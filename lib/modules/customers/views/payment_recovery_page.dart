import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/recovery_messaging_service.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/customers/views/customer_detail_page.dart';
import 'package:mandi/modules/customers/views/send_reminder_dialog.dart';
import 'package:mandi/modules/payments/views/add_payment_page.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Khata Recovery Center (تقاضا سنٹر).
/// Centralized hub for managing customer receivables, sorting by balance severity,
/// and dispatching automated WhatsApp and SMS reminders.
class PaymentRecoveryPage extends StatefulWidget {
  const PaymentRecoveryPage({super.key});

  @override
  State<PaymentRecoveryPage> createState() => _PaymentRecoveryPageState();
}

class _PaymentRecoveryPageState extends State<PaymentRecoveryPage> {
  final _searchCtrl = TextEditingController();
  double _minBalanceFilter = 0.0;
  final String _sortBy = 'balance_desc'; // 'balance_desc', 'balance_asc', 'name'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final customerProv = context.watch<CustomerProvider>();

    // Filter customers who genuinely owe money (runningBalance > 0)
    final allDebtors = customerProv.customers
        .where((c) => c.runningBalance > 0)
        .toList();

    final totalReceivables =
        allDebtors.fold<double>(0.0, (sum, c) => sum + c.runningBalance);

    // Apply search query
    final query = _searchCtrl.text.trim().toLowerCase();
    List<Customer> filtered = allDebtors.where((c) {
      if (c.runningBalance < _minBalanceFilter) return false;
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.city.toLowerCase().contains(query);
    }).toList();

    // Sort
    if (_sortBy == 'balance_desc') {
      filtered.sort((a, b) => b.runningBalance.compareTo(a.runningBalance));
    } else if (_sortBy == 'balance_asc') {
      filtered.sort((a, b) => a.runningBalance.compareTo(b.runningBalance));
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Recovery Center'),
            Text(
              'تقاضا کھاتہ و باقیدار لسٹ',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Receivables Overview Banner
          Padding(
            padding: const EdgeInsets.all(MSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.sm),
                    borderColor: Colors.redAccent.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Outstanding',
                            style: MText.caption.copyWith(color: Colors.redAccent)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${totalReceivables.toStringAsFixed(0)}',
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('کل واجب الوصول رقم',
                            style: MText.caption.copyWith(
                                color: MColors.textOnDarkSub, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.xs),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Debtors',
                            style: MText.caption
                                .copyWith(color: MColors.textOnDarkSub)),
                        const SizedBox(height: 2),
                        Text(
                          '${allDebtors.length}',
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text('کل باقیدار',
                            style: MText.caption.copyWith(
                                color: MColors.textOnDarkSub, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search debtor by name, phone, city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: MSpacing.sm),

          // Filter by Minimum Balance Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: Row(
              children: [
                _buildAmountFilterChip(0.0, 'All Debtors'),
                const SizedBox(width: MSpacing.xs),
                _buildAmountFilterChip(25000.0, '> 25K'),
                const SizedBox(width: MSpacing.xs),
                _buildAmountFilterChip(50000.0, '> 50K'),
                const SizedBox(width: MSpacing.xs),
                _buildAmountFilterChip(100000.0, '> 100K'),
                const SizedBox(width: MSpacing.xs),
                _buildAmountFilterChip(500000.0, '> 500K'),
              ],
            ),
          ),
          const SizedBox(height: MSpacing.sm),

          // Debtors List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 56,
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: MSpacing.sm),
                        Text(
                          allDebtors.isEmpty
                              ? 'All clear! No customer has an outstanding balance.'
                              : 'No debtors matching filter criteria.',
                          style: MText.bodyMd.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      MSpacing.md,
                      MSpacing.xs,
                      MSpacing.md,
                      MSpacing.lg,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: MSpacing.sm),
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      return _DebtorCard(
                        customer: customer,
                        shop: shop,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountFilterChip(double amount, String label) {
    final isSelected = _minBalanceFilter == amount;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _minBalanceFilter = amount);
      },
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final Customer customer;
  final dynamic shop;

  const _DebtorCard({
    required this.customer,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(MSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Name, Balance
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: MSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: MText.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${customer.phone}${customer.city.isNotEmpty ? ' • ${customer.city}' : ''}',
                      style: MText.caption.copyWith(color: MColors.textOnDarkSub),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    'واجب الادا',
                    style: MText.caption.copyWith(
                      fontSize: 9,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: MSpacing.sm),
          const Divider(height: 1, thickness: 0.5, color: Colors.white12),
          const SizedBox(height: MSpacing.xs),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contact icons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_outlined, size: 18),
                    tooltip: 'Call Phone',
                    onPressed: () {
                      RecoveryMessagingService.launchPhoneCall(customer.phone);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    tooltip: 'Send SMS Notice',
                    onPressed: () {
                      final msg =
                          RecoveryMessagingService.formatRecoveryMessage(
                        customerName: customer.name,
                        pendingBalance: customer.runningBalance,
                        shopName: shop?.name ?? 'Mandi Commission Shop',
                        shopPhone: shop?.phone,
                        shopCity: shop?.city,
                      );
                      RecoveryMessagingService.launchSms(
                        phone: customer.phone,
                        message: msg,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.campaign_outlined,
                      size: 20,
                      color: MColors.gold,
                    ),
                    tooltip: 'Custom Reminder Dialog',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => SendReminderDialog(
                          customer: customer,
                          shop: shop,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined, size: 13),
                    label: const Text('Khata'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerDetailPage(customer: customer),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 13),
                    label: const Text('Receive Cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPaymentPage(
                            initialPartyType: 'customer',
                            initialCustomer: customer,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

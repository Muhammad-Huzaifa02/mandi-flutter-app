import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/core/utils/ledger_calculator.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/ledger_entry_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/payments/views/add_payment_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _customer.name);
    final phoneCtrl = TextEditingController(text: _customer.phone);
    final emailCtrl = TextEditingController(text: _customer.email);
    final cityCtrl = TextEditingController(text: _customer.city);
    final addressCtrl = TextEditingController(text: _customer.address);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Customer Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name *'),
              ),
              const SizedBox(height: MSpacing.sm),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: MSpacing.sm),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: MSpacing.sm),
              TextFormField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: MSpacing.sm),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;

              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              final newCity = cityCtrl.text.trim();
              final newAddress = addressCtrl.text.trim();

              Navigator.pop(dialogCtx);

              setState(() {
                _customer = _customer.copyWith(
                  name: newName,
                  phone: newPhone,
                  email: newEmail,
                  city: newCity,
                  address: newAddress,
                );
              });

              if (_customer.id.isNotEmpty) {
                await SupabaseService.updateCustomer(_customer.id, {
                  'name': newName,
                  'phone': newPhone,
                  'email': newEmail,
                  'city': newCity,
                  'address': newAddress,
                });
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer profile updated.')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final canEdit = shopCtx.hasPermission('manage_customers');

    final invoices = context.watch<InvoiceProvider>().invoices;
    final myInvoices = invoices
        .where((inv) =>
            inv.customerId == _customer.id ||
            (inv.customerName.isNotEmpty &&
                inv.customerName.toLowerCase() ==
                    _customer.name.toLowerCase()))
        .toList();

    final allPayments = context.watch<PaymentProvider>().payments;
    final myPayments = allPayments
        .where((p) =>
            p.partyType.toLowerCase() == 'customer' &&
            (p.partyId == _customer.id ||
                (_customer.userId != null && p.partyId == _customer.userId)))
        .toList();

    // DSA: Chronological Merge & Prefix-Sum progressive balance calculation
    final ledgerEntries = LedgerCalculator.buildCustomerLedger(
      openingBalance: _customer.openingBalance,
      invoices: myInvoices,
      payments: myPayments,
    );

    final totalSpent =
        myInvoices.fold(0.0, (sum, inv) => sum + inv.total);
    final loyaltyPoints = (totalSpent / 1000).floor();

    final locationStr = [_customer.address, _customer.city]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.tr(context, 'edit_profile'),
              onPressed: _editProfileDialog,
            ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: AppStrings.tr(context, 'print_ledger_pdf'),
            onPressed: () {
              LedgerPdfGenerator.printCustomerLedger(
                customer: _customer,
                shopName: shop?.name ?? 'Mandi Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
                entries: ledgerEntries,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header GlassCard with Loyalty Badge
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: MColors.gold.withValues(alpha: 0.2),
                        child: Text(
                          _customer.name.isNotEmpty
                              ? _customer.name[0].toUpperCase()
                              : 'C',
                          style: MText.titleLg.copyWith(color: MColors.gold),
                        ),
                      ),
                      const SizedBox(width: MSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_customer.name,
                                style: MText.titleLg.copyWith(color: MColors.textPrimary)),
                            if (_customer.phone.isNotEmpty)
                              Text('Phone: ${_customer.phone}',
                                  style: MText.bodySm
                                      .copyWith(color: MColors.textSecondary)),
                            if (_customer.email.isNotEmpty)
                              Text('Email: ${_customer.email}',
                                  style: MText.bodySm
                                      .copyWith(color: MColors.textSecondary)),
                            if (locationStr.isNotEmpty)
                              Text('Address: $locationStr',
                                  style: MText.bodySm
                                      .copyWith(color: MColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.md),
                  Chip(
                    avatar: const Icon(Icons.stars,
                        color: MColors.primary, size: 18),
                    label: Text(
                      '$loyaltyPoints ${AppStrings.tr(context, 'loyalty_points')} (Rs. ${totalSpent.toStringAsFixed(0)} ${AppStrings.tr(context, 'spent')})',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MColors.textPrimary),
                    ),
                    backgroundColor: MColors.primary.withValues(alpha: 0.12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Khata Balance GlassCard
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.tr(context, 'outstanding_khata_balance'),
                      style: MText.labelMd.copyWith(color: MColors.textSecondary)),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${_customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: _customer.runningBalance > 0
                          ? MColors.danger
                          : (_customer.runningBalance < 0
                              ? Colors.green.shade700
                              : MColors.textPrimary),
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    _customer.runningBalance > 0
                        ? AppStrings.tr(context, 'customer_owes_you')
                        : (_customer.runningBalance < 0
                            ? AppStrings.tr(context, 'advance_received')
                            : AppStrings.tr(context, 'khata_settled')),
                    style: MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Account Ledger History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.tr(context, 'account_ledger_history'),
                    style: MText.titleLg.copyWith(color: MColors.textPrimary)),
                Text('${ledgerEntries.length} ${AppStrings.tr(context, 'transactions')}',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              ],
            ),
            const SizedBox(height: MSpacing.sm),

            if (ledgerEntries.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(MSpacing.xl),
                child: Center(
                  child: Text('No transactions recorded for this customer yet.',
                      style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ledgerEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  // Reverse order to show newest transactions first in the app UI
                  final entry = ledgerEntries[ledgerEntries.length - 1 - i];
                  final isInvoice = entry.type == LedgerEntryType.invoice;

                  return GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isInvoice
                                  ? MColors.primary.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              child: Icon(
                                isInvoice ? Icons.receipt_long : Icons.payments,
                                color: isInvoice
                                    ? MColors.primary
                                    : Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.reference,
                                    style: MText.titleLg.copyWith(color: MColors.textPrimary)),
                                Text(
                                  '${entry.formattedDate} • ${entry.description}',
                                  style: MText.bodySm
                                      .copyWith(color: MColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isInvoice
                                  ? '+ Rs. ${entry.debit.toStringAsFixed(0)} (Dr)'
                                  : '- Rs. ${entry.credit.toStringAsFixed(0)} (Cr)',
                              style: MText.bodyMd.copyWith(
                                color: isInvoice
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bal: Rs. ${entry.runningBalance.toStringAsFixed(0)}',
                              style: MText.bodySm.copyWith(
                                color: entry.runningBalance > 0
                                    ? MColors.primary
                                    : MColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: MSpacing.xl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MColors.primary,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPaymentPage(
                          initialCustomer: _customer,
                          initialPartyType: 'customer',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.payment_outlined, size: 18),
                    label: Text(AppStrings.tr(context, 'record_receipt'),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                if (_customer.runningBalance > 0 &&
                    _customer.phone.isNotEmpty) ...[
                  const SizedBox(width: MSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        WhatsAppShareService.sharePaymentReminder(
                          phone: _customer.phone,
                          name: _customer.name,
                          pendingBalance: _customer.runningBalance,
                          shopName: shop?.name ?? 'Mandi Shop',
                        );
                      },
                      icon: const Icon(Icons.send_outlined,
                          color: Colors.white, size: 18),
                      label: Text(AppStrings.tr(context, 'whatsapp'),
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
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
              tooltip: 'Edit Profile',
              onPressed: _editProfileDialog,
            ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Ledger Statement PDF',
            onPressed: () {
              LedgerPdfGenerator.printCustomerLedger(
                customer: _customer,
                shopName: shop?.name ?? 'Mandi Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
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
                                style: MText.titleLg.copyWith(color: Colors.white)),
                            if (_customer.phone.isNotEmpty)
                              Text('Phone: ${_customer.phone}',
                                  style: MText.bodySm
                                      .copyWith(color: Colors.white70)),
                            if (_customer.email.isNotEmpty)
                              Text('Email: ${_customer.email}',
                                  style: MText.bodySm
                                      .copyWith(color: Colors.white70)),
                            if (locationStr.isNotEmpty)
                              Text('Address: $locationStr',
                                  style: MText.bodySm
                                      .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.md),
                  Chip(
                    avatar: const Icon(Icons.stars,
                        color: Colors.amber, size: 18),
                    label: Text(
                      '$loyaltyPoints Loyalty Points (Rs. ${totalSpent.toStringAsFixed(0)} spent)',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
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
                  Text('Outstanding Khata Balance',
                      style: MText.labelMd.copyWith(color: Colors.white70)),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${_customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: _customer.runningBalance > 0
                          ? MColors.danger
                          : (_customer.runningBalance < 0
                              ? Colors.greenAccent
                              : Colors.white),
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    _customer.runningBalance > 0
                        ? 'Customer owes you'
                        : (_customer.runningBalance < 0
                            ? 'Advance payment received'
                            : 'Khata Settled'),
                    style: MText.bodySm.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Invoices History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invoices History',
                    style: MText.titleLg.copyWith(color: Colors.white)),
                Text('${myInvoices.length} Invoices',
                    style: MText.bodySm.copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: MSpacing.sm),

            if (myInvoices.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(MSpacing.xl),
                child: Center(
                  child: Text('No invoices issued for this customer yet.',
                      style: MText.bodyMd.copyWith(color: Colors.white70)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myInvoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  final inv = myInvoices[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: MColors.gold.withValues(alpha: 0.2),
                              child: const Icon(Icons.receipt_long,
                                  color: MColors.gold),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv.invoiceNumber,
                                    style: MText.titleLg.copyWith(color: Colors.white)),
                                Text(
                                  inv.createdAt != null
                                      ? '${inv.createdAt!.day}/${inv.createdAt!.month}/${inv.createdAt!.year}'
                                      : 'Sales Invoice',
                                  style: MText.bodySm
                                      .copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${inv.total.toStringAsFixed(0)}',
                              style: MText.titleLg.copyWith(color: MColors.gold),
                            ),
                            Text(
                              inv.pendingAmount > 0
                                  ? 'Pending: Rs. ${inv.pendingAmount.toStringAsFixed(0)}'
                                  : 'PAID',
                              style: MText.bodySm.copyWith(
                                color: inv.pendingAmount > 0
                                    ? MColors.danger
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
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
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
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
                    label: const Text('Record Receipt',
                        style: TextStyle(fontSize: 13)),
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
                      label: const Text('WhatsApp',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
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

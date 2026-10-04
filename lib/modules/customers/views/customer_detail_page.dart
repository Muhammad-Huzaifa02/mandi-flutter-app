import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/invoices/views/invoice_detail_page.dart';
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

              final updateData = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              };

              if (_customer.id.isNotEmpty) {
                await SupabaseService.updateCustomer(_customer.id, updateData);
              }

              setState(() {
                _customer = _customer.copyWith(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
              });

              if (!mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer profile updated.')),
              );
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
            // Profile Header Card with Loyalty Badge
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: MColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _customer.name.isNotEmpty
                              ? _customer.name[0].toUpperCase()
                              : 'C',
                          style: MText.titleLg.copyWith(color: MColors.primary),
                        ),
                      ),
                      const SizedBox(width: MSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_customer.name, style: MText.titleLg),
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
                        color: Colors.amber, size: 18),
                    label: Text(
                      '$loyaltyPoints Loyalty Points (Rs. ${totalSpent.toStringAsFixed(0)} spent)',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Khata Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outstanding Khata Balance', style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${_customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: _customer.runningBalance > 0
                          ? MColors.danger
                          : (_customer.runningBalance < 0
                              ? Colors.green
                              : MColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    _customer.runningBalance > 0
                        ? 'Customer owes you'
                        : (_customer.runningBalance < 0
                            ? 'Advance payment received'
                            : 'Khata Settled'),
                    style:
                        MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Invoices History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoices History', style: MText.titleLg),
                Text('${myInvoices.length} Invoices',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              ],
            ),
            const SizedBox(height: MSpacing.sm),

            if (myInvoices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpacing.xl),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: MRadius.md,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text('No invoices issued for this customer yet.',
                      style:
                          MText.bodyMd.copyWith(color: MColors.textSecondary)),
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
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: MRadius.md,
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: MColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.receipt_long,
                            color: MColors.primary),
                      ),
                      title: Text(inv.invoiceNumber, style: MText.titleLg),
                      subtitle: Text(
                        inv.createdAt != null
                            ? '${inv.createdAt!.day}/${inv.createdAt!.month}/${inv.createdAt!.year}'
                            : 'Sales Invoice',
                        style: MText.bodySm
                            .copyWith(color: MColors.textSecondary),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. ${inv.total.toStringAsFixed(0)}',
                            style: MText.titleLg
                                .copyWith(color: MColors.primary),
                          ),
                          Text(
                            inv.pendingAmount > 0
                                ? 'Pending: Rs. ${inv.pendingAmount.toStringAsFixed(0)}'
                                : 'PAID',
                            style: MText.bodySm.copyWith(
                              color: inv.pendingAmount > 0
                                  ? MColors.danger
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoiceDetailPage(invoice: inv),
                        ),
                      ),
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddPaymentPage()),
                    ),
                    icon: const Icon(Icons.payment_outlined),
                    label: const Text('Record Receipt'),
                  ),
                ),
                if (_customer.runningBalance > 0 &&
                    _customer.phone.isNotEmpty) ...[
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
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
                          style: TextStyle(color: Colors.white)),
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

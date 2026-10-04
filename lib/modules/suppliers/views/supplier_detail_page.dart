import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/modules/payments/views/add_payment_page.dart';

class SupplierDetailPage extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailPage({super.key, required this.supplier});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  late Supplier _supplier;

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _supplier.name);
    final phoneCtrl = TextEditingController(text: _supplier.phone);
    final emailCtrl = TextEditingController(text: _supplier.email);
    final productsCtrl = TextEditingController(text: _supplier.productsSupplied);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Supplier Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Name *'),
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
                controller: productsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Products Supplied (e.g. Wheat, Rice)'),
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
                'products_supplied': productsCtrl.text.trim(),
              };

              if (_supplier.id.isNotEmpty) {
                await SupabaseService.updateShopMember(
                  membershipId: _supplier.id,
                  shopId: _supplier.shopId,
                  data: updateData,
                  actorUid: context.read<ShopContextProvider>().currentMember?.id ?? '',
                  actorName: context.read<ShopContextProvider>().currentMember?.name ?? '',
                );
              }

              setState(() {
                _supplier = _supplier.copyWith(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  productsSupplied: productsCtrl.text.trim(),
                );
              });

              if (!mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supplier profile updated.')),
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
    final canEdit = shopCtx.hasPermission('manage_suppliers');

    final purchaseOrders =
        context.watch<PurchaseOrderProvider>().purchaseOrders;
    final myOrders = purchaseOrders
        .where((po) =>
            po.supplierId == _supplier.id ||
            (po.supplierName.isNotEmpty &&
                po.supplierName.toLowerCase() ==
                    _supplier.name.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_supplier.name),
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
              LedgerPdfGenerator.printSupplierLedger(
                supplier: _supplier,
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
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _supplier.name.isNotEmpty
                          ? _supplier.name[0].toUpperCase()
                          : 'S',
                      style: MText.titleLg.copyWith(color: MColors.primary),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_supplier.name, style: MText.titleLg),
                        if (_supplier.phone.isNotEmpty)
                          Text('Phone: ${_supplier.phone}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                        if (_supplier.email.isNotEmpty)
                          Text('Email: ${_supplier.email}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                        if (_supplier.productsSupplied.isNotEmpty)
                          Text('Supplies: ${_supplier.productsSupplied}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpacing.lg),

            // Ledger Summary
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
                  const Text('Outstanding Payable Balance', style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${_supplier.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: _supplier.runningBalance > 0
                          ? MColors.danger
                          : (_supplier.runningBalance < 0
                              ? Colors.green
                              : MColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    _supplier.runningBalance > 0
                        ? 'Payable to supplier'
                        : (_supplier.runningBalance < 0
                            ? 'Advance paid to supplier'
                            : 'Settled'),
                    style:
                        MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Purchase Orders History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Purchase Orders', style: MText.titleLg),
                Text('${myOrders.length} Orders',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              ],
            ),
            const SizedBox(height: MSpacing.sm),

            if (myOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpacing.xl),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: MRadius.md,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text('No purchase orders recorded for this supplier.',
                      style:
                          MText.bodyMd.copyWith(color: MColors.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  final po = myOrders[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: MRadius.md,
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: MColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.assignment_outlined,
                            color: MColors.primary),
                      ),
                      title: Text(po.supplierName, style: MText.titleLg),
                      subtitle: Text(
                        'Status: ${po.status.toUpperCase()} ${po.createdAt != null ? '• ${po.createdAt!.day}/${po.createdAt!.month}/${po.createdAt!.year}' : ''}',
                        style: MText.bodySm
                            .copyWith(color: MColors.textSecondary),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. ${po.total.toStringAsFixed(0)}',
                            style: MText.titleLg
                                .copyWith(color: MColors.primary),
                          ),
                          Text(
                            po.pendingAmount > 0
                                ? 'Pending: Rs. ${po.pendingAmount.toStringAsFixed(0)}'
                                : 'PAID',
                            style: MText.bodySm.copyWith(
                              color: po.pendingAmount > 0
                                  ? MColors.danger
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                        builder: (_) => AddPaymentPage(
                          initialSupplier: _supplier,
                          initialPartyType: 'supplier',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.payment_outlined),
                    label: const Text('Pay Supplier'),
                  ),
                ),
                if (_supplier.runningBalance > 0 &&
                    _supplier.phone.isNotEmpty) ...[
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                      ),
                      onPressed: () {
                        WhatsAppShareService.sharePaymentReminder(
                          phone: _supplier.phone,
                          name: _supplier.name,
                          pendingBalance: _supplier.runningBalance,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/core/utils/ledger_calculator.dart';
import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/data/models/ledger_entry_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/payments/views/add_payment_page.dart';

class FarmerDetailPage extends StatefulWidget {
  final Farmer farmer;
  Farmer get supplier => farmer;

  FarmerDetailPage({
    super.key,
    Farmer? farmer,
    Farmer? supplier,
  }) : farmer = (farmer ?? supplier)!;

  @override
  State<FarmerDetailPage> createState() => _FarmerDetailPageState();
}

class _FarmerDetailPageState extends State<FarmerDetailPage> {
  late Farmer _farmer;

  @override
  void initState() {
    super.initState();
    _farmer = widget.farmer;
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _farmer.name);
    final phoneCtrl = TextEditingController(text: _farmer.phone);
    final emailCtrl = TextEditingController(text: _farmer.email);
    final productsCtrl = TextEditingController(text: _farmer.productsSupplied);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Farmer Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Farmer Name *'),
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
                    labelText: 'Crops (e.g. Wheat, Rice, Cotton)'),
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
              final newProducts = productsCtrl.text.trim();

              final shopCtx = context.read<ShopContextProvider>();
              final actorUid = shopCtx.currentMember?.id ?? '';
              final actorName = shopCtx.currentMember?.name ?? '';

              Navigator.pop(dialogCtx);

              setState(() {
                _farmer = _farmer.copyWith(
                  name: newName,
                  phone: newPhone,
                  email: newEmail,
                  productsSupplied: newProducts,
                );
              });

              if (_farmer.id.isNotEmpty) {
                await SupabaseService.updateShopMember(
                  membershipId: _farmer.id,
                  shopId: _farmer.shopId,
                  data: {
                    'name': newName,
                    'phone': newPhone,
                    'email': newEmail,
                    'products_supplied': newProducts,
                  },
                  actorUid: actorUid,
                  actorName: actorName,
                );
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Farmer profile updated.')),
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
    final canEdit = shopCtx.hasPermission('manage_suppliers');

    final purchaseOrders =
        context.watch<PurchaseOrderProvider>().purchaseOrders;
    final myOrders = purchaseOrders
        .where((po) =>
            po.supplierId == _farmer.id ||
            (po.supplierName.isNotEmpty &&
                po.supplierName.toLowerCase() ==
                    _farmer.name.toLowerCase()))
        .toList();

    final allInvoices = context.watch<InvoiceProvider>().invoices
        .where((inv) =>
            inv.supplierId == _farmer.id ||
            (inv.supplierName.isNotEmpty &&
                inv.supplierName.toLowerCase() ==
                    _farmer.name.toLowerCase()))
        .toList();

    final allPayments = context.watch<PaymentProvider>().payments
        .where((p) =>
            p.partyType.toLowerCase() == 'supplier' &&
            (p.partyId == _farmer.id ||
                (_farmer.userId != null && p.partyId == _farmer.userId)))
        .toList();

    // DSA: Unified merge & Prefix-Sum progressive running balance calculation
    final ledgerEntries = LedgerCalculator.buildFarmerLedger(
      openingBalance: _farmer.openingBalance,
      purchaseOrders: myOrders,
      consignmentInvoices: allInvoices,
      payments: allPayments,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_farmer.name),
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
              LedgerPdfGenerator.printFarmerLedger(
                farmer: _farmer,
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
            // Profile Header GlassCard
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MColors.gold.withValues(alpha: 0.2),
                    child: Text(
                      _farmer.name.isNotEmpty
                          ? _farmer.name[0].toUpperCase()
                          : 'F',
                      style: MText.titleLg.copyWith(color: MColors.gold),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_farmer.name,
                            style: MText.titleLg.copyWith(color: MColors.textPrimary)),
                        if (_farmer.phone.isNotEmpty)
                          Text('Phone: ${_farmer.phone}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                        if (_farmer.email.isNotEmpty)
                          Text('Email: ${_farmer.email}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                        if (_farmer.productsSupplied.isNotEmpty)
                          Text('Crops: ${_farmer.productsSupplied}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Payable Balance GlassCard
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding Payable Balance',
                      style: MText.labelMd.copyWith(color: MColors.textSecondary)),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${_farmer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: _farmer.runningBalance > 0
                          ? MColors.danger
                          : (_farmer.runningBalance < 0
                              ? Colors.green.shade700
                              : MColors.textPrimary),
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    _farmer.runningBalance > 0
                        ? 'Payable to farmer (واجب الادا رقم)'
                        : (_farmer.runningBalance < 0
                            ? 'Advance paid to farmer (پیشگی رقم)'
                            : 'Settled'),
                    style: MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Farmer Ledger History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Account Ledger History',
                    style: MText.titleLg.copyWith(color: MColors.textPrimary)),
                Text('${ledgerEntries.length} Transactions',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              ],
            ),
            const SizedBox(height: MSpacing.sm),

            if (ledgerEntries.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(MSpacing.xl),
                child: Center(
                  child: Text('No transactions recorded for this farmer yet.',
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
                  final isPayout = entry.type == LedgerEntryType.payout;

                  return GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isPayout
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : MColors.primary.withValues(alpha: 0.12),
                              child: Icon(
                                isPayout ? Icons.payments : Icons.assignment_outlined,
                                color: isPayout
                                    ? Colors.green.shade700
                                    : MColors.primary,
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
                              isPayout
                                  ? '- Rs. ${entry.debit.toStringAsFixed(0)} (Paid)'
                                  : '+ Rs. ${entry.credit.toStringAsFixed(0)} (Produce)',
                              style: MText.bodyMd.copyWith(
                                color: isPayout
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
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
                          initialSupplier: _farmer,
                          initialPartyType: 'supplier',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.payment_outlined, size: 18),
                    label: const Text('Pay Farmer',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                if (_farmer.runningBalance > 0 &&
                    _farmer.phone.isNotEmpty) ...[
                  const SizedBox(width: MSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        WhatsAppShareService.sharePaymentReminder(
                          phone: _farmer.phone,
                          name: _farmer.name,
                          pendingBalance: _farmer.runningBalance,
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

// Backward compatibility alias
typedef SupplierDetailPage = FarmerDetailPage;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/ledger_pdf_generator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class SupplierDetailPage extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailPage({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopContextProvider>().currentShop;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Ledger Statement PDF',
            onPressed: () {
              LedgerPdfGenerator.printSupplierLedger(
                supplier: supplier,
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
                      supplier.name.isNotEmpty
                          ? supplier.name[0].toUpperCase()
                          : 'S',
                      style: MText.titleLg.copyWith(color: MColors.primary),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier.name, style: MText.titleLg),
                        if (supplier.productsSupplied.isNotEmpty)
                          Text(
                            'Supplies: ${supplier.productsSupplied}',
                            style: MText.bodyMd.copyWith(
                                color: MColors.textSecondary),
                          ),
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
                  const Text('Outstanding Payable Balance',
                      style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${supplier.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: supplier.runningBalance > 0
                          ? MColors.danger
                          : (supplier.runningBalance < 0
                              ? Colors.green
                              : MColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    supplier.runningBalance > 0
                        ? 'Payable to supplier'
                        : (supplier.runningBalance < 0
                            ? 'Advance paid to supplier'
                            : 'Settled'),
                    style:
                        MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpacing.lg),

            // Contact Information
            const Text('Contact Information', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            _DetailTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: supplier.phone.isNotEmpty ? supplier.phone : 'Not provided',
            ),
            _DetailTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: supplier.email.isNotEmpty ? supplier.email : 'Not provided',
            ),
            _DetailTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Products Supplied',
              value: supplier.productsSupplied.isNotEmpty
                  ? supplier.productsSupplied
                  : 'Not specified',
            ),

            if (supplier.runningBalance > 0 && supplier.phone.isNotEmpty) ...[
              const SizedBox(height: MSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () {
                    WhatsAppShareService.sharePaymentReminder(
                      phone: supplier.phone,
                      name: supplier.name,
                      pendingBalance: supplier.runningBalance,
                      shopName: shop?.name ?? 'Mandi Shop',
                    );
                  },
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  label: const Text('Send WhatsApp Payment Reminder',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MColors.textSecondary),
          const SizedBox(width: MSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              Text(value, style: MText.bodyMd),
            ],
          ),
        ],
      ),
    );
  }
}

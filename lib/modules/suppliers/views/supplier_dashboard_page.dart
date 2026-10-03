import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/suppliers/views/supplier_detail_page.dart';
import 'package:mandi/modules/products/views/product_list_page.dart';
import 'package:mandi/modules/purchase_orders/views/purchase_order_list_page.dart';
import 'package:mandi/modules/payments/views/payment_list_page.dart';

/// Shown when the signed-in account's role in the active shop is
/// 'supplier' (see lib/routes/dashboard_router.dart).
class SupplierDashboardPage extends StatelessWidget {
  const SupplierDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;
    final member = shopCtx.currentMember;

    final suppliers = context.watch<SupplierProvider>().suppliers;
    final mySupplier = suppliers.firstWhere(
      (s) =>
          s.userId == auth.uid ||
          (member?.email.isNotEmpty == true &&
              s.email.toLowerCase() == member!.email.toLowerCase()),
      orElse: () => Supplier(
        id: member?.id ?? '',
        shopId: shopCtx.currentShopId ?? '',
        name: member?.name ?? 'Supplier',
        phone: member?.phone ?? '',
        email: member?.email ?? '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(shop?.name ?? 'Mandi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.signOut();
              shopCtx.clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${member?.name ?? ''}', style: MText.titleLg),
            const SizedBox(height: MSpacing.xs),
            Text('Supplier to ${shop?.name ?? 'this shop'}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.xl),

            // Balance Card with WhatsApp Reminder
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
                  Text('Money Owed to Me by ${shop?.name ?? "Shop"}',
                      style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${mySupplier.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: mySupplier.runningBalance > 0
                          ? MColors.danger
                          : Colors.green,
                    ),
                  ),
                  if (mySupplier.runningBalance > 0 &&
                      (shop?.phone.isNotEmpty == true ||
                          shop?.whatsapp.isNotEmpty == true)) ...[
                    const SizedBox(height: MSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                        onPressed: () {
                          final targetPhone = shop!.whatsapp.isNotEmpty
                              ? shop.whatsapp
                              : shop.phone;
                          final msg = '''
Assalam-o-Alaikum,

This is a friendly payment reminder from *${mySupplier.name}* (Supplier).

My outstanding balance payable by *${shop.name}* is: *Rs. ${mySupplier.runningBalance.toStringAsFixed(0)}*.

Kindly process the payment at your earliest convenience.

Thank you!
''';
                          WhatsAppShareService.launchWhatsApp(
                            phone: targetPhone,
                            message: msg,
                          );
                        },
                        icon:
                            const Icon(Icons.send_outlined, color: Colors.white),
                        label: const Text(
                          'Send Payment Reminder to Shop Owner',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),
            const Text('Supply Operations', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                _SupplierTile(
                  icon: Icons.assignment_outlined,
                  label: 'Purchase Orders',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PurchaseOrderListPage()),
                  ),
                ),
                _SupplierTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListPage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: MSpacing.lg),
            const Text('My Account', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                _SupplierTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payments',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentListPage()),
                  ),
                ),
                _SupplierTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Ledger',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupplierDetailPage(supplier: mySupplier),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupplierTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MRadius.md,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: MSpacing.md),
        decoration: BoxDecoration(
          color: MColors.surface,
          borderRadius: MRadius.md,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: MColors.primary),
            const SizedBox(height: MSpacing.xs),
            Text(label, style: MText.labelMd, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

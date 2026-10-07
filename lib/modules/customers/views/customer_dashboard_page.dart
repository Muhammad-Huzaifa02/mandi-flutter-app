import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/customers/views/customer_detail_page.dart';
import 'package:mandi/modules/products/views/product_list_page.dart';
import 'package:mandi/modules/invoices/views/invoice_list_page.dart';
import 'package:mandi/modules/payments/views/payment_list_page.dart';

/// Shown when the signed-in account's role in the active shop is
/// 'customer' (see lib/routes/dashboard_router.dart).
class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;
    final member = shopCtx.currentMember;

    final customers = context.watch<CustomerProvider>().customers;
    final myCustomer = customers.firstWhere(
      (c) =>
          c.userId == auth.uid ||
          (member?.email.isNotEmpty == true &&
              c.email.toLowerCase() == member!.email.toLowerCase()),
      orElse: () => Customer(
        id: member?.id ?? '',
        shopId: shopCtx.currentShopId ?? '',
        name: member?.name ?? 'Customer',
        phone: member?.phone ?? '',
        email: member?.email ?? '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(shop.logoUrl!),
              ),
              const SizedBox(width: MSpacing.xs),
            ],
            Text(shop?.name ?? 'Mandi'),
          ],
        ),
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
            Text('Customer at ${shop?.name ?? 'this shop'}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.xl),

            // Balance Card
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
                  const Text('My Outstanding Balance', style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${myCustomer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: myCustomer.runningBalance > 0
                          ? MColors.danger
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),
            const Text('Shop', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                _CustomerTile(
                  icon: Icons.storefront_outlined,
                  label: 'Products',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListPage()),
                  ),
                ),
                _CustomerTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoices',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvoiceListPage()),
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
                _CustomerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payments',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentListPage()),
                  ),
                ),
                _CustomerTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Ledger',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerDetailPage(customer: myCustomer),
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

class _CustomerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CustomerTile({
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

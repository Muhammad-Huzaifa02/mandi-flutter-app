import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
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
          children: [
            if (shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(shop.logoUrl!),
              ),
              const SizedBox(width: MSpacing.xs),
            ],
            Expanded(
              child: Text(
                shop?.name ?? 'Mandi',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerDetailPage(customer: myCustomer),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: GlassCard(
                padding: const EdgeInsets.all(MSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: MColors.gold.withValues(alpha: 0.2),
                      child: Text(
                        member?.name.isNotEmpty == true
                            ? member!.name[0].toUpperCase()
                            : 'C',
                        style: MText.titleLg.copyWith(color: MColors.gold),
                      ),
                    ),
                    const SizedBox(width: MSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Welcome, ${member?.name ?? ''}',
                                  style: MText.titleLg
                                      .copyWith(color: Colors.white)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: MColors.gold),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Customer at ${shop?.name ?? 'this shop'}',
                              style: MText.bodySm
                                  .copyWith(color: MColors.textOnDarkSub)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Glass Balance Card
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Outstanding Balance',
                      style: MText.labelMd.copyWith(color: Colors.white70)),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${myCustomer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: myCustomer.runningBalance > 0
                          ? MColors.danger
                          : Colors.greenAccent,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),
            Text('Shop', style: MText.titleLg.copyWith(color: Colors.white)),
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
            Text('My Account',
                style: MText.titleLg.copyWith(color: Colors.white)),
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
                _CustomerTile(
                  icon: Icons.person_outline,
                  label: 'Profile',
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
    return GlassCard(
      onTap: onTap,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(
          vertical: MSpacing.md, horizontal: MSpacing.xs),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(icon, color: MColors.gold, size: 26),
            const SizedBox(height: MSpacing.xs),
            Text(
              label,
              style: MText.labelMd.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

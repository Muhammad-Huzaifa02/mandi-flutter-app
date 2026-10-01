import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/module_tile.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${member?.name ?? ''}', style: MText.titleLg),
            const SizedBox(height: MSpacing.xs),
            Text('Customer at ${shop?.name ?? 'this shop'}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.xl),
            const Text('Shop', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            const Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                ModuleTile(icon: Icons.storefront_outlined, label: 'Products'),
                ModuleTile(icon: Icons.search, label: 'Search'),
                ModuleTile(icon: Icons.shopping_cart_outlined, label: 'Cart'),
              ],
            ),
            const SizedBox(height: MSpacing.lg),
            const Text('My Account', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            const Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                ModuleTile(icon: Icons.receipt_long_outlined, label: 'Orders'),
                ModuleTile(icon: Icons.description_outlined, label: 'Invoices'),
                ModuleTile(icon: Icons.account_balance_wallet_outlined, label: 'Payments'),
                ModuleTile(icon: Icons.menu_book_outlined, label: 'Ledger'),
                ModuleTile(icon: Icons.notifications_outlined, label: 'Notifications'),
                ModuleTile(icon: Icons.person_outline, label: 'Profile'),
              ],
            ),
            const SizedBox(height: MSpacing.xl),
            Text(
              'This is your own view as a customer of ${shop?.name ?? 'this shop'} — '
              'separate from the owner/staff dashboard.',
              style: MText.bodyMd.copyWith(color: MColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/module_tile.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

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
            Text('Supplier to ${shop?.name ?? 'this shop'}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.xl),
            const Text('Supply', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            const Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                ModuleTile(icon: Icons.assignment_outlined, label: 'Purchase Orders'),
                ModuleTile(icon: Icons.inventory_2_outlined, label: 'Products Supplied'),
                ModuleTile(icon: Icons.local_shipping_outlined, label: 'Deliveries'),
              ],
            ),
            const SizedBox(height: MSpacing.lg),
            const Text('Accounts', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            const Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                ModuleTile(icon: Icons.description_outlined, label: 'Invoices'),
                ModuleTile(icon: Icons.account_balance_wallet_outlined, label: 'Payments'),
                ModuleTile(icon: Icons.menu_book_outlined, label: 'Ledger'),
                ModuleTile(icon: Icons.folder_outlined, label: 'Documents'),
              ],
            ),
            const SizedBox(height: MSpacing.xl),
            Text(
              'This is your own view as a supplier to ${shop?.name ?? 'this shop'} — '
              'separate from the owner/staff dashboard. Modules above are planned; '
              'none are wired to real data yet.',
              style: MText.bodyMd.copyWith(color: MColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

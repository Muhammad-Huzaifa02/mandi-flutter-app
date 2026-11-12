import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/farmer_provider.dart';
import 'package:mandi/modules/suppliers/views/farmer_detail_page.dart';
import 'package:mandi/modules/products/views/product_list_page.dart';
import 'package:mandi/modules/products/views/add_edit_farmer_product_page.dart';
import 'package:mandi/modules/purchase_orders/views/purchase_order_list_page.dart';
import 'package:mandi/modules/payments/views/payment_list_page.dart';
import 'package:mandi/modules/farmer_passbook/pages/farmer_passbook_page.dart';
import 'package:mandi/modules/rates/views/mandi_rate_board_page.dart';
import 'package:mandi/modules/gate_pass/pages/gate_pass_page.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';

/// Shown when the signed-in account's role in the active shop is
/// 'supplier' (farmer/zamindar).
class FarmerDashboardPage extends StatelessWidget {
  const FarmerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;
    final member = shopCtx.currentMember;

    final farmers = context.watch<FarmerProvider>().farmers;
    final myFarmer = farmers.firstWhere(
      (s) =>
          s.userId == auth.uid ||
          (member?.email.isNotEmpty == true &&
              s.email.toLowerCase() == member!.email.toLowerCase()),
      orElse: () => Farmer(
        id: member?.id ?? '',
        shopId: shopCtx.currentShopId ?? '',
        name: member?.name ?? 'Farmer',
        phone: member?.phone ?? '',
        email: member?.email ?? '',
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : MColors.textPrimary;
    final subtitleColor = isDark ? MColors.textOnDarkSub : MColors.textSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(shop?.name ?? 'Farmer Dashboard (زمیندار ڈیش بورڈ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.tr(context, 'logout'),
            onPressed: () {
              auth.signOut();
              shopCtx.clear();
            },
          ),
        ],
      ),
      body: LiquidCrystalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmerDetailPage(supplier: myFarmer),
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
                              : 'F',
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
                                Expanded(
                                  child: Text(
                                    'Welcome, ${member?.name ?? ''}',
                                    style: MText.titleLg.copyWith(color: headingColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined,
                                    size: 16, color: MColors.gold),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Farmer (زمیندار) at ${shop?.name ?? 'this shop'}',
                                style: MText.bodySm
                                    .copyWith(color: subtitleColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: MSpacing.lg),

              // Glass Balance Card with WhatsApp Reminder
              GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Money Owed to Me by ${shop?.name ?? "Shop"}',
                        style: MText.labelMd.copyWith(
                          color: isDark ? Colors.white70 : MColors.textSecondary,
                        )),
                    const SizedBox(height: MSpacing.xs),
                    Text(
                      'Rs. ${myFarmer.runningBalance.toStringAsFixed(0)}',
                      style: MText.titleLg.copyWith(
                        color: myFarmer.runningBalance > 0
                            ? MColors.danger
                            : Colors.greenAccent,
                        fontSize: 24,
                      ),
                    ),
                    if (myFarmer.runningBalance > 0 &&
                        (shop?.phone.isNotEmpty == true ||
                            shop?.whatsapp.isNotEmpty == true)) ...[
                      const SizedBox(height: MSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final targetPhone = shop?.whatsapp.isNotEmpty == true
                                ? shop!.whatsapp
                                : (shop?.phone ?? '');
                            WhatsAppShareService.sharePaymentReminder(
                              phone: targetPhone,
                              name: shop?.name ?? 'Shop Owner',
                              pendingBalance: myFarmer.runningBalance,
                              shopName: shop?.name ?? 'Mandi Shop',
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
              Text('Farmer & Crop Services (زمیندار سروسز)',
                  style: MText.titleLg.copyWith(color: headingColor)),
              const SizedBox(height: MSpacing.sm),
              Wrap(
                spacing: MSpacing.sm,
                runSpacing: MSpacing.sm,
                children: [
                  _FarmerTile(
                    icon: Icons.menu_book_rounded,
                    label: AppStrings.tr(context, 'farmer_passbook'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FarmerPassbookPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.confirmation_num_rounded,
                    label: AppStrings.tr(context, 'gate_pass'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GatePassPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.trending_up,
                    label: AppStrings.tr(context, 'rate_board'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MandiRateBoardPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.add_business_outlined,
                    label: 'Offer Crop',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditFarmerProductPage(farmer: myFarmer),
                      ),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.assignment_outlined,
                    label: AppStrings.tr(context, 'purchases'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PurchaseOrderListPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.inventory_2_outlined,
                    label: AppStrings.tr(context, 'products'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductListPage()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MSpacing.lg),
              Text('My Account (میرا کھاتہ)',
                  style: MText.titleLg.copyWith(color: headingColor)),
              const SizedBox(height: MSpacing.sm),
              Wrap(
                spacing: MSpacing.sm,
                runSpacing: MSpacing.sm,
                children: [
                  _FarmerTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: AppStrings.tr(context, 'payments'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentListPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.menu_book_outlined,
                    label: 'Khata Ledger',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FarmerDetailPage(farmer: myFarmer),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FarmerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? MColors.gold : MColors.primary;
    final textColor = isDark ? Colors.white : MColors.textPrimary;

    return GlassCard(
      onTap: onTap,
      borderRadius: AppDimensions.cardRadius,
      padding: const EdgeInsets.symmetric(
          vertical: MSpacing.sm, horizontal: MSpacing.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 96,
          minHeight: 88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: MText.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Backward compatibility alias
typedef SupplierDashboardPage = FarmerDashboardPage;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/responsive.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/data/models/shop_model.dart';
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

  void _showShopSwitcherBottomSheet(BuildContext context) {
    final shopCtx = context.read<ShopContextProvider>();
    final currentShopId = shopCtx.currentShopId;
    final available = shopCtx.availableShops;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tr(sheetCtx, 'switch_mandi_shop'),
                      style: MText.titleLg.copyWith(color: MColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: MColors.textSecondary),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.sm),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: MSpacing.md),
                    child: Text(
                      AppStrings.tr(sheetCtx, 'no_other_shops'),
                      style: MText.bodySm.copyWith(color: MColors.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: MColors.divider),
                      itemBuilder: (_, i) {
                        final s = available[i];
                        final isSelected = s.id == currentShopId;
                        return InkWell(
                          onTap: () async {
                            Navigator.pop(sheetCtx);
                            if (!isSelected) {
                              await shopCtx.switchShop(s.id);
                            }
                          },
                          borderRadius: MRadius.sm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: MSpacing.sm,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? MColors.primary
                                      : MColors.emeraldPale,
                                  backgroundImage: s.logoUrl != null &&
                                          s.logoUrl!.isNotEmpty
                                      ? NetworkImage(s.logoUrl!)
                                      : null,
                                  child: s.logoUrl == null ||
                                          s.logoUrl!.isEmpty
                                      ? Icon(
                                          Icons.storefront_rounded,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : MColors.primary,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: MSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: MText.bodyMd.copyWith(
                                          color: MColors.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      if (s.city.isNotEmpty)
                                        Text(
                                          'Ghalla Mandi, ${s.city}',
                                          style: MText.caption.copyWith(
                                            color: MColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: MColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShopDetailsModal(BuildContext context, Shop? shop) {
    final shopCtx = context.read<ShopContextProvider>();
    final effectiveShopName = (shop != null && shop.name.isNotEmpty)
        ? shop.name
        : 'Saith Commission Shop';
    final effectiveCity = (shop != null && shop.city.isNotEmpty)
        ? shop.city
        : 'Faisalabad';
    final effectiveAddress = (shop != null && shop.address.isNotEmpty)
        ? shop.address
        : 'Shop # 42, New Ghalla Mandi, $effectiveCity';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MSpacing.lg,
              vertical: MSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MColors.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: MSpacing.md),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MColors.primary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: shop != null &&
                              shop.logoUrl != null &&
                              shop.logoUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                shop.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  color: MColors.primary,
                                  size: 28,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              color: MColors.primary,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: MSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveShopName,
                            style: MText.titleLg.copyWith(
                              color: MColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MColors.emeraldPale,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppStrings.tr(sheetCtx, 'commission_agent'),
                                  style: MText.caption.copyWith(
                                    color: MColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• $effectiveCity',
                                style: MText.caption
                                    .copyWith(color: MColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: MColors.textSecondary),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.md),
                const Divider(color: MColors.divider),
                const SizedBox(height: MSpacing.sm),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: MColors.emeraldPale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: MColors.primary, size: 20),
                  ),
                  title: Text(
                    AppStrings.tr(sheetCtx, 'shop_address'),
                    style: MText.labelSm.copyWith(color: MColors.textSecondary),
                  ),
                  subtitle: Text(
                    effectiveAddress,
                    style: MText.bodyMd.copyWith(
                        color: MColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                if (shop != null && shop.phone.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: MColors.emeraldPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_outlined,
                          color: MColors.primary, size: 20),
                    ),
                    title: Text(
                      AppStrings.tr(sheetCtx, 'shop_phone'),
                      style: MText.labelSm
                          .copyWith(color: MColors.textSecondary),
                    ),
                    subtitle: Text(
                      shop.phone,
                      style: MText.bodyMd.copyWith(
                          color: MColors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                if (shop != null && shop.defaultCommissionPercent > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: MColors.goldLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.percent_rounded,
                          color: MColors.goldDark, size: 20),
                    ),
                    title: Text(
                      'Commission Rate',
                      style: MText.labelSm
                          .copyWith(color: MColors.textSecondary),
                    ),
                    subtitle: Text(
                      '${shop.defaultCommissionPercent}%',
                      style: MText.bodyMd.copyWith(
                          color: MColors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                const SizedBox(height: MSpacing.md),
                Row(
                  children: [
                    if (shop != null &&
                        (shop.whatsapp.isNotEmpty || shop.phone.isNotEmpty))
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final target = shop.whatsapp.isNotEmpty
                                ? shop.whatsapp
                                : shop.phone;
                            WhatsAppShareService.launchWhatsApp(
                              phone: target,
                              message:
                                  'Salam, inquiring about Mandi rates and consignment khata at $effectiveShopName.',
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white, size: 18),
                          label: Text(
                            AppStrings.tr(sheetCtx, 'whatsapp_shop'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    if (shopCtx.hasMultipleShops) ...[
                      const SizedBox(width: MSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MColors.primary,
                            side: const BorderSide(color: MColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showShopSwitcherBottomSheet(context);
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text(
                            AppStrings.tr(sheetCtx, 'switch_shop'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: MSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;
    final member = shopCtx.currentMember;

    final effectiveShopName = (shop != null && shop.name.isNotEmpty)
        ? shop.name
        : 'Saith Commission Shop';

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
    final subtitleColor =
        isDark ? MColors.textOnDarkSub : MColors.textSecondary;

    return LiquidCrystalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: InkWell(
            onTap: shopCtx.hasMultipleShops
                ? () => _showShopSwitcherBottomSheet(context)
                : () => _showShopDetailsModal(context, shop),
            borderRadius: MRadius.sm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: MColors.primary.withValues(alpha: 0.12),
                    backgroundImage: shop != null &&
                            shop.logoUrl != null &&
                            shop.logoUrl!.isNotEmpty
                        ? NetworkImage(shop.logoUrl!)
                        : null,
                    child: shop?.logoUrl == null || shop!.logoUrl!.isEmpty
                        ? const Icon(
                            Icons.storefront_rounded,
                            size: 16,
                            color: MColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: MSpacing.xs),
                  Flexible(
                    child: Text(
                      effectiveShopName,
                      overflow: TextOverflow.ellipsis,
                      style: MText.titleMd.copyWith(
                        color: MColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (shopCtx.hasMultipleShops) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: MColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: AppStrings.tr(context, 'shop_details'),
              onPressed: () => _showShopDetailsModal(context, shop),
            ),
            if (shopCtx.hasMultipleShops)
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: AppStrings.tr(context, 'switch_mandi_shop'),
                onPressed: () => _showShopSwitcherBottomSheet(context),
              ),
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
        body: SingleChildScrollView(
          child: AdaptiveContainer(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(
                mobile: MSpacing.md,
                tablet: MSpacing.lg,
                desktop: MSpacing.xl,
              ),
              vertical: MSpacing.lg,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Farmer Profile Greeting Card
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
                                    '${AppStrings.tr(context, 'welcome')}, ${member?.name ?? ''}',
                                    style: MText.titleLg
                                        .copyWith(color: headingColor),
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
                            Text(
                              '${AppStrings.tr(context, 'farmer')} ${AppStrings.tr(context, 'at_this_shop')} $effectiveShopName',
                              style: MText.bodySm
                                  .copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: MSpacing.lg),

              // 2. Glass Balance Card with WhatsApp Reminder
              GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.tr(context, 'money_owed_to_me')} ($effectiveShopName)',
                      style: MText.labelMd.copyWith(
                        color: isDark ? Colors.white70 : MColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: MSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rs. ${myFarmer.runningBalance.toStringAsFixed(0)}',
                        style: MText.displayMd.copyWith(
                          color: myFarmer.runningBalance > 0
                              ? MColors.danger
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (myFarmer.runningBalance > 0 &&
                        shop != null &&
                        (shop.phone.isNotEmpty || shop.whatsapp.isNotEmpty)) ...[
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
                            final targetPhone = shop.whatsapp.isNotEmpty
                                ? shop.whatsapp
                                : shop.phone;
                            WhatsAppShareService.sharePaymentReminder(
                              phone: targetPhone,
                              name: shop.name,
                              pendingBalance: myFarmer.runningBalance,
                              shopName: effectiveShopName,
                            );
                          },
                          icon: const Icon(Icons.send_outlined,
                              color: Colors.white),
                          label: Text(
                            AppStrings.tr(context, 'send_reminder'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: MSpacing.xl),
              Text(AppStrings.tr(context, 'farmer_services'),
                  style: MText.titleLg.copyWith(color: headingColor)),
              const SizedBox(height: MSpacing.sm),
              Wrap(
                spacing: MSpacing.sm,
                runSpacing: MSpacing.sm,
                children: [
                  _FarmerTile(
                    icon: Icons.storefront_rounded,
                    label: AppStrings.tr(context, 'shop_details'),
                    onTap: () => _showShopDetailsModal(context, shop),
                  ),
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
                    label: AppStrings.tr(context, 'offer_crop'),
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
                      MaterialPageRoute(
                          builder: (_) => const ProductListPage()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MSpacing.lg),
              Text(AppStrings.tr(context, 'my_khata'),
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
                      MaterialPageRoute(
                          builder: (_) => const PaymentListPage()),
                    ),
                  ),
                  _FarmerTile(
                    icon: Icons.menu_book_outlined,
                    label: AppStrings.tr(context, 'khata_ledger'),
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
    final minW = context.responsive<double>(mobile: 88, tablet: 104, desktop: 114);
    final maxW = context.responsive<double>(mobile: 98, tablet: 116, desktop: 124);
    final minH = context.responsive<double>(mobile: 96, tablet: 104, desktop: 112);

    return GlassCard(
      onTap: onTap,
      borderRadius: AppDimensions.cardRadius,
      padding: const EdgeInsets.symmetric(
          vertical: MSpacing.sm, horizontal: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minW,
          maxWidth: maxW,
          minHeight: minH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: MColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: MText.caption.copyWith(
                color: MColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.2,
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

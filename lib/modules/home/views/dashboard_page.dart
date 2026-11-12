import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/views/employee_list_page.dart';
import 'package:mandi/modules/customers/views/customer_list_page.dart';
import 'package:mandi/modules/suppliers/views/farmer_list_page.dart';
import 'package:mandi/modules/products/views/product_list_page.dart';
import 'package:mandi/modules/invoices/views/invoice_list_page.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/farmer_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/views/expense_list_page.dart';
import 'package:mandi/modules/payments/views/payment_list_page.dart';
import 'package:mandi/modules/reports/views/reports_page.dart';
import 'package:mandi/modules/roles/views/roles_list_page.dart';
import 'package:mandi/modules/audit_logs/views/audit_log_list_page.dart';
import 'package:mandi/modules/settings/views/shop_settings_page.dart';
import 'package:mandi/modules/purchase_orders/views/purchase_order_list_page.dart';
import 'package:mandi/modules/reports/views/roznamcha_page.dart';
import 'package:mandi/modules/consignment/views/consignment_list_page.dart';
import 'package:mandi/modules/customers/views/payment_recovery_page.dart';
import 'package:mandi/modules/banking/views/bank_ledger_page.dart';
import 'package:mandi/modules/storage/views/storage_and_bardana_page.dart';
import 'package:mandi/modules/weighbridge/views/weighbridge_page.dart';
import 'package:mandi/modules/advances/views/farmer_advance_page.dart';
import 'package:mandi/modules/cross_border/views/cross_border_page.dart';
import 'package:mandi/modules/sms/views/sms_gateway_page.dart';
import 'package:mandi/modules/transfers/views/multi_shop_hub_page.dart';
import 'package:mandi/modules/voice_notes/views/voice_notes_hub_page.dart';
import 'package:mandi/modules/loyalty/views/customer_loyalty_page.dart';
import 'package:mandi/modules/rates/views/mandi_rate_board_page.dart';
import 'package:mandi/modules/payroll/views/staff_payroll_page.dart';
import 'package:mandi/modules/fleet/views/fleet_logistics_page.dart';
import 'package:mandi/modules/quality/views/quality_lab_page.dart';
import 'package:mandi/modules/inventory_labels/views/inventory_labels_page.dart';
import 'package:mandi/modules/offline_sync/views/offline_sync_page.dart';
import 'package:mandi/modules/broadcast/views/broadcast_hub_page.dart';
import 'package:mandi/modules/auction_boli/pages/live_auction_terminal_page.dart';
import 'package:mandi/modules/gate_pass/pages/gate_pass_page.dart';
import 'package:mandi/modules/farmer_passbook/pages/farmer_passbook_page.dart';
import 'package:mandi/modules/partner_capital/pages/partner_capital_page.dart';
import 'package:mandi/modules/warehouse_grid/pages/warehouse_floor_grid_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showShopSwitcherBottomSheet(BuildContext context) {
    final shopCtx = context.read<ShopContextProvider>();
    final currentShopId = shopCtx.currentShopId;
    final available = shopCtx.availableShops;

    showModalBottomSheet(
      context: context,
      backgroundColor: MColors.surfaceDark,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr(sheetCtx, 'switch_mandi_shop'),
                          style: MText.titleLg.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.md),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: MSpacing.md),
                    child: Text(
                      AppStrings.tr(sheetCtx, 'no_other_shops'),
                      style: MText.bodyMd.copyWith(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: MSpacing.xs),
                      itemBuilder: (ctx, i) {
                        final s = available[i];
                        final isSelected = s.id == currentShopId;
                        return GlassCard(
                          padding: const EdgeInsets.all(MSpacing.sm),
                          borderColor: isSelected ? MColors.gold : null,
                          onTap: () async {
                            Navigator.pop(sheetCtx);
                            if (!isSelected) {
                              await shopCtx.switchShop(s.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched to ${s.name}'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isSelected
                                    ? MColors.gold.withValues(alpha: 0.2)
                                    : Colors.white10,
                                backgroundImage: (s.logoUrl != null &&
                                        s.logoUrl!.isNotEmpty)
                                    ? NetworkImage(s.logoUrl!)
                                    : null,
                                child: (s.logoUrl == null ||
                                        s.logoUrl!.isEmpty)
                                    ? Text(
                                        s.name.isNotEmpty
                                            ? s.name[0].toUpperCase()
                                            : 'S',
                                        style: TextStyle(
                                          color: isSelected
                                              ? MColors.gold
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                        color: Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (s.city.isNotEmpty)
                                      Text(
                                        'Grain Market, ${s.city}',
                                        style: MText.caption.copyWith(
                                          color: MColors.textOnDarkSub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: MColors.gold,
                                  size: 22,
                                ),
                            ],
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

  void _editProfileDialog(BuildContext context) {
    final shopCtx = context.read<ShopContextProvider>();
    final member = shopCtx.currentMember;
    if (member == null) return;

    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    final emailCtrl = TextEditingController(text: member.email);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit My Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
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
              };

              await SupabaseService.updateShopMember(
                membershipId: member.id,
                shopId: member.shopId,
                data: updateData,
                actorUid: member.id,
                actorName: member.name,
              );

              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
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
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;

    final customerProv = context.watch<CustomerProvider>();
    final farmerProv = context.watch<FarmerProvider>();
    final invoiceProv = context.watch<InvoiceProvider>();

    final totalReceivables = customerProv.customers.fold<double>(
      0.0,
      (sum, c) => sum + (c.runningBalance > 0 ? c.runningBalance : 0.0),
    );
    final totalPayables = farmerProv.farmers.fold<double>(
      0.0,
      (sum, s) => sum + (s.runningBalance > 0 ? s.runningBalance : 0.0),
    );
    final totalInvoicesCount = invoiceProv.invoices.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: InkWell(
          onTap: shopCtx.hasMultipleShops
              ? () => _showShopSwitcherBottomSheet(context)
              : null,
          borderRadius: MRadius.sm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(shop.logoUrl!),
                  ),
                  const SizedBox(width: MSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    shop?.name ?? 'Mandi',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (shopCtx.hasMultipleShops) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: MColors.gold,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (shopCtx.hasMultipleShops)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: AppStrings.tr(context, 'switch_shop'),
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
      body: LiquidCrystalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              onTap: () => _editProfileDialog(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: MColors.gold.withValues(alpha: 0.2),
                    child: Text(
                      shopCtx.currentMember?.name.isNotEmpty == true
                          ? shopCtx.currentMember!.name[0].toUpperCase()
                          : 'M',
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
                                '${AppStrings.tr(context, 'welcome')}, ${shopCtx.currentMember?.name ?? ''}',
                                style: MText.titleLg.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : MColors.textPrimary,
                                ),
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
                          '${AppStrings.tr(context, 'role')}: ${shopCtx.currentRole?.name ?? '—'}',
                          style: MText.bodySm.copyWith(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? MColors.textOnDarkSub
                                : MColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Role-based Executive KPI Metric Row (Visible to Owners, Managers, Accountants)
            if (shopCtx.hasPermission('view_reports') ||
                shopCtx.hasPermission('view_ledger') ||
                shopCtx.currentRole?.id == 'owner') ...[
              const SizedBox(height: MSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MSpacing.sm,
                        vertical: MSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Receivables',
                                  style: MText.caption.copyWith(
                                    color: isDark ? Colors.white70 : MColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${totalReceivables.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                color: isDark ? Colors.white : MColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${customerProv.customers.length} Customers',
                            style: MText.caption.copyWith(
                              color: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.xs),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MSpacing.sm,
                        vertical: MSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Payables',
                                  style: MText.caption.copyWith(
                                    color: isDark ? Colors.white70 : MColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.trending_down, color: Colors.amberAccent, size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${totalPayables.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                color: isDark ? Colors.white : MColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${farmerProv.farmers.length} Farmers',
                            style: MText.caption.copyWith(
                              color: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.xs),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MSpacing.sm,
                        vertical: MSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Invoices',
                                  style: MText.caption.copyWith(
                                    color: isDark ? Colors.white70 : MColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.receipt, color: Colors.lightBlueAccent, size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$totalInvoicesCount Bills',
                              style: MText.titleMd.copyWith(
                                color: isDark ? Colors.white : MColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'This Season',
                            style: MText.caption.copyWith(
                              color: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: MSpacing.lg),
            Text(
              AppStrings.tr(context, 'manage'),
              style: MText.titleLg.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : MColors.textPrimary,
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                if (shopCtx.hasPermission('manage_employees'))
                  _ManageTile(
                    icon: Icons.badge_outlined,
                    label: AppStrings.tr(context, 'employees'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployeeListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_customers'))
                  _ManageTile(
                    icon: Icons.people_alt_outlined,
                    label: AppStrings.tr(context, 'customers'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_suppliers'))
                  _ManageTile(
                    icon: Icons.agriculture_rounded,
                    label: AppStrings.tr(context, 'farmers'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FarmerListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_purchase') ||
                    shopCtx.hasPermission('manage_suppliers'))
                  _ManageTile(
                    icon: Icons.assignment_outlined,
                    label: AppStrings.tr(context, 'purchases'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PurchaseOrderListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_purchase') ||
                    shopCtx.hasPermission('manage_suppliers') ||
                    shopCtx.hasPermission('create_invoice'))
                  _ManageTile(
                    icon: Icons.gavel_outlined,
                    label: AppStrings.tr(context, 'consignments'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConsignmentListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_products') ||
                    shopCtx.hasPermission('manage_inventory'))
                  _ManageTile(
                    icon: Icons.grass_outlined,
                    label: AppStrings.tr(context, 'products'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_invoice') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.receipt_long_outlined,
                    label: AppStrings.tr(context, 'invoices'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InvoiceListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_expenses'))
                  _ManageTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: AppStrings.tr(context, 'expenses'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpenseListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_receipt') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.payments_outlined,
                    label: AppStrings.tr(context, 'payments'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_customers') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.campaign_outlined,
                    label: AppStrings.tr(context, 'recovery'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentRecoveryPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('view_reports') ||
                    shopCtx.hasPermission('view_analytics'))
                  _ManageTile(
                    icon: Icons.bar_chart_outlined,
                    label: AppStrings.tr(context, 'reports'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('view_reports') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.menu_book_outlined,
                    label: AppStrings.tr(context, 'roznamcha'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RoznamchaPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('view_ledger') ||
                    shopCtx.hasPermission('create_receipt') ||
                    shopCtx.hasPermission('view_reports'))
                  _ManageTile(
                    icon: Icons.account_balance_outlined,
                    label: AppStrings.tr(context, 'bank_and_cheques'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BankLedgerPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_inventory') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.warehouse_outlined,
                    label: AppStrings.tr(context, 'godown_and_bardana'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StorageAndBardanaPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_inventory') ||
                    shopCtx.hasPermission('create_purchase') ||
                    shopCtx.hasPermission('create_invoice'))
                  _ManageTile(
                    icon: Icons.scale_rounded,
                    label: AppStrings.tr(context, 'weighbridge'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WeighbridgePage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_suppliers') ||
                    shopCtx.hasPermission('view_ledger') ||
                    shopCtx.hasPermission('create_purchase'))
                  _ManageTile(
                    icon: Icons.agriculture_rounded,
                    label: AppStrings.tr(context, 'farmer_advances'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FarmerAdvancePage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_purchase') ||
                    shopCtx.hasPermission('manage_products'))
                  _ManageTile(
                    icon: Icons.public_rounded,
                    label: AppStrings.tr(context, 'border_trade'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CrossBorderPage()),
                    ),
                  ),
                _ManageTile(
                  icon: Icons.sms_rounded,
                  label: AppStrings.tr(context, 'sms_gateway'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SmsGatewayPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.hub_outlined,
                  label: AppStrings.tr(context, 'multi_shop'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MultiShopHubPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.mic_rounded,
                  label: AppStrings.tr(context, 'voice_notes'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VoiceNotesHubPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.stars_rounded,
                  label: AppStrings.tr(context, 'loyalty_and_rebates'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerLoyaltyPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.trending_up,
                  label: AppStrings.tr(context, 'rate_board'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MandiRateBoardPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.badge_outlined,
                  label: AppStrings.tr(context, 'staff_payroll'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffPayrollPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.local_shipping_rounded,
                  label: AppStrings.tr(context, 'fleet_and_bilty'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FleetLogisticsPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.biotech_rounded,
                  label: AppStrings.tr(context, 'quality_lab'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QualityLabPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.qr_code_2_rounded,
                  label: AppStrings.tr(context, 'barcode_and_qr'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InventoryLabelsPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.sync_problem_rounded,
                  label: AppStrings.tr(context, 'offline_sync'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OfflineSyncPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.campaign_rounded,
                  label: AppStrings.tr(context, 'rate_broadcast'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BroadcastHubPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.gavel_rounded,
                  label: AppStrings.tr(context, 'live_auction'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LiveAuctionTerminalPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.confirmation_num_rounded,
                  label: AppStrings.tr(context, 'gate_pass'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GatePassPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.menu_book_rounded,
                  label: AppStrings.tr(context, 'farmer_passbook'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FarmerPassbookPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.handshake_rounded,
                  label: AppStrings.tr(context, 'shop_partners'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PartnerCapitalPage()),
                  ),
                ),
                _ManageTile(
                  icon: Icons.grid_on_rounded,
                  label: AppStrings.tr(context, 'warehouse_2d_grid'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WarehouseFloorGridPage()),
                  ),
                ),
                if (shopCtx.hasPermission('manage_roles'))
                  _ManageTile(
                    icon: Icons.shield_outlined,
                    label: AppStrings.tr(context, 'roles'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RolesListPage()),
                    ),
                  ),
                _ManageTile(
                  icon: Icons.history_outlined,
                  label: AppStrings.tr(context, 'audit_logs'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuditLogListPage()),
                  ),
                ),
                if (shopCtx.hasPermission('manage_settings'))
                  _ManageTile(
                    icon: Icons.settings_outlined,
                    label: AppStrings.tr(context, 'settings'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopSettingsPage()),
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

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ManageTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? MColors.gold
                  : MColors.primary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: MText.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : MColors.textPrimary,
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

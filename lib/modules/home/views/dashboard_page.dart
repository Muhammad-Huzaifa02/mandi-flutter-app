import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/views/employee_list_page.dart';
import 'package:mandi/modules/customers/views/customer_list_page.dart';
import 'package:mandi/modules/suppliers/views/supplier_list_page.dart';
import 'package:mandi/modules/products/views/product_list_page.dart';
import 'package:mandi/modules/invoices/views/invoice_list_page.dart';
import 'package:mandi/modules/expenses/views/expense_list_page.dart';
import 'package:mandi/modules/payments/views/payment_list_page.dart';
import 'package:mandi/modules/reports/views/reports_page.dart';
import 'package:mandi/modules/roles/views/roles_list_page.dart';
import 'package:mandi/modules/audit_logs/views/audit_log_list_page.dart';
import 'package:mandi/modules/settings/views/shop_settings_page.dart';
import 'package:mandi/modules/purchase_orders/views/purchase_order_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

              if (context.mounted) {
                await shopCtx.refreshShop();
              }

              Navigator.pop(dialogCtx);
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
                            Text('Welcome, ${shopCtx.currentMember?.name ?? ''}',
                                style: MText.titleLg.copyWith(color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined,
                                size: 16, color: MColors.gold),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Role: ${shopCtx.currentRole?.name ?? '—'}',
                            style: MText.bodySm
                                .copyWith(color: MColors.textOnDarkSub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),
            Text('Manage',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),

            Wrap(
              spacing: MSpacing.sm,
              runSpacing: MSpacing.sm,
              children: [
                if (shopCtx.hasPermission('manage_employees'))
                  _ManageTile(
                    icon: Icons.badge_outlined,
                    label: 'Employees',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployeeListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_customers'))
                  _ManageTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Customers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_suppliers'))
                  _ManageTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Suppliers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SupplierListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_purchase') ||
                    shopCtx.hasPermission('manage_suppliers'))
                  _ManageTile(
                    icon: Icons.assignment_outlined,
                    label: 'Purchases',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PurchaseOrderListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_products') ||
                    shopCtx.hasPermission('manage_inventory'))
                  _ManageTile(
                    icon: Icons.grass_outlined,
                    label: 'Products',
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
                    label: 'Invoices',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InvoiceListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_expenses'))
                  _ManageTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Expenses',
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
                    label: 'Payments',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('view_reports') ||
                    shopCtx.hasPermission('view_analytics'))
                  _ManageTile(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_roles'))
                  _ManageTile(
                    icon: Icons.shield_outlined,
                    label: 'Roles',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RolesListPage()),
                    ),
                  ),
                _ManageTile(
                  icon: Icons.history_outlined,
                  label: 'Audit Logs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuditLogListPage()),
                  ),
                ),
                if (shopCtx.hasPermission('manage_settings'))
                  _ManageTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
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
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(
          vertical: MSpacing.md, horizontal: MSpacing.xs),
      child: SizedBox(
        width: 76,
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

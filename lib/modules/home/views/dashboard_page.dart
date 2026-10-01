import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final auth = context.read<AuthProvider>();
    final shop = shopCtx.currentShop;

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
            Text('Welcome, ${shopCtx.currentMember?.name ?? ''}',
                style: MText.titleLg),
            const SizedBox(height: MSpacing.xs),
            Text('Role: ${shopCtx.currentRole?.name ?? '—'}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.xl),
            const Text('Manage', style: MText.titleLg),
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
                      MaterialPageRoute(builder: (_) => const EmployeeListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_customers'))
                  _ManageTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Customers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_suppliers'))
                  _ManageTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Suppliers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupplierListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_products') ||
                    shopCtx.hasPermission('manage_inventory'))
                  _ManageTile(
                    icon: Icons.grass_outlined,
                    label: 'Products',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_invoice') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Invoices',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoiceListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('manage_expenses'))
                  _ManageTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Expenses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpenseListPage()),
                    ),
                  ),
                if (shopCtx.hasPermission('create_receipt') ||
                    shopCtx.hasPermission('view_ledger'))
                  _ManageTile(
                    icon: Icons.payments_outlined,
                    label: 'Payments',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentListPage()),
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
                      MaterialPageRoute(builder: (_) => const RolesListPage()),
                    ),
                  ),
                _ManageTile(
                  icon: Icons.history_outlined,
                  label: 'Audit Logs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogListPage()),
                  ),
                ),
                if (shopCtx.hasPermission('manage_settings'))
                  _ManageTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopSettingsPage()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MSpacing.xl),
            Text(
              'Products, inventory, customers, suppliers, invoices, '
              'purchases, expenses and reports plug in here next — the shop '
              'context, auth gate and shop-scoped data layer underneath are '
              'now live.',
              style: MText.bodyMd.copyWith(color: MColors.textSecondary),
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
  const _ManageTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MRadius.md,
      child: Container(
        width: 96,
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

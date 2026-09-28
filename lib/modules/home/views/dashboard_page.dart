import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/views/employee_list_page.dart';
import 'package:mandi/modules/customers/views/customer_list_page.dart';
import 'package:mandi/modules/suppliers/views/supplier_list_page.dart';

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

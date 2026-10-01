import 'package:flutter/material.dart';

import 'package:mandi/modules/home/views/dashboard_page.dart';
import 'package:mandi/modules/customers/views/customer_dashboard_page.dart';
import 'package:mandi/modules/suppliers/views/supplier_dashboard_page.dart';

/// Maps the active shop membership's role to the dashboard that role
/// actually sees. This is the piece AppRoot was missing — it always
/// returned DashboardPage regardless of role, so a customer or supplier
/// account landed on the owner/staff screen.
///
/// 'customer' and 'supplier' get their own dedicated pages. Every other
/// role — owner, manager, accountant, sales_staff, inventory_staff, and
/// any future custom staff role an owner creates — shares DashboardPage,
/// which already gates its own tiles by permission (see
/// ShopContextProvider.hasPermission). A null roleId (no active
/// membership) falls through to DashboardPage too, but AppRoot should
/// never reach this function in that state — it checks shopCtx.hasShop
/// first.
Widget dashboardForRole(String? roleId) {
  switch (roleId) {
    case 'customer':
      return const CustomerDashboardPage();
    case 'supplier':
      return const SupplierDashboardPage();
    default:
      return const DashboardPage();
  }
}

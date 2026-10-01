import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/routes/dashboard_router.dart';
import 'package:mandi/modules/home/views/dashboard_page.dart';
import 'package:mandi/modules/customers/views/customer_dashboard_page.dart';
import 'package:mandi/modules/suppliers/views/supplier_dashboard_page.dart';

void main() {
  group('dashboardForRole', () {
    test('customer -> CustomerDashboardPage',
        () => expect(dashboardForRole('customer'), isA<CustomerDashboardPage>()));

    test('supplier -> SupplierDashboardPage',
        () => expect(dashboardForRole('supplier'), isA<SupplierDashboardPage>()));

    test('every internal staff role -> DashboardPage', () {
      for (final roleId in [
        'owner',
        'manager',
        'accountant',
        'sales_staff',
        'inventory_staff',
        'some_future_custom_role', // owners can create custom roles too
      ]) {
        expect(dashboardForRole(roleId), isA<DashboardPage>());
      }
    });

    test('null roleId falls back to DashboardPage rather than crashing',
        () => expect(dashboardForRole(null), isA<DashboardPage>()));
  });
}

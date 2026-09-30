import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/supabase_config.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/theme_provider.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/providers/employee_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/routes/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MandiApp());
}

class MandiApp extends StatelessWidget {
  const MandiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopContextProvider()),
        // Business-data providers (products, customers, invoices, ...)
        // register here in later batches, each keyed off
        // ShopContextProvider.currentShopId via ChangeNotifierProxyProvider.
        ChangeNotifierProxyProvider<ShopContextProvider, EmployeeProvider>(
          create: (_) => EmployeeProvider(),
          update: (_, shopCtx, employeeProvider) =>
              employeeProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, CustomerProvider>(
          create: (_) => CustomerProvider(),
          update: (_, shopCtx, customerProvider) =>
              customerProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, SupplierProvider>(
          create: (_) => SupplierProvider(),
          update: (_, shopCtx, supplierProvider) =>
              supplierProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, shopCtx, productProvider) =>
              productProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, InvoiceProvider>(
          create: (_) => InvoiceProvider(),
          update: (_, shopCtx, invoiceProvider) =>
              invoiceProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, shopCtx, expenseProvider) =>
              expenseProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (_, shopCtx, paymentProvider) =>
              paymentProvider!..updateShop(shopCtx.currentShopId),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mandi',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AppRoot(),
        ),
      ),
    );
  }
}

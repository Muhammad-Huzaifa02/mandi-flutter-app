import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/supabase_config.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/theme/theme_provider.dart';
import 'package:mandi/core/utils/connectivity_service.dart';
import 'package:mandi/core/utils/notification_service.dart';
import 'package:mandi/core/widgets/offline_banner.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/providers/employee_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/routes/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  await NotificationService.initialize();

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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopContextProvider()),
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
        ChangeNotifierProxyProvider<ShopContextProvider, PurchaseOrderProvider>(
          create: (_) => PurchaseOrderProvider(),
          update: (_, shopCtx, purchaseOrderProvider) =>
              purchaseOrderProvider!..updateShop(shopCtx.currentShopId),
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (_, themeProvider, localeProvider, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mandi',
          theme: AppTheme.getDynamicTheme(
            brandColor: themeProvider.primaryBrandColor,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.getDynamicTheme(
            brandColor: themeProvider.primaryBrandColor,
            brightness: Brightness.dark,
          ),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final clampedSystemFactor =
                mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.2);
            final effectiveScale =
                themeProvider.fontScale * clampedSystemFactor;

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(effectiveScale),
              ),
              child: child!,
            );
          },
          home: const OfflineBannerWrapper(child: AppRoot()),
        ),
      ),
    );
  }
}

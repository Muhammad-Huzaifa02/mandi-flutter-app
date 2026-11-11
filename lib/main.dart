import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:mandi/modules/consignment/providers/consignment_provider.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';
import 'package:mandi/modules/storage/providers/storage_provider.dart';
import 'package:mandi/modules/weighbridge/providers/weighbridge_provider.dart';
import 'package:mandi/modules/advances/providers/farmer_advance_provider.dart';
import 'package:mandi/modules/cross_border/providers/cross_border_provider.dart';
import 'package:mandi/modules/sms/providers/sms_provider.dart';
import 'package:mandi/modules/transfers/providers/multi_shop_provider.dart';
import 'package:mandi/modules/voice_notes/providers/audio_note_provider.dart';
import 'package:mandi/modules/loyalty/providers/loyalty_rebate_provider.dart';
import 'package:mandi/modules/rates/providers/mandi_rate_provider.dart';
import 'package:mandi/modules/payroll/providers/staff_payroll_provider.dart';
import 'package:mandi/modules/fleet/providers/fleet_provider.dart';
import 'package:mandi/modules/quality/providers/quality_provider.dart';
import 'package:mandi/modules/inventory_labels/providers/inventory_label_provider.dart';
import 'package:mandi/modules/offline_sync/providers/offline_sync_provider.dart';
import 'package:mandi/modules/broadcast/providers/broadcast_provider.dart';
import 'package:mandi/modules/auction_boli/providers/auction_boli_provider.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';
import 'package:mandi/modules/farmer_passbook/providers/farmer_passbook_provider.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';
import 'package:mandi/modules/warehouse_grid/providers/warehouse_grid_provider.dart';
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
        ChangeNotifierProxyProvider<ShopContextProvider, ConsignmentProvider>(
          create: (_) => ConsignmentProvider(),
          update: (_, shopCtx, consignmentProvider) =>
              consignmentProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, BankProvider>(
          create: (_) => BankProvider(),
          update: (_, shopCtx, bankProvider) =>
              bankProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, StorageProvider>(
          create: (_) => StorageProvider(),
          update: (_, shopCtx, storageProvider) =>
              storageProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, WeighbridgeProvider>(
          create: (_) => WeighbridgeProvider(),
          update: (_, shopCtx, weighbridgeProvider) =>
              weighbridgeProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, FarmerAdvanceProvider>(
          create: (_) => FarmerAdvanceProvider(),
          update: (_, shopCtx, farmerAdvanceProvider) =>
              farmerAdvanceProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, CrossBorderProvider>(
          create: (_) => CrossBorderProvider(),
          update: (_, shopCtx, crossBorderProvider) =>
              crossBorderProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, SmsProvider>(
          create: (_) => SmsProvider(),
          update: (_, shopCtx, smsProvider) =>
              smsProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, MultiShopProvider>(
          create: (_) => MultiShopProvider(),
          update: (_, shopCtx, multiShopProvider) =>
              multiShopProvider!..updateShopContext(
                activeShopId: shopCtx.currentShopId,
                availableShops: shopCtx.availableShops,
              ),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, AudioNoteProvider>(
          create: (_) => AudioNoteProvider(),
          update: (_, shopCtx, audioNoteProvider) =>
              audioNoteProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, LoyaltyRebateProvider>(
          create: (_) => LoyaltyRebateProvider(),
          update: (_, shopCtx, loyaltyRebateProvider) =>
              loyaltyRebateProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, MandiRateProvider>(
          create: (_) => MandiRateProvider(),
          update: (_, shopCtx, mandiRateProvider) =>
              mandiRateProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, StaffPayrollProvider>(
          create: (_) => StaffPayrollProvider(),
          update: (_, shopCtx, staffPayrollProvider) =>
              staffPayrollProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, FleetProvider>(
          create: (_) => FleetProvider(),
          update: (_, shopCtx, fleetProvider) =>
              fleetProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, QualityProvider>(
          create: (_) => QualityProvider(),
          update: (_, shopCtx, qualityProvider) =>
              qualityProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, InventoryLabelProvider>(
          create: (_) => InventoryLabelProvider(),
          update: (_, shopCtx, labelProvider) =>
              labelProvider!..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, OfflineSyncProvider>(
          create: (_) => OfflineSyncProvider(),
          update: (_, shopCtx, syncProvider) =>
              (syncProvider ?? OfflineSyncProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, BroadcastProvider>(
          create: (_) => BroadcastProvider(),
          update: (_, shopCtx, broadcastProvider) =>
              (broadcastProvider ?? BroadcastProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, AuctionBoliProvider>(
          create: (_) => AuctionBoliProvider(),
          update: (_, shopCtx, boliProvider) =>
              (boliProvider ?? AuctionBoliProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, GatePassProvider>(
          create: (_) => GatePassProvider(),
          update: (_, shopCtx, gateProvider) =>
              (gateProvider ?? GatePassProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, FarmerPassbookProvider>(
          create: (_) => FarmerPassbookProvider(),
          update: (_, shopCtx, passbookProvider) =>
              (passbookProvider ?? FarmerPassbookProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, PartnerCapitalProvider>(
          create: (_) => PartnerCapitalProvider(),
          update: (_, shopCtx, partnerProvider) =>
              (partnerProvider ?? PartnerCapitalProvider())..updateShop(shopCtx.currentShopId),
        ),
        ChangeNotifierProxyProvider<ShopContextProvider, WarehouseGridProvider>(
          create: (_) => WarehouseGridProvider(),
          update: (_, shopCtx, gridProvider) =>
              (gridProvider ?? WarehouseGridProvider())..updateShop(shopCtx.currentShopId),
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
          supportedLocales: const [
            Locale('en', ''),
            Locale('ur', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            // Universal standard text scaling:
            // Lock scale factor to 1.0 (standard 100% typography scale) so large/small
            // system font settings or accessibility zoom do not inflate cards or cause RenderFlex overflows.
            // If the user deliberately changed the in-app font scale in settings, allow a safe clamp between 0.9 and 1.1.
            final safeFontScale = themeProvider.fontScale.clamp(0.90, 1.10);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(safeFontScale),
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

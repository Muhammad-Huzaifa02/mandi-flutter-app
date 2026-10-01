import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/auth/views/splash_page.dart';
import 'package:mandi/modules/auth/views/welcome_page.dart';
import 'package:mandi/modules/onboarding/views/no_shop_page.dart';
import 'package:mandi/routes/dashboard_router.dart';

/// The single real gate in the app. Replaces the old pattern of scattered
/// AuthGuard widgets that only checked "is someone logged in" — this one
/// checks the FULL chain: logged in → belongs to a shop → shop is active
/// → which dashboard THIS role actually sees.
///
/// States, in order:
///  1. Auth not yet resolved            → Splash
///  2. Not logged in                    → Welcome (Create Shop / Login)
///  3. Logged in, shop context loading  → Splash
///  4. Logged in, no active shop        → NoShopPage
///  5. Logged in, has an active shop    → dashboardForRole(currentMember.roleId)
///     (owner/manager/accountant/sales_staff/inventory_staff → DashboardPage;
///      customer → CustomerDashboardPage; supplier → SupplierDashboardPage)
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? _loadedForUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shopCtx = context.watch<ShopContextProvider>();

    if (!auth.initialized) {
      return const SplashPage();
    }

    if (!auth.isLoggedIn) {
      // Reset shop context so a fresh login doesn't briefly see the
      // previous user's shop while Postgres catches up.
      if (_loadedForUid != null) {
        _loadedForUid = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<ShopContextProvider>().clear();
        });
      }
      return const WelcomePage();
    }

    // Logged in — kick off shop-context loading exactly once per uid.
    if (_loadedForUid != auth.uid) {
      _loadedForUid = auth.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ShopContextProvider>().loadForUser(auth.uid!);
      });
      return const SplashPage();
    }

    if (shopCtx.isLoading) {
      return const SplashPage();
    }

    if (!shopCtx.hasShop) {
      return const NoShopPage();
    }

    return dashboardForRole(shopCtx.currentMember?.roleId);
  }
}

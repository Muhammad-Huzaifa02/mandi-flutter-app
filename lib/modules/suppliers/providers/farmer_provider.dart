import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Farmer for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class FarmerProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Farmer> _farmers = [];
  bool _isLoading = true;

  List<Farmer> get farmers => List.unmodifiable(_farmers);
  List<Farmer> get suppliers => farmers; // Backward-compatibility
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _farmers = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.suppliersStream(shopId).listen((rows) async {
      final farmerList = rows
          .map((r) => Farmer.fromMap(r['id'] as String, r))
          .toList();

      final memberRows = await SupabaseService.shopMembersForShop(shopId);
      final farmerMembers = memberRows
          .where((m) => m['role_id'] == 'supplier')
          .map((m) => Farmer(
                id: m['id'] as String? ?? '',
                shopId: shopId,
                userId: m['user_id'] as String?,
                name: (m['name'] as String?)?.isNotEmpty == true
                    ? m['name'] as String
                    : 'Farmer',
                phone: m['phone'] as String? ?? '',
                email: m['email'] as String? ?? '',
              ));

      final existingIds = farmerList.map((s) => s.id).toSet();
      final existingUserIds = farmerList.map((s) => s.userId).where((u) => u != null).toSet();
      final existingPhones = farmerList.map((s) => s.phone).where((p) => p.isNotEmpty).toSet();

      for (final sm in farmerMembers) {
        if (!existingIds.contains(sm.id) &&
            !existingUserIds.contains(sm.userId) &&
            (sm.phone.isEmpty || !existingPhones.contains(sm.phone))) {
          farmerList.add(sm);
        }
      }

      _farmers = farmerList
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Farmer> search(String query) {
    if (query.trim().isEmpty) return farmers;
    final q = query.toLowerCase();
    return _farmers
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.phone.contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.productsSupplied.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Full compatibility alias
typedef SupplierProvider = FarmerProvider;

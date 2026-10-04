import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Supplier for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class SupplierProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _suppliers = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.suppliersStream(shopId).listen((rows) async {
      final supplierList = rows
          .map((r) => Supplier.fromMap(r['id'] as String, r))
          .toList();

      final memberRows = await SupabaseService.shopMembersForShop(shopId);
      final supplierMembers = memberRows
          .where((m) => m['role_id'] == 'supplier')
          .map((m) => Supplier(
                id: m['id'] as String? ?? '',
                shopId: shopId,
                userId: m['user_id'] as String?,
                name: (m['name'] as String?)?.isNotEmpty == true
                    ? m['name'] as String
                    : 'Supplier',
                phone: m['phone'] as String? ?? '',
                email: m['email'] as String? ?? '',
              ));

      final existingIds = supplierList.map((s) => s.id).toSet();
      final existingUserIds = supplierList.map((s) => s.userId).where((u) => u != null).toSet();
      final existingPhones = supplierList.map((s) => s.phone).where((p) => p.isNotEmpty).toSet();

      for (final sm in supplierMembers) {
        if (!existingIds.contains(sm.id) &&
            !existingUserIds.contains(sm.userId) &&
            (sm.phone.isEmpty || !existingPhones.contains(sm.phone))) {
          supplierList.add(sm);
        }
      }

      _suppliers = supplierList
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Supplier> search(String query) {
    if (query.trim().isEmpty) return suppliers;
    final q = query.toLowerCase();
    return _suppliers
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

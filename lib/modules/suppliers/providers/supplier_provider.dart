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

    _sub = SupabaseService.suppliersStream(shopId).listen((rows) {
      _suppliers = rows
          .map((r) => Supplier.fromMap(r['id'] as String, r))
          .toList()
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
            s.productsSupplied.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

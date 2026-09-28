import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Customer for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class CustomerProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Customer> _customers = [];
  bool _isLoading = true;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _customers = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.customersStream(shopId).listen((rows) {
      _customers = rows
          .map((r) => Customer.fromMap(r['id'] as String, r))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Customer> search(String query) {
    if (query.trim().isEmpty) return customers;
    final q = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.city.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

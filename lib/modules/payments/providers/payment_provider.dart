import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Payment for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class PaymentProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Payment> _payments = [];
  bool _isLoading = true;

  List<Payment> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _payments = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.paymentsStream(shopId).listen((rows) {
      _payments = rows
          .map((r) => Payment.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Payment> search(String query) {
    if (query.trim().isEmpty) return payments;
    final q = query.toLowerCase();
    return _payments
        .where((p) =>
            p.partyType.toLowerCase().contains(q) ||
            p.reference.toLowerCase().contains(q) ||
            p.method.toLowerCase().contains(q))
        .toList();
  }

  Future<void> addPayment(Payment payment) async {
    await SupabaseService.addPayment(payment.toMap());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

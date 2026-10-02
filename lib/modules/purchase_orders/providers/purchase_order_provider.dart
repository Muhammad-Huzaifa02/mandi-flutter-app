import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every PurchaseOrder for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class PurchaseOrderProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<PurchaseOrder> _purchaseOrders = [];
  bool _isLoading = true;

  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _purchaseOrders = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.purchaseOrdersStream(shopId).listen((rows) {
      _purchaseOrders = rows
          .map((r) => PurchaseOrder.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<PurchaseOrder> search(String query) {
    if (query.trim().isEmpty) return purchaseOrders;
    final q = query.toLowerCase();
    return _purchaseOrders
        .where((po) =>
            po.supplierName.toLowerCase().contains(q) ||
            po.status.toLowerCase().contains(q))
        .toList();
  }

  Future<void> addPurchaseOrder(PurchaseOrder po) async {
    await SupabaseService.addPurchaseOrder(po.toMap());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

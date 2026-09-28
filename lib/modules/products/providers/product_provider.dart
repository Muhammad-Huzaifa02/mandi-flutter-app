import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Product for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class ProductProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Product> _products = [];
  bool _isLoading = true;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock && p.isActive).toList();
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _products = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.productsStream(shopId).listen((rows) {
      _products = rows
          .map((r) => Product.fromMap(r['id'] as String, r))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Product> search(String query) {
    if (query.trim().isEmpty) return products;
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    await SupabaseService.addProduct(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await SupabaseService.updateProduct(product.id, product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await SupabaseService.deleteProduct(productId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

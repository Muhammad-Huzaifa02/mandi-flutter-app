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

    _sub = SupabaseService.customersStream(shopId).listen((rows) async {
      final customerList = rows
          .map((r) => Customer.fromMap(r['id'] as String, r))
          .toList();

      final memberRows = await SupabaseService.shopMembersForShop(shopId);
      final customerMembers = memberRows
          .where((m) => m['role_id'] == 'customer')
          .map((m) => Customer(
                id: m['id'] as String? ?? '',
                shopId: shopId,
                userId: m['user_id'] as String?,
                name: (m['name'] as String?)?.isNotEmpty == true
                    ? m['name'] as String
                    : 'Customer',
                phone: m['phone'] as String? ?? '',
                email: m['email'] as String? ?? '',
              ));

      final existingIds = customerList.map((c) => c.id).toSet();
      final existingUserIds = customerList.map((c) => c.userId).where((u) => u != null).toSet();
      final existingPhones = customerList.map((c) => c.phone).where((p) => p.isNotEmpty).toSet();

      for (final cm in customerMembers) {
        if (!existingIds.contains(cm.id) &&
            !existingUserIds.contains(cm.userId) &&
            (cm.phone.isEmpty || !existingPhones.contains(cm.phone))) {
          customerList.add(cm);
        }
      }

      _customers = customerList
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
            c.email.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

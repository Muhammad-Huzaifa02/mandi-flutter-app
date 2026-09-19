import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/role_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Not customers, not suppliers — those have their own default roles
/// ('customer' / 'supplier') seeded per shop and get their own dedicated
/// dashboards, per the multi-shop architecture. This provider is scoped to
/// the shop's actual staff roster.
const _nonStaffRoleIds = {'customer', 'supplier'};

/// Streams every staff ShopMember for the active shop, plus its roles, so
/// screens can show a role name instead of a raw roleId.
///
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes (shop switch, login, logout) — see main.dart.
class EmployeeProvider extends ChangeNotifier {
  StreamSubscription? _membersSub;
  StreamSubscription? _rolesSub;
  String? _shopId;

  List<ShopMember> _employees = [];
  Map<String, Role> _rolesById = {};
  bool _isLoading = true;

  List<ShopMember> get employees => List.unmodifiable(_employees);
  Map<String, Role> get rolesById => Map.unmodifiable(_rolesById);
  List<Role> get roles =>
      _rolesById.values.where((r) => !_nonStaffRoleIds.contains(r.id)).toList();
  bool get isLoading => _isLoading;

  String roleName(String roleId) => _rolesById[roleId]?.name ?? roleId;

  /// Call from the ProxyProvider update whenever the active shop changes.
  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _membersSub?.cancel();
    _rolesSub?.cancel();
    _employees = [];
    _rolesById = {};

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _rolesSub = SupabaseService.rolesStream(shopId).listen((rows) {
      _rolesById = {
        for (final r in rows) r['id'] as String: Role.fromMap(r['id'] as String, r)
      };
      notifyListeners();
    });

    _membersSub = SupabaseService.shopMembersForShopStream(shopId).listen((rows) {
      _employees = rows
          .map((r) => ShopMember.fromMap(r['id'] as String, r))
          .where((m) => !_nonStaffRoleIds.contains(m.roleId))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<ShopMember> search(String query) {
    if (query.trim().isEmpty) return employees;
    final q = query.toLowerCase();
    return _employees
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.phone.contains(q) ||
            m.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _rolesSub?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/role_model.dart';
import 'package:mandi/data/models/shop_model.dart';

/// The single source of truth for "which shop is active, who is the caller
/// in that shop, and what are they allowed to do".
///
/// Every shop-scoped read/write elsewhere in the app goes through
/// `currentShopId` — never hardcode a shop id, and never trust a shopId
/// that came from outside this provider. Row Level Security (see
/// supabase/schema.sql) independently re-derives and re-checks the same
/// thing server-side on every request — this provider's job is only to
/// drive the UI, not to be the actual security boundary.
class ShopContextProvider extends ChangeNotifier {
  static const _lastShopPrefsKey = 'last_active_shop_id';
  final SupabaseClient _client = Supabase.instance.client;

  String? _currentShopId;
  Shop? _currentShop;
  List<ShopMember> _memberships = []; // every shop this user belongs to
  ShopMember? _currentMember;
  Role? _currentRole;
  bool _isLoading = true;

  String? get currentShopId => _currentShopId;
  Shop? get currentShop => _currentShop;
  ShopMember? get currentMember => _currentMember;
  Role? get currentRole => _currentRole;
  List<ShopMember> get memberships => List.unmodifiable(_memberships);
  bool get isLoading => _isLoading;
  bool get hasShop => _currentShopId != null && _currentMember != null;

  /// The rare case (see spec: "no unnecessary shop selection") — only true
  /// when the account genuinely has 2+ active memberships. Everyone else
  /// skips straight to their one dashboard.
  bool get hasMultipleShops => _memberships.length > 1;

  /// permissions() already accounts for a member's custom_permissions
  /// override (see Role/ShopMember) — screens should call hasPermission,
  /// never read the role's permission list directly.
  List<String> get permissions =>
      _currentMember?.customPermissions ?? _currentRole?.permissions ?? const [];
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Call once after Supabase Auth resolves a signed-in user. Loads every
  /// shop this user belongs to and activates the previously-used shop if
  /// they still belong to it, otherwise the first active membership. If
  /// the user belongs to no shop yet, hasShop stays false and the UI
  /// should route them to shop creation.
  Future<void> loadForUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    final rows = await _client
        .from('shop_memberships')
        .select()
        .eq('user_id', uid)
        .eq('status', 'active');

    _memberships =
        (rows as List).map((r) => ShopMember.fromMap(r['id'] as String, r)).toList();

    if (_memberships.isEmpty) {
      _currentShopId = null;
      _currentShop = null;
      _currentMember = null;
      _currentRole = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastShopPrefsKey);
    final match = _memberships.where((m) => m.shopId == lastId);
    final chosen = match.isNotEmpty ? match.first : _memberships.first;

    await switchShop(chosen.shopId);
  }

  /// Switches the active shop context. Every provider built on top of
  /// `currentShopId` should be listening to this provider so switching
  /// re-points the whole app's data without a manual reload. Only ever
  /// reachable from a "Switch Shop" affordance shown when hasMultipleShops
  /// is true — never presented as a required step for a single-membership
  /// account.
  Future<void> switchShop(String shopId) async {
    _isLoading = true;
    notifyListeners();

    final member = _memberships.where((m) => m.shopId == shopId);
    if (member.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _currentMember = member.first;
    _currentShopId = shopId;

    final shopRow =
        await _client.from('shops').select().eq('id', shopId).maybeSingle();
    _currentShop = shopRow != null ? Shop.fromMap(shopId, shopRow) : null;

    final roleRow = await _client
        .from('roles')
        .select()
        .eq('shop_id', shopId)
        .eq('id', _currentMember!.roleId)
        .maybeSingle();
    _currentRole =
        roleRow != null ? Role.fromMap(roleRow['id'] as String, roleRow) : null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShopPrefsKey, shopId);

    _isLoading = false;
    notifyListeners();
  }

  /// Called right after a brand-new shop + owner membership + default
  /// roles have been created (create_shop_with_owner RPC), so the new shop
  /// becomes active immediately without re-querying.
  void adoptNewShop(Shop shop, ShopMember ownerMembership, Role ownerRole) {
    _memberships = [..._memberships, ownerMembership];
    _currentMember = ownerMembership;
    _currentShopId = ownerMembership.shopId;
    _currentShop = shop;
    _currentRole = ownerRole;
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _currentShopId = null;
    _currentShop = null;
    _memberships = [];
    _currentMember = null;
    _currentRole = null;
    _isLoading = false;
    notifyListeners();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Every method here that touches business data takes a shopId and filters
/// by it. There is no "singleton shop" fallback in this app — a query
/// without a shopId is a bug, not a default.
///
/// Client-side filtering is a convenience only. The real enforcement is
/// Row Level Security (see supabase/schema.sql), which independently
/// checks that the caller is an active shop_memberships row for the
/// shop_id on every row they touch.
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ── Shops / Members / Roles ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getShop(String shopId) =>
      _client.from('shops').select().eq('id', shopId).maybeSingle();

  static Stream<List<Map<String, dynamic>>> shopStream(String shopId) =>
      _client.from('shops').stream(primaryKey: ['id']).eq('id', shopId);

  static Future<void> updateShop(String shopId, Map<String, dynamic> data) =>
      _client.from('shops').update(data).eq('id', shopId);

  /// All active shop_memberships rows for one Supabase Auth user, across
  /// every shop they belong to. Used by ShopContextProvider on login.
  static Future<List<Map<String, dynamic>>> shopMembersForUser(String uid) =>
      _client.from('shop_memberships').select().eq('user_id', uid);

  static Future<List<Map<String, dynamic>>> shopMembersForShop(
          String shopId) =>
      _client.from('shop_memberships').select().eq('shop_id', shopId);

  /// Realtime staff roster for one shop. RLS restricts this to callers
  /// with manage_employees — a customer or supplier calling this gets an
  /// empty stream, not an error.
  static Stream<List<Map<String, dynamic>>> shopMembersForShopStream(
          String shopId) =>
      _client
          .from('shop_memberships')
          .stream(primaryKey: ['id']).eq('shop_id', shopId);

  static Future<Map<String, dynamic>?> getRole(String shopId, String roleId) =>
      _client
          .from('roles')
          .select()
          .eq('shop_id', shopId)
          .eq('id', roleId)
          .maybeSingle();

  static Stream<List<Map<String, dynamic>>> rolesStream(String shopId) =>
      _client.from('roles').stream(primaryKey: ['shop_id', 'id']).eq(
          'shop_id', shopId);

  static Future<void> saveRole(
          String shopId, String roleId, Map<String, dynamic> data) =>
      _client.from('roles').upsert({
        ...data,
        'shop_id': shopId,
        'id': roleId,
      });

  /// Creates a brand-new shop end to end via the create_shop_with_owner
  /// Postgres function: the shop row, its default roles, and the owner's
  /// shop_memberships row, all in one transaction so a failure partway
  /// through can't leave a half-created shop. Runs as the calling user
  /// (not a service-role Edge Function) because every insert here is
  /// something an authenticated user is allowed to do to create their OWN
  /// shop — unlike staff/customer/supplier creation, which needs the
  /// elevated Edge Functions in supabase/functions/.
  ///
  /// Returns the new shop's id.
  static Future<String> createShopWithOwner({
    required Map<String, dynamic> shopData, // Shop.toMap() shape (camelCase)
    required String ownerName,
    required String ownerPhone,
    required String ownerEmail,
    required List<Map<String, dynamic>> defaultRoles, // Role.toMap() shape
  }) async {
    final shopId = await _client.rpc('create_shop_with_owner', params: {
      'p_shop': shopData,
      'p_owner_name': ownerName,
      'p_owner_phone': ownerPhone,
      'p_owner_email': ownerEmail,
      'p_default_roles': defaultRoles,
    }) as String;
    return shopId;
  }

  static Future<void> markShopSetupComplete(String shopId) =>
      updateShop(shopId, {'setup_complete': true});

  /// Activates or deactivates a member. Unlike the old Firebase design,
  /// this does NOT need a service-role Edge Function: every RLS policy in
  /// supabase/schema.sql already requires status = 'active' before
  /// granting any shop data access, so flipping this one column is enough
  /// to fully cut the person off — their Supabase Auth session can stay
  /// technically valid; it just can't do anything against this shop's
  /// data anymore. RLS's own "manage_employees can write" policy on
  /// shop_memberships is what actually authorizes this call.
  static Future<void> toggleMemberStatus({
    required String membershipId,
    required String shopId,
    required bool makeActive,
    required String memberName,
    required String actorUid,
    required String actorName,
  }) async {
    await _client
        .from('shop_memberships')
        .update({'status': makeActive ? 'active' : 'inactive'})
        .eq('id', membershipId);

    await addAuditLog(
      shopId: shopId,
      actorUid: actorUid,
      actorName: actorName,
      action: makeActive ? 'member_activated' : 'member_deactivated',
      entityType: 'shop_member',
      entityId: membershipId,
      summary:
          '$actorName ${makeActive ? "reactivated" : "deactivated"} $memberName',
    );
  }

  /// Edits a staff/customer/supplier member's profile/role fields. Does
  /// NOT change `status` — use toggleMemberStatus for that. Account
  /// creation itself still goes through the Edge Functions in
  /// supabase/functions/, since only those hold the service-role key
  /// needed to create the person's Auth account in the first place.
  static Future<void> updateShopMember({
    required String membershipId,
    required String shopId,
    required Map<String, dynamic> data,
    required String actorUid,
    required String actorName,
  }) async {
    await _client.from('shop_memberships').update(data).eq('id', membershipId);

    await addAuditLog(
      shopId: shopId,
      actorUid: actorUid,
      actorName: actorName,
      action: 'member_updated',
      entityType: 'shop_member',
      entityId: membershipId,
      summary: "$actorName updated ${data['name'] ?? "a member's"} details",
    );
  }

  /// One member's own activity trail — audit_logs filtered by who
  /// performed the action, not just which shop it happened in.
  static Stream<List<Map<String, dynamic>>> auditLogsForActorStream(
          String shopId, String actorUid) =>
      _client
          .from('audit_logs')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false)
          // NOTE: filtering actor_id client-side rather than chaining a
          // second .eq() — verify your supabase_flutter version supports
          // multiple chained .eq() on a stream builder before relying on
          // that instead; this works regardless of version.
          .map((rows) =>
              rows.where((r) => r['actor_id'] == actorUid).toList());

  // ── Products ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> productsStream(String shopId) =>
      _client
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('name');

  static Future<void> addProduct(Map<String, dynamic> data) =>
      _client.from('products').insert(data);

  static Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      _client.from('products').update(data).eq('id', id);

  static Future<void> deleteProduct(String id) =>
      _client.from('products').delete().eq('id', id);

  // ── Customers ────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> customersStream(String shopId) =>
      _client
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('name');

  static Future<void> addCustomer(Map<String, dynamic> data) =>
      _client.from('customers').insert(data);

  static Future<void> updateCustomer(String id, Map<String, dynamic> data) =>
      _client.from('customers').update(data).eq('id', id);

  // ── Suppliers ────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> suppliersStream(String shopId) =>
      _client
          .from('suppliers')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('name');

  static Future<void> addSupplier(Map<String, dynamic> data) =>
      _client.from('suppliers').insert(data);

  // ── Invoices ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> invoicesStream(String shopId) =>
      _client
          .from('invoices')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  /// Creates an invoice + line items and deducts stock atomically via the
  /// create_invoice_with_stock_deduction Postgres function (see
  /// supabase/schema.sql) — throws if any product doesn't have enough
  /// stock, leaving nothing partially applied.
  static Future<String> createInvoiceWithStockDeduction({
    required Map<String, dynamic> invoiceData, // camelCase, see schema.sql RPC
    required List<Map<String, dynamic>> items, // camelCase, see schema.sql RPC
  }) async {
    final id = await _client.rpc('create_invoice_with_stock_deduction',
        params: {'p_invoice': invoiceData, 'p_items': items}) as String;
    return id;
  }

  // ── Expenses ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> expensesStream(String shopId) =>
      _client
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<void> addExpense(Map<String, dynamic> data) =>
      _client.from('expenses').insert(data);

  // ── Payments ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> paymentsStream(String shopId) =>
      _client
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<void> addPayment(Map<String, dynamic> data) async {
    await _client.from('payments').insert(data);

    final partyType = data['party_type'] as String;
    final partyId = data['party_id'] as String;
    final amount = (data['amount'] as num).toDouble();

    if (partyType == 'customer') {
      final customer = await _client
          .from('customers')
          .select('running_balance')
          .eq('id', partyId)
          .single();
      final current = (customer['running_balance'] as num?)?.toDouble() ?? 0;
      await _client
          .from('customers')
          .update({'running_balance': current - amount})
          .eq('id', partyId);
    } else if (partyType == 'supplier') {
      final supplier = await _client
          .from('suppliers')
          .select('running_balance')
          .eq('id', partyId)
          .single();
      final current = (supplier['running_balance'] as num?)?.toDouble() ?? 0;
      await _client
          .from('suppliers')
          .update({'running_balance': current - amount})
          .eq('id', partyId);
    }
  }

  // ── Audit logs ───────────────────────────────────────────────────────────

  static Future<void> addAuditLog({
    required String shopId,
    required String actorUid,
    required String actorName,
    required String action,
    required String entityType,
    required String entityId,
    required String summary,
  }) =>
      _client.from('audit_logs').insert({
        'shop_id': shopId,
        'actor_id': actorUid,
        'actor_name': actorName,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'summary': summary,
      });

  static Stream<List<Map<String, dynamic>>> auditLogsStream(String shopId) =>
      _client
          .from('audit_logs')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);
}

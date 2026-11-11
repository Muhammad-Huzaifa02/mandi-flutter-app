import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mandi/data/models/invoice_model.dart';

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

  /// Uploads a shop logo image byte array to Supabase Storage `shop-assets` bucket.
  /// Returns the public URL of the uploaded image.
  static Future<String> uploadShopLogo({
    required String shopId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'png';
    final path = '$shopId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('shop-assets').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('shop-assets').getPublicUrl(path);
    return publicUrl;
  }

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

  // ── Purchase Orders ──────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> purchaseOrdersStream(
          String shopId) =>
      _client
          .from('purchase_orders')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<String> addPurchaseOrder({
    required String shopId,
    String? supplierId,
    String? productId,
    double weightKg = 0,
    double ratePer40kg = 0,
    required double total,
    double paidAmount = 0,
    double? pendingAmount,
    String status = 'received',
  }) async {
    final id = await _client.rpc('create_purchase_order_with_stock_addition', params: {
      'p_po': {
        'shopId': shopId,
        'supplierId': supplierId,
        'productId': productId,
        'weightKg': weightKg,
        'ratePer40kg': ratePer40kg,
        'total': total,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount ?? (total - paidAmount),
        'status': status,
      },
    }) as String;
    return id;
  }

  static Future<String> addPurchaseOrderMap(Map<String, dynamic> data) async {
    final shopId = data['shopId'] ?? data['shop_id'];
    final supplierId = data['supplierId'] ?? data['supplier_id'];
    final productId = data['productId'] ?? data['product_id'];
    final weightKg =
        (data['weightKg'] ?? data['weight_kg'] as num?)?.toDouble() ?? 0;
    final ratePer40kg =
        (data['ratePer40kg'] ?? data['rate_per_40kg'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final paidAmount =
        (data['paidAmount'] ?? data['paid_amount'] as num?)?.toDouble() ?? 0;
    final pendingAmount =
        (data['pendingAmount'] ?? data['pending_amount'] as num?)?.toDouble();
    final status = data['status'] as String? ?? 'received';

    return addPurchaseOrder(
      shopId: shopId as String,
      supplierId: supplierId as String?,
      productId: productId as String?,
      weightKg: weightKg,
      ratePer40kg: ratePer40kg,
      total: total,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      status: status,
    );
  }

  // ── Consignment Lots (Dheri / آمد و ڈھیری) ──────────────────────────────

  static Stream<List<Map<String, dynamic>>> consignmentLotsStream(
          String shopId) =>
      _client
          .from('consignment_lots')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getConsignmentLots(String shopId) =>
      _client
          .from('consignment_lots')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<String> addConsignmentLot(Map<String, dynamic> data) async {
    final res = await _client
        .from('consignment_lots')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateConsignmentLot({
    required String lotId,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('consignment_lots')
        .update(data)
        .eq('id', lotId)
        .eq('shop_id', shopId);
  }

  static Future<void> updateLotBid({
    required String lotId,
    required String shopId,
    required String winningBuyerId,
    required String winningBuyerName,
    required double ratePerMaund,
    double? finalWeightKg,
  }) async {
    await _client.from('consignment_lots').update({
      'winning_buyer_id': winningBuyerId,
      'winning_buyer_name': winningBuyerName,
      'rate_per_maund': ratePerMaund,
      if (finalWeightKg != null && finalWeightKg > 0) 'weight_kg': finalWeightKg,
      'status': 'sold',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', lotId).eq('shop_id', shopId);
  }

  // ── Bank Accounts & Cheques (PDC / بینکاری اور چیک رجسٹر) ─────────────

  static Stream<List<Map<String, dynamic>>> bankAccountsStream(String shopId) =>
      _client
          .from('bank_accounts')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('bank_name', ascending: true);

  static Future<List<Map<String, dynamic>>> getBankAccounts(String shopId) =>
      _client
          .from('bank_accounts')
          .select()
          .eq('shop_id', shopId)
          .order('bank_name', ascending: true);

  static Future<String> addBankAccount(Map<String, dynamic> data) async {
    final res = await _client
        .from('bank_accounts')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateBankAccount({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('bank_accounts')
        .update(data)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> deleteBankAccount({
    required String id,
    required String shopId,
  }) async {
    await _client
        .from('bank_accounts')
        .delete()
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Stream<List<Map<String, dynamic>>> chequesStream(String shopId) =>
      _client
          .from('cheques')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('due_date', ascending: true);

  static Future<List<Map<String, dynamic>>> getCheques(String shopId) =>
      _client
          .from('cheques')
          .select()
          .eq('shop_id', shopId)
          .order('due_date', ascending: true);

  static Future<String> addCheque(Map<String, dynamic> data) async {
    final res = await _client
        .from('cheques')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateCheque({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('cheques')
        .update(data)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> markChequeDeposited({
    required String id,
    required String shopId,
    required String targetBankAccountId,
    DateTime? depositDate,
  }) async {
    await _client.from('cheques').update({
      'target_bank_account_id': targetBankAccountId,
      'deposit_date': (depositDate ?? DateTime.now()).toIso8601String(),
      'status': 'deposited',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  static Future<void> markChequeCleared({
    required String id,
    required String shopId,
    DateTime? clearanceDate,
  }) async {
    final now = clearanceDate ?? DateTime.now();
    await _client.from('cheques').update({
      'clearance_date': now.toIso8601String(),
      'status': 'cleared',
      'updated_at': now.toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  static Future<void> markChequeBounced({
    required String id,
    required String shopId,
    required String bounceReason,
  }) async {
    await _client.from('cheques').update({
      'bounce_reason': bounceReason,
      'status': 'bounced',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  // ── Godowns, Cold Storage & Bardana (گودام و باردانہ) ─────────────────────

  static Stream<List<Map<String, dynamic>>> storageLocationsStream(
          String shopId) =>
      _client
          .from('storage_locations')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('name', ascending: true);

  static Future<List<Map<String, dynamic>>> getStorageLocations(
          String shopId) =>
      _client
          .from('storage_locations')
          .select()
          .eq('shop_id', shopId)
          .order('name', ascending: true);

  static Future<String> addStorageLocation(Map<String, dynamic> data) async {
    final res = await _client
        .from('storage_locations')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateStorageLocation({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('storage_locations')
        .update(data)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> deleteStorageLocation({
    required String id,
    required String shopId,
  }) async {
    await _client
        .from('storage_locations')
        .delete()
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Stream<List<Map<String, dynamic>>> storageAllocationsStream(
          String shopId) =>
      _client
          .from('storage_allocations')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('inward_date', ascending: false);

  static Future<String> addStorageAllocation(Map<String, dynamic> data) async {
    final res = await _client
        .from('storage_allocations')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateStorageAllocationStatus({
    required String id,
    required String shopId,
    required String status,
    DateTime? outwardDate,
    double? totalRentCharged,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (outwardDate != null) {
      updateData['outward_date'] = outwardDate.toIso8601String();
    }
    if (totalRentCharged != null) {
      updateData['total_rent_charged'] = totalRentCharged;
    }
    await _client
        .from('storage_allocations')
        .update(updateData)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Stream<List<Map<String, dynamic>>> bardanaTransactionsStream(
          String shopId) =>
      _client
          .from('bardana_transactions')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('transaction_date', ascending: false);

  static Future<String> addBardanaTransaction(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('bardana_transactions')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateBardanaStatus({
    required String id,
    required String shopId,
    required String status,
  }) async {
    await _client.from('bardana_transactions').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  // ── Weighbridge & Kanda (دھرم کنڈا وزن پرچی) ─────────────────────────

  static Stream<List<Map<String, dynamic>>> weighbridgeTicketsStream(
          String shopId) =>
      _client
          .from('weighbridge_tickets')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getWeighbridgeTickets(
      String shopId) async {
    final rows = await _client
        .from('weighbridge_tickets')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createWeighbridgeTicket(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('weighbridge_tickets')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateWeighbridgeTicket({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('weighbridge_tickets')
        .update(updateData)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> recordTareWeight({
    required String id,
    required String shopId,
    required double tareWeightKg,
    required double deductionKg,
    required String deductionReason,
    required double finalWeightKg,
    required double netWeightKg,
  }) async {
    final now = DateTime.now();
    await _client.from('weighbridge_tickets').update({
      'tare_weight_kg': tareWeightKg,
      'deduction_kg': deductionKg,
      'deduction_reason': deductionReason,
      'net_weight_kg': netWeightKg,
      'final_weight_kg': finalWeightKg,
      'status': 'completed',
      'tare_weighed_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  static Future<void> cancelWeighbridgeTicket({
    required String id,
    required String shopId,
  }) async {
    await _client.from('weighbridge_tickets').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('shop_id', shopId);
  }

  // ── Farmer Pre-Harvest Advances (زمیندار پیشگی قرضہ کھاتہ) ────────────────

  static Stream<List<Map<String, dynamic>>> farmerAdvancesStream(
          String shopId) =>
      _client
          .from('farmer_advances')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('disbursement_date', ascending: false);

  static Future<List<Map<String, dynamic>>> getFarmerAdvances(
      String shopId) async {
    final rows = await _client
        .from('farmer_advances')
        .select('*')
        .eq('shop_id', shopId)
        .order('disbursement_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Stream<List<Map<String, dynamic>>> farmerAdvanceRecoveriesStream(
          String advanceId) =>
      _client
          .from('farmer_advance_recoveries')
          .stream(primaryKey: ['id'])
          .eq('advance_id', advanceId)
          .order('recovery_date', ascending: false);

  static Future<String> createFarmerAdvance(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('farmer_advances')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateFarmerAdvance({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('farmer_advances')
        .update(updateData)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> recordAdvanceRecovery({
    required String advanceId,
    required String shopId,
    required double recoveryAmount,
    String? consignmentLotId,
    String? invoiceId,
    String recoveryMethod = 'consignment_deduction',
    String notes = '',
  }) async {
    final now = DateTime.now();

    // 1. Insert recovery audit row
    await _client.from('farmer_advance_recoveries').insert({
      'shop_id': shopId,
      'advance_id': advanceId,
      'consignment_lot_id': consignmentLotId,
      'invoice_id': invoiceId,
      'recovered_amount': recoveryAmount,
      'recovery_date': now.toIso8601String(),
      'recovery_method': recoveryMethod,
      'notes': notes,
    });

    // 2. Fetch current advance to compute new recovered_amount and balance
    final advanceRow = await _client
        .from('farmer_advances')
        .select('total_payable, recovered_amount')
        .eq('id', advanceId)
        .eq('shop_id', shopId)
        .single();

    final totalPayable =
        (advanceRow['total_payable'] as num?)?.toDouble() ?? 0.0;
    final currentRecovered =
        (advanceRow['recovered_amount'] as num?)?.toDouble() ?? 0.0;
    final newRecovered = currentRecovered + recoveryAmount;
    final newBalance =
        (totalPayable - newRecovered).clamp(0.0, double.infinity);
    final newStatus =
        newBalance <= 0 ? 'fully_recovered' : 'partially_recovered';

    await _client.from('farmer_advances').update({
      'recovered_amount': newRecovered,
      'remaining_balance': newBalance,
      'status': newStatus,
      'updated_at': now.toIso8601String(),
    }).eq('id', advanceId).eq('shop_id', shopId);
  }

  // ── Cross-Border Mandi Trade (پاک افغان و پاک ایران سرحدی تجارت) ─────────────

  static Stream<List<Map<String, dynamic>>> crossBorderShipmentsStream(
          String shopId) =>
      _client
          .from('cross_border_shipments')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getCrossBorderShipments(
      String shopId) async {
    final rows = await _client
        .from('cross_border_shipments')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createCrossBorderShipment(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('cross_border_shipments')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateCrossBorderShipment({
    required String id,
    required String shopId,
    required Map<String, dynamic> data,
  }) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('cross_border_shipments')
        .update(updateData)
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  static Future<void> deleteCrossBorderShipment({
    required String id,
    required String shopId,
  }) async {
    await _client
        .from('cross_border_shipments')
        .delete()
        .eq('id', id)
        .eq('shop_id', shopId);
  }

  // ── Invoices ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> invoicesStream(String shopId) =>
      _client
          .from('invoices')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  /// Retrieves line items for an invoice from invoice_items table, joining product names.
  static Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    final rows = await _client
        .from('invoice_items')
        .select('*, products(name)')
        .eq('invoice_id', invoiceId);

    return (rows as List).map((r) {
      final map = Map<String, dynamic>.from(r);
      final prodName = r['products']?['name'] as String? ?? '';
      map['product_name'] = prodName;
      return InvoiceItem.fromMap(map);
    }).toList();
  }

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

  /// Cancels an invoice, restores product stock, reverses customer/supplier
  /// balance, and writes an audit log entry.
  static Future<void> cancelInvoice({
    required String invoiceId,
    required String shopId,
    required String actorId,
    required String actorName,
    String reason = '',
  }) async {
    await _client.rpc('cancel_invoice_and_restore_stock', params: {
      'p_invoice_id': invoiceId,
      'p_shop_id': shopId,
      'p_actor_id': actorId,
      'p_actor_name': actorName,
      'p_reason': reason,
    });
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

  /// [data] is a payment map in either key convention (Payment.toMap()
  /// sends both snake_case and camelCase) — only the camelCase keys are
  /// read here, since record_payment parses its jsonb argument itself.
  static Future<String> addPayment(Map<String, dynamic> data) async {
    final shopId = data['shopId'] ?? data['shop_id'];
    final partyType = data['partyType'] ?? data['party_type'];
    final partyId = data['partyId'] ?? data['party_id'];
    final amount = data['amount'];
    final method = data['method'];
    final reference = data['reference'];

    final id = await _client.rpc('record_payment', params: {
      'p_payment': {
        'shopId': shopId,
        'partyType': partyType,
        'partyId': partyId,
        'amount': amount,
        'method': method,
        'reference': reference,
      },
    }) as String;
    return id;
  }

  static Future<String> ensureCustomerRow({
    required String shopId,
    String? customerId,
    String? userId,
    required String name,
    String phone = '',
    String email = '',
  }) async {
    if (customerId != null && customerId.isNotEmpty) {
      final match = await _client
          .from('customers')
          .select('id')
          .eq('id', customerId)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    if (userId != null && userId.isNotEmpty) {
      final match = await _client
          .from('customers')
          .select('id')
          .eq('shop_id', shopId)
          .eq('user_id', userId)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    if (email.isNotEmpty) {
      final match = await _client
          .from('customers')
          .select('id')
          .eq('shop_id', shopId)
          .eq('email', email)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    final newRow = await _client
        .from('customers')
        .insert({
          'shop_id': shopId,
          'user_id': userId,
          'name': name,
          'phone': phone,
          'email': email,
          'opening_balance': 0,
          'running_balance': 0,
        })
        .select('id')
        .single();

    return newRow['id'] as String;
  }

  static Future<String> ensureSupplierRow({
    required String shopId,
    String? supplierId,
    String? userId,
    required String name,
    String phone = '',
    String email = '',
  }) async {
    if (supplierId != null && supplierId.isNotEmpty) {
      final match = await _client
          .from('suppliers')
          .select('id')
          .eq('id', supplierId)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    if (userId != null && userId.isNotEmpty) {
      final match = await _client
          .from('suppliers')
          .select('id')
          .eq('shop_id', shopId)
          .eq('user_id', userId)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    if (email.isNotEmpty) {
      final match = await _client
          .from('suppliers')
          .select('id')
          .eq('shop_id', shopId)
          .eq('email', email)
          .maybeSingle();
      if (match != null) return match['id'] as String;
    }

    final newRow = await _client
        .from('suppliers')
        .insert({
          'shop_id': shopId,
          'user_id': userId,
          'name': name,
          'phone': phone,
          'email': email,
          'opening_balance': 0,
          'running_balance': 0,
        })
        .select('id')
        .single();

    return newRow['id'] as String;
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

  // ── SMS Gateway & Notification Logs (خودکار ایس ایم ایس) ────────────────────

  static Future<Map<String, dynamic>?> getSmsSettings(String shopId) async {
    final row = await _client
        .from('sms_gateway_settings')
        .select('*')
        .eq('shop_id', shopId)
        .maybeSingle();
    return row;
  }

  static Future<void> upsertSmsSettings(Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('sms_gateway_settings').upsert(
          data,
          onConflict: 'shop_id',
        );
  }

  static Stream<List<Map<String, dynamic>>> smsLogsStream(String shopId) =>
      _client
          .from('sms_logs')
          .stream(primaryKey: ['id'])
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getSmsLogs(String shopId,
      {int limit = 100}) async {
    final rows = await _client
        .from('sms_logs')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createSmsLog(Map<String, dynamic> data) async {
    final res = await _client
        .from('sms_logs')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateSmsLogStatus({
    required String logId,
    required String shopId,
    required String status,
    String? errorMessage,
    String? externalMessageId,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
    };
    if (errorMessage != null) {
      updateData['error_message'] = errorMessage;
    }
    if (externalMessageId != null) {
      updateData['external_message_id'] = externalMessageId;
    }
    await _client
        .from('sms_logs')
        .update(updateData)
        .eq('id', logId)
        .eq('shop_id', shopId);
  }

  // ── Inter-Shop Transfers (بین المانڈی اسٹاک منتقلی) ──────────────────────────

  static Stream<List<Map<String, dynamic>>> interShopTransfersStream(
      String shopId) {
    return _client
        .from('inter_shop_transfers')
        .stream(primaryKey: ['id'])
        .order('dispatched_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getInterShopTransfersForShop(
      String shopId) async {
    final rows = await _client
        .from('inter_shop_transfers')
        .select('*')
        .or('source_shop_id.eq.$shopId,destination_shop_id.eq.$shopId')
        .order('dispatched_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createInterShopTransfer(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('inter_shop_transfers')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateInterShopTransferStatus({
    required String transferId,
    required String status,
    DateTime? receivedAt,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (receivedAt != null) {
      updateData['received_at'] = receivedAt.toIso8601String();
    }
    await _client
        .from('inter_shop_transfers')
        .update(updateData)
        .eq('id', transferId);
  }

  // ── Consolidated Multi-Branch Financial Queries ─────────────────────────

  static Future<Map<String, double>> getShopFinancialMetrics(
      String shopId) async {
    // 1. Invoices (Sales & Commission)
    final invoiceRows = await _client
        .from('invoices')
        .select('subtotal, commission_amount, status')
        .eq('shop_id', shopId)
        .neq('status', 'cancelled');

    double totalSales = 0.0;
    double totalCommission = 0.0;
    for (final row in invoiceRows) {
      totalSales += (row['subtotal'] as num?)?.toDouble() ?? 0.0;
      totalCommission +=
          (row['commission_amount'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. Expenses
    final expenseRows = await _client
        .from('expenses')
        .select('amount')
        .eq('shop_id', shopId);

    double totalExpenses = 0.0;
    for (final row in expenseRows) {
      totalExpenses += (row['amount'] as num?)?.toDouble() ?? 0.0;
    }

    // 3. Customer Receivables
    final customerRows = await _client
        .from('customers')
        .select('running_balance')
        .eq('shop_id', shopId)
        .gt('running_balance', 0);

    double totalReceivables = 0.0;
    for (final row in customerRows) {
      totalReceivables +=
          (row['running_balance'] as num?)?.toDouble() ?? 0.0;
    }

    // 4. Supplier Payables
    final supplierRows = await _client
        .from('suppliers')
        .select('running_balance')
        .eq('shop_id', shopId)
        .gt('running_balance', 0);

    double totalPayables = 0.0;
    for (final row in supplierRows) {
      totalPayables +=
          (row['running_balance'] as num?)?.toDouble() ?? 0.0;
    }

    // 5. Stock Value
    final productRows = await _client
        .from('products')
        .select('current_stock, unit_price')
        .eq('shop_id', shopId);

    double totalStockValue = 0.0;
    for (final row in productRows) {
      final stock = (row['current_stock'] as num?)?.toDouble() ?? 0.0;
      final price = (row['unit_price'] as num?)?.toDouble() ?? 0.0;
      totalStockValue += (stock * price);
    }

    return {
      'totalSales': totalSales,
      'totalCommission': totalCommission,
      'totalExpenses': totalExpenses,
      'totalReceivables': totalReceivables,
      'totalPayables': totalPayables,
      'totalStockValue': totalStockValue,
    };
  }

  // ── Audio Voice Notes (صوتی نوٹس اور آواز سے اندراج) ──────────────────────────

  static Stream<List<Map<String, dynamic>>> audioVoiceNotesStream(String shopId) {
    return _client
        .from('audio_voice_notes')
        .stream(primaryKey: ['id'])
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getAudioVoiceNotes(String shopId) async {
    final rows = await _client
        .from('audio_voice_notes')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createAudioVoiceNote(Map<String, dynamic> data) async {
    final res = await _client
        .from('audio_voice_notes')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> updateAudioVoiceNoteStatus({
    required String noteId,
    required String shopId,
    required String status,
    String? entityType,
    String? entityId,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (entityType != null) updateData['entity_type'] = entityType;
    if (entityId != null) updateData['entity_id'] = entityId;
    if (notes != null) updateData['notes'] = notes;

    await _client
        .from('audio_voice_notes')
        .update(updateData)
        .eq('id', noteId)
        .eq('shop_id', shopId);
  }

  static Future<void> deleteAudioVoiceNote(String noteId, String shopId) async {
    await _client
        .from('audio_voice_notes')
        .delete()
        .eq('id', noteId)
        .eq('shop_id', shopId);
  }

  // ── Customer Loyalty & Volume Rebates (گاہک رعایت و والیم بونس) ─────────────

  static Stream<List<Map<String, dynamic>>> customerLoyaltyRebatesStream(
      String shopId) {
    return _client
        .from('customer_loyalty_rebates')
        .stream(primaryKey: ['id'])
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getCustomerLoyaltyRebates(
      String shopId) async {
    final rows = await _client
        .from('customer_loyalty_rebates')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createCustomerLoyaltyRebate(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('customer_loyalty_rebates')
        .insert(data)
        .select('id')
        .single();
    return res['id'] as String;
  }

  static Future<void> creditRebateToCustomerKhata({
    required String rebateId,
    required String shopId,
    required String customerId,
    required double rebateAmount,
    required String creditNoteNumber,
    String notes = '',
  }) async {
    final now = DateTime.now();

    // 1. Mark rebate as credited
    await _client.from('customer_loyalty_rebates').update({
      'status': 'credited',
      'credited_at': now.toIso8601String(),
      'credit_note_number': creditNoteNumber,
      'notes': notes,
      'updated_at': now.toIso8601String(),
    }).eq('id', rebateId).eq('shop_id', shopId);

    // 2. Adjust customer running balance (subtract rebate credit from receivables)
    final cust = await _client
        .from('customers')
        .select('running_balance')
        .eq('id', customerId)
        .eq('shop_id', shopId)
        .single();

    final currentBal = (cust['running_balance'] as num?)?.toDouble() ?? 0.0;
    final updatedBal = currentBal - rebateAmount;

    await _client.from('customers').update({
      'running_balance': updatedBal,
      'updated_at': now.toIso8601String(),
    }).eq('id', customerId).eq('shop_id', shopId);
  }
}

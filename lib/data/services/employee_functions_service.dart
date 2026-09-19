import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase Edge Functions that create staff,
/// customer and supplier accounts (supabase/functions/create-staff,
/// create-customer, create-supplier). These can't be done with a plain
/// client-side insert — creating another person's Auth account requires
/// the service-role key, which must never reach this app, so it happens
/// entirely inside the Edge Function instead.
///
/// Every call re-throws a plain [String] message on failure so UI code can
/// show it directly.
class AccountInviteService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> _invoke(String functionName, Map<String, dynamic> body) async {
    final res = await _client.functions.invoke(functionName, body: body);
    if (res.status != 200) {
      final err = (res.data is Map) ? res.data['error'] : null;
      throw (err as String?) ?? 'Something went wrong. Please try again.';
    }
  }

  /// Invites a new staff member. Never returns a password — the Edge
  /// Function sends an activation email and the person sets their own
  /// password when they accept, per the secure invitation requirement.
  static Future<void> inviteStaff({
    required String shopId,
    required String name,
    required String phone,
    required String email,
    required String roleId,
    String? cnic,
    DateTime? joiningDate,
    double? salary,
    List<String>? customPermissions,
  }) =>
      _invoke('create-staff', {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'email': email,
        'roleId': roleId,
        'cnic': cnic,
        'joiningDate': joiningDate?.toIso8601String(),
        'salary': salary,
        'customPermissions': customPermissions,
      });

  static Future<void> inviteCustomer({
    required String shopId,
    required String name,
    required String phone,
    required String email,
    double? openingBalance,
  }) =>
      _invoke('create-customer', {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'email': email,
        'roleId': 'customer',
        'extra': {'openingBalance': openingBalance},
      });

  static Future<void> inviteSupplier({
    required String shopId,
    required String name,
    required String phone,
    required String email,
    String? productsSupplied,
    double? openingBalance,
  }) =>
      _invoke('create-supplier', {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'email': email,
        'roleId': 'supplier',
        'extra': {
          'productsSupplied': productsSupplied,
          'openingBalance': openingBalance,
        },
      });
}

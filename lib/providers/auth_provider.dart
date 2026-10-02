import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth. Knows nothing about shops — that's
/// ShopContextProvider's job. This just answers "is someone signed in,
/// and who".
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  User? _user;
  bool _initialized = false;
  bool _needsPasswordSetup = false;

  AuthProvider() {
    // authStateChanges doesn't exist on supabase_flutter — it exposes a
    // Stream<AuthState> instead, which fires on sign-in, sign-out, token
    // refresh, and session restoration alike.
    _user = _client.auth.currentSession?.user;
    _initialized = true;
    _client.auth.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      _initialized = true;

      if (state.event == AuthChangeEvent.passwordRecovery) {
        _needsPasswordSetup = true;
      } else if (state.event == AuthChangeEvent.signedIn) {
        final meta = _user?.userMetadata;
        if (meta != null &&
            meta.containsKey('invited_to_shop') &&
            meta['invited_to_shop'] != null &&
            meta['account_activated'] != true) {
          _needsPasswordSetup = true;
        }
      }

      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get initialized => _initialized;
  bool get needsPasswordSetup => _needsPasswordSetup;
  String? get uid => _user?.id;

  void clearNeedsPasswordSetup() {
    _needsPasswordSetup = false;
    notifyListeners();
  }

  Future<void> completeAccountActivation(String newPassword,
      {String? fullName, String? phone}) async {
    await _client.auth.updateUser(UserAttributes(
      password: newPassword,
      data: {
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'invited_to_shop': null,
        'account_activated': true,
      },
    ));
    _needsPasswordSetup = false;
    notifyListeners();
  }

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Pakistani phone-first sign-in. Pass an already-normalized E.164
  /// number (e.g. +923001234567) — see lib/core/utils/pk_phone.dart.
  Future<AuthResponse> signInWithPhone(String e164Phone, String password) =>
      _client.auth.signInWithPassword(phone: e164Phone, password: password);

  Future<AuthResponse> registerWithEmail(
    String email,
    String password, {
    String? fullName,
    Map<String, dynamic>? data,
  }) {
    final meta = <String, dynamic>{
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (data != null) ...data,
    };
    return _client.auth.signUp(
      email: email,
      password: password,
      data: meta.isNotEmpty ? meta : null,
    );
  }

  /// Email-based recovery — sends a reset link. For phone-based recovery,
  /// use sendPhoneOtp/verifyPhoneOtp below (Supabase phone auth uses OTP,
  /// not a reset link, since there's no inbox to click a link from).
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<void> sendPhoneOtp(String e164Phone) =>
      _client.auth.signInWithOtp(phone: e164Phone);

  Future<AuthResponse> verifyPhoneOtp(String e164Phone, String otp) =>
      _client.auth.verifyOTP(
        phone: e164Phone,
        token: otp,
        type: OtpType.sms,
      );

  /// Call after verifyPhoneOtp succeeds, to let the user set a new
  /// password — this is the "Create New Password" step of the forgot-
  /// password flow.
  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  Future<void> signOut() => _client.auth.signOut();
}

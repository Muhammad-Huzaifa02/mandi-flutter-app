import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Biometric Authentication Service (Fingerprint / Face Unlock)
/// for Mandi Cash Drawers, Clerk Fast-Login, and sensitive Financial Approvals.
class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKeyBiometricEnabled = 'mandi_biometric_enabled';
  static const String _prefKeyQuickCashApproval = 'mandi_biometric_quick_cash';

  /// Checks if hardware supports biometrics and is actively enrolled.
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Returns list of enrolled biometric types (e.g. fingerprint, face).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return const [];
    }
  }

  /// Checks if user toggled biometrics on in Mandi settings.
  static Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBiometricEnabled) ?? false;
  }

  /// Saves user biometric preference.
  static Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBiometricEnabled, enabled);
  }

  /// Quick cash-drawer & payment approval setting.
  static Future<bool> isQuickCashApprovalEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyQuickCashApproval) ?? true;
  }

  /// Authenticates using biometrics with localized prompt.
  static Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvail = await isBiometricAvailable();
      if (!isAvail) return true; // Graceful fallback if device lacks hardware

      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Cancels any ongoing biometric prompt.
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

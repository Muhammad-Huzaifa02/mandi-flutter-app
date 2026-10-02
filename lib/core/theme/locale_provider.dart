import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app language locale (English / Urdu اردو).
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';

  LocaleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }

  void toggleLanguage() {
    setLocale(isUrdu ? const Locale('en') : const Locale('ur'));
  }
}

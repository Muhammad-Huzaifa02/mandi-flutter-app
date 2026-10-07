import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  static const _brandKey = 'brand_color_value';

  ThemeMode _mode = ThemeMode.dark; // Default to Deep Emerald Dark
  Color _primaryBrandColor = const Color(0xFF0F6B3C); // Default Emerald Green

  ThemeMode get themeMode => _mode;
  Color get primaryBrandColor => _primaryBrandColor;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };

    final colorVal = prefs.getInt(_brandKey);
    if (colorVal != null) {
      _primaryBrandColor = Color(colorVal);
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> setBrandColor(Color color) async {
    if (_primaryBrandColor == color) return;
    _primaryBrandColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_brandKey, color.toARGB32());
  }
}

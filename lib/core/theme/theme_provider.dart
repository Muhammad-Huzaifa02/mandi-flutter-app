import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _brandKey = 'brand_color_value';
  static const _fontScaleKey = 'font_scale_value';

  // The application is permanently dedicated to Light Mode
  ThemeMode get themeMode => ThemeMode.light;
  Color _primaryBrandColor = const Color(0xFF0F6B3C); // Default Emerald Green
  double _fontScale = 1.0; // 0.85 (Compact), 1.0 (Normal), 1.15 (Large), 1.3 (XL)

  Color get primaryBrandColor => _primaryBrandColor;
  double get fontScale => _fontScale;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final colorVal = prefs.getInt(_brandKey);
    if (colorVal != null) {
      _primaryBrandColor = Color(colorVal);
    }

    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    // No-op: The app is strictly Light Mode only
  }

  Future<void> setBrandColor(Color color) async {
    if (_primaryBrandColor == color) return;
    _primaryBrandColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_brandKey, color.toARGB32());
  }

  Future<void> setFontScale(double scale) async {
    if (_fontScale == scale) return;
    _fontScale = scale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }
}

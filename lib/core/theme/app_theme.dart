import 'package:flutter/material.dart';

/// Mandi's default brand palette — emerald green + gold, per spec.
/// Each shop can eventually override its own accent color (spec §19);
/// this is the platform default a fresh shop starts with.
class MColors {
  static const primary = Color(0xFF0F6B3C); // emerald green
  static const primaryLight = Color(0xFF3E9B6B);
  static const primaryDark = Color(0xFF0A4A29);
  static const gold = Color(0xFFD4A62A);
  static const goldLight = Color(0xFFE8C767);

  static const background = Color(0xFFF7F8F6);
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF14231C);
  static const backgroundDark = Color(0xFF0E1712);

  static const textPrimary = Color(0xFF1A231E);
  static const textSecondary = Color(0xFF5C6B62);
  static const textOnDark = Colors.white;
  static const textOnDarkSub = Color(0xFFB9C7BE);

  static const danger = Color(0xFFC0392B);
  static const warning = Color(0xFFD4A62A);
  static const success = Color(0xFF2E8B57);
}

class MGradient {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MColors.primaryDark, MColors.primary],
  );
}

class MSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class MRadius {
  static final sm = BorderRadius.circular(8);
  static final md = BorderRadius.circular(14);
  static final lg = BorderRadius.circular(20);
  static final full = BorderRadius.circular(999);
}

class MText {
  static const _font = 'Poppins';

  static const displayMd = TextStyle(
      fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w700);
  static const titleLg = TextStyle(
      fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w600);
  static const bodyMd = TextStyle(
      fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w400);
  static const bodySm = TextStyle(
      fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w400);
  static const labelMd = TextStyle(
      fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600);
  static const labelSm = TextStyle(
      fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: MColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MColors.primary,
          brightness: Brightness.light,
          secondary: MColors.gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MColors.surface,
          foregroundColor: MColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: MRadius.md),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: MRadius.md,
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: MColors.surface,
          shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MColors.primary,
          brightness: Brightness.dark,
          secondary: MColors.gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MColors.surfaceDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: MColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
        ),
      );
}

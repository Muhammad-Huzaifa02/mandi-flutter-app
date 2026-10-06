import 'package:flutter/material.dart';

/// Mandi's default brand palette — emerald green + gold, per spec.
class MColors {
  static const primary = Color(0xFF0F6B3C); // emerald green
  static const primaryLight = Color(0xFF3E9B6B);
  static const primaryDark = Color(0xFF0A4A29);
  static const emeraldPale = Color(0xFFEAF5EE); // soft emerald tint
  static const gold = Color(0xFFD4A62A);
  static const goldLight = Color(0xFFE8C767);

  static const background = Color(0xFFF3F6F4);
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

  static const button = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [MColors.primaryLight, MColors.primary],
  );

  static final liquidGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.85),
      Colors.white.withValues(alpha: 0.55),
    ],
  );

  static final liquidGlassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.12),
      Colors.white.withValues(alpha: 0.05),
    ],
  );
}

class MShadows {
  static final soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static final floating3D = [
    BoxShadow(
      color: MColors.primary.withValues(alpha: 0.18),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
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
        scaffoldBackgroundColor: const Color(0xFFF3F6F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: MColors.primary,
          brightness: Brightness.light,
          secondary: MColors.gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: MColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: MColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: MColors.primary.withValues(alpha: 0.35),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: MColors.primary, width: 1.8),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: MColors.primary.withValues(alpha: 0.08),
          color: Colors.white.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
          ),
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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: MColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: MColors.primary, width: 1.8),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          color: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          ),
        ),
      );
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mandi's refined professional brand palette — authoritative emerald green + harvest gold.
/// Architected strictly for high-definition, high-contrast Light Mode UI/UX.
class MColors {
  // Brand Emerald & Gold Palette
  static const primary = Color(0xFF0B6637); // Rich authoritative Emerald Green
  static const primaryLight = Color(0xFF2E8B57); // Sea green
  static const primaryDark = Color(0xFF064423); // Deep emerald
  static const emeraldPale = Color(0xFFEAF5EE); // Soft emerald tint for badges & active states
  static const emeraldSubtle = Color(0xFFF2F8F4); // Micro tint

  static const gold = Color(0xFFC9971E); // Mandi Harvest Gold
  static const goldLight = Color(0xFFFDF6E2); // Warm gentle gold tint
  static const goldDark = Color(0xFF997312); // Deep gold

  // Canvas & Surfaces (Strictly Light Mode Focused)
  static const background = Color(0xFFF4F7F5); // Crisp porcelain mint canvas
  static const surface = Colors.white; // Pure white card surfaces
  static const surfaceSubtle = Color(0xFFF8FAF9); // Alternating table rows & headers
  static const surfaceDark = Color(0xFF14231C); // Deep slate for specific dark overlays
  static const backgroundDark = Color(0xFF0B2B1B);

  // Neutral High-Contrast Typography
  static const textPrimary = Color(0xFF141F18); // Carbon deep forest (#141F18, 95% contrast)
  static const textSecondary = Color(0xFF4E6155); // Slate forest (#4E6155, WCAG AAA compliant)
  static const textMuted = Color(0xFF7E9185); // Hint & timestamp grey
  static const textOnDark = Colors.white;
  static const textOnDarkSub = Color(0xFFB9C7BE);

  // Financial & Operational Semantics
  static const success = Color(0xFF198754); // Positive / Paid / Inflow
  static const successLight = Color(0xFFE8F5E9);
  static const danger = Color(0xFFDC3545); // Due / Debt / Alert
  static const dangerLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFD97706); // Action required / Pending
  static const warningLight = Color(0xFFFEF3C7);
  static const info = Color(0xFF0D6EFD); // Notes / Boli / Challan
  static const infoLight = Color(0xFFE7F1FF);

  // Borders & Structural Dividers
  static const borderLight = Color(0xFFD8E6DE); // Subtle translucent crystal outline
  static const borderMedium = Color(0xFFBFD4C7); // Input field active border
  static const divider = Color(0xFFE5EEE8); // Divider lines
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
      Colors.white.withValues(alpha: 0.92),
      Colors.white.withValues(alpha: 0.75),
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
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static final medium = [
    const BoxShadow(
      color: Color(0x0C0B2B1B),
      blurRadius: 16,
      offset: Offset(0, 5),
    ),
  ];

  static final floating3D = [
    BoxShadow(
      color: MColors.primary.withValues(alpha: 0.14),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 1),
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

/// Standardized Layout & Widget Dimensional Constants for responsive rendering
class AppDimensions {
  static const double cardRadius = 16.0;
  static const double tileWidth = 92.0;
  static const double tileMinHeight = 96.0;
  static const double kpiCardMinHeight = 84.0;
  static const double buttonHeight = 48.0;
  static const double iconSizeSm = 18.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
}

/// Unified cross-platform typographic scale.
/// Provides consistent sizing, weights, line heights, and colors across all screens.
class MText {
  static const _font = 'Poppins';

  static const displayLg = TextStyle(
      fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w700, height: 1.25, color: MColors.textPrimary);
  static const displayMd = TextStyle(
      fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, height: 1.3, color: MColors.textPrimary);
  static const titleLg = TextStyle(
      fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: MColors.textPrimary);
  static const titleMd = TextStyle(
      fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: MColors.textPrimary);
  static const bodyMd = TextStyle(
      fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: MColors.textPrimary);
  static const bodySm = TextStyle(
      fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: MColors.textSecondary);
  static const labelMd = TextStyle(
      fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: MColors.textPrimary);
  static const labelSm = TextStyle(
      fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, height: 1.25, color: MColors.textSecondary);
  static const caption = TextStyle(
      fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w400, height: 1.25, color: MColors.textSecondary);
}

class AppTheme {
  static const Color defaultDarkBg = Color(0xFF0B2B1B);
  static const Color goldAccent = Color(0xFFC9971E);

  static const List<Map<String, dynamic>> brandColorOptions = [
    {'name': 'Emerald Green', 'color': Color(0xFF0B6637)},
    {'name': 'Royal Blue', 'color': Color(0xFF1E3A8A)},
    {'name': 'Deep Red', 'color': Color(0xFF8B0000)},
    {'name': 'Golden Amber', 'color': Color(0xFFB45309)},
  ];

  static ThemeData getDynamicTheme({
    required Color brandColor,
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    final scaffoldBg = isDark ? defaultDarkBg : MColors.background;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brandColor,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF07381E) : MColors.emeraldPale,
      onPrimaryContainer: isDark ? const Color(0xFFA5D6A7) : MColors.primaryDark,
      secondary: goldAccent,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF4A3800) : MColors.goldLight,
      onSecondaryContainer: isDark ? const Color(0xFFFFE082) : const Color(0xFF5A4100),
      tertiary: MColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF0A2E66) : MColors.infoLight,
      onTertiaryContainer: isDark ? const Color(0xFF90CAF9) : const Color(0xFF002B66),
      error: MColors.danger,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF5C1118) : MColors.dangerLight,
      onErrorContainer: isDark ? const Color(0xFFFFCDD2) : const Color(0xFF68000D),
      surface: isDark ? const Color(0xFF14231C) : Colors.white,
      onSurface: isDark ? Colors.white : MColors.textPrimary,
      surfaceContainerHighest: isDark ? const Color(0xFF1E3529) : MColors.surfaceSubtle,
      onSurfaceVariant: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
      outline: isDark ? Colors.white.withValues(alpha: 0.18) : MColors.borderLight,
      outlineVariant: isDark ? Colors.white.withValues(alpha: 0.08) : MColors.divider,
    );

    final baseTextTheme = Typography.material2021(platform: TargetPlatform.android).black.apply(
      fontFamily: 'Poppins',
      bodyColor: isDark ? Colors.white : MColors.textPrimary,
      displayColor: isDark ? Colors.white : MColors.textPrimary,
    );

    final standardizedTextTheme = baseTextTheme.copyWith(
      displayLarge: MText.displayLg.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      displayMedium: MText.displayMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      headlineMedium: MText.titleLg.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      titleLarge: MText.titleLg.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      titleMedium: MText.titleMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      titleSmall: MText.labelMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      bodyLarge: MText.bodyMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      bodyMedium: MText.bodyMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      bodySmall: MText.bodySm.copyWith(color: isDark ? MColors.textOnDarkSub : MColors.textSecondary),
      labelLarge: MText.labelMd.copyWith(color: isDark ? Colors.white : MColors.textPrimary),
      labelMedium: MText.labelSm.copyWith(color: isDark ? MColors.textOnDarkSub : MColors.textSecondary),
      labelSmall: MText.caption.copyWith(color: isDark ? MColors.textOnDarkSub : MColors.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: colorScheme,
      textTheme: standardizedTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: MColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x0F000000),
        titleTextStyle: MText.titleLg.copyWith(
          color: MColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: MColors.textPrimary,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: MColors.textPrimary,
          size: 22,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: brandColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: MText.titleMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColor,
          side: BorderSide(color: brandColor.withValues(alpha: 0.4), width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: MText.titleMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandColor,
          textStyle: MText.titleMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.18) : MColors.borderLight,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.18) : MColors.borderLight,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brandColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.danger, width: 1.4),
        ),
        labelStyle: MText.bodyMd.copyWith(
          color: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
        ),
        hintStyle: MText.bodyMd.copyWith(
          color: isDark ? Colors.white38 : MColors.textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.18) : MColors.borderLight,
            width: 1.2,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: brandColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: brandColor,
        unselectedLabelColor: isDark ? Colors.white70 : MColors.textSecondary,
        labelStyle: MText.labelMd.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: MText.labelMd.copyWith(fontWeight: FontWeight.normal),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF14241C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : MColors.borderLight,
            width: 1.2,
          ),
        ),
        titleTextStyle: MText.titleLg.copyWith(
          color: isDark ? Colors.white : MColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: MText.bodyMd.copyWith(
          color: isDark ? MColors.textOnDarkSub : MColors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF14241C) : Colors.white,
        modalBackgroundColor: isDark ? const Color(0xFF14241C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1B3626) : MColors.emeraldPale,
        selectedColor: brandColor,
        labelStyle: MText.caption.copyWith(
          color: isDark ? Colors.white : MColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : MColors.borderLight,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: MColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B2B22),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  static ThemeData get lightTheme => getDynamicTheme(
        brandColor: const Color(0xFF0B6637),
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => getDynamicTheme(
        brandColor: const Color(0xFF0B6637),
        brightness: Brightness.dark,
      );
}

/// Cross-platform adaptive scroll behavior enabling drag gestures with mouse,
/// trackpad, stylus, and touch on Web, Desktop, Tablet, and Mobile.
class MandiScrollBehavior extends MaterialScrollBehavior {
  const MandiScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

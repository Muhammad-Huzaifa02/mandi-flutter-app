import 'package:flutter/material.dart';

/// Screen size category for adaptive and responsive UI layouts across
/// Mobile, Tablet, and Web/Desktop environments.
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Responsive Breakpoint definitions and utility helpers.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobileMax = 650;
  static const double tabletMax = 1100;
  static const double maxContentWidth = 1240;

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) {
      return ScreenType.mobile;
    } else if (width < tabletMax) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      getScreenType(context) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getScreenType(context) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      getScreenType(context) == ScreenType.desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax;

  /// Returns a responsive value based on current breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  /// Calculates dynamic column count for grid-based dashboards.
  static int gridColumnCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    return value<int>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Convenience BuildContext extension for responsive layouts.
extension ResponsiveContext on BuildContext {
  ScreenType get screenType => ResponsiveBreakpoints.getScreenType(this);
  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
  bool get isWide => ResponsiveBreakpoints.isWide(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      ResponsiveBreakpoints.value<T>(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}

/// Adaptive container that centers content and limits width on Web & Tablets
/// preventing visual stretching on wide monitors while keeping full-width on mobile.
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = context.responsive<EdgeInsetsGeometry>(
      mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

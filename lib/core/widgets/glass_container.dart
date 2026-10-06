import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:mandi/core/theme/app_theme.dart';

/// Reusable 3D Liquid Glassmorphism container for iOS-style floating glass UI cards.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final List<BoxShadow>? customShadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.borderColor,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? MRadius.lg;

    final glassColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.70);

    final borderGrad = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.80));

    final shadows = customShadows ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : MColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.50),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ];

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(MSpacing.lg),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: radius,
            border: Border.all(color: borderGrad, width: 1.2),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        shadows: shadows,
      ),
      child: content,
    );
  }
}

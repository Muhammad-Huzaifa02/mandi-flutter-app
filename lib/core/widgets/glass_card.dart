import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mandi/core/theme/app_theme.dart';

/// A 3D Liquid Crystal Glassmorphism frosted floating container.
/// Combines hardware-accelerated BackdropFilter blur with an iridescent specular border
/// and liquid reflection gradients for an authentic liquid crystal feel.
///
/// Supports [directSunlightMode] for outdoor sunlight legibility and
/// [lowPowerMode] to bypass GPU blur filters on budget devices.
class GlassCard extends StatelessWidget {
  /// Global switch to optimize rendering on low-end budget Android devices.
  static bool lowPowerMode = false;

  /// Global switch for high-contrast outdoor direct sunlight readability.
  static bool directSunlightMode = false;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? borderGradient;
  final double? width;
  final double? height;
  final double blurSigma;
  final bool? isDirectSunlight;
  final bool? isLowPower;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.borderGradient,
    this.width,
    this.height,
    this.blurSigma = 16.0,
    this.isDirectSunlight,
    this.isLowPower,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveSunlight = isDirectSunlight ?? directSunlightMode;
    final effectiveLowPower = isLowPower ?? lowPowerMode;

    // Direct sunlight outdoor mode elevates opacity and contrast
    final defaultBg = effectiveSunlight
        ? (isDark ? const Color(0xE6081A12) : const Color(0xF5FFFFFF))
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85));

    final resolvedBorderColor = borderColor ??
        (effectiveSunlight
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F6B3C))
            : (isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.7)));

    final borderWidth = effectiveSunlight ? 1.8 : 1.2;

    final decoration = BoxDecoration(
      color: backgroundColor ?? defaultBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: resolvedBorderColor,
        width: borderWidth,
      ),
    );

    Widget innerBox = Container(
      padding: padding ?? const EdgeInsets.all(MSpacing.lg),
      decoration: decoration,
      child: child,
    );

    // Performance optimization: Bypass BackdropFilter when in lowPowerMode or blurSigma <= 0
    final shouldBlur = !effectiveLowPower && blurSigma > 0;

    Widget surface = shouldBlur
        ? BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: innerBox,
          )
        : innerBox;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // 3D Ambient Layered Shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: effectiveSunlight ? 0.65 : 0.45)
                : (effectiveSunlight
                    ? const Color(0x33000000)
                    : const Color(0x180F6B3C)),
            blurRadius: effectiveSunlight ? 10 : 18,
            spreadRadius: effectiveSunlight ? 1 : 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x0A000000),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: surface,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: MColors.primary.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A high-frequency Liquid Crystal modal dialog container.
/// Floats with frosted refraction, iridescent highlight borders, and fluid styling.
class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry padding;

  const GlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 480,
    this.borderRadius = 22.0,
    this.blurSigma = 20.0,
    this.padding = const EdgeInsets.all(MSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassCard(
          borderRadius: borderRadius,
          blurSigma: blurSigma,
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                DefaultTextStyle(
                  style: MText.titleLg.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : MColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  child: title!,
                ),
                const SizedBox(height: MSpacing.md),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: MSpacing.md),
              ],
              Flexible(child: content),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: MSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show a [GlassDialog] with spring-scale transition.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

/// A Liquid Crystal frosted bottom sheet container with top rounded corners and drag handle.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry padding;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blurSigma = 20.0,
    this.padding = const EdgeInsets.all(MSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: MSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Helper function to present a frosted [GlassBottomSheet].
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => GlassBottomSheet(child: builder(ctx)),
  );
}

import 'package:flutter/material.dart';

/// A high-performance organic Liquid Crystal canvas widget.
/// Renders ambient fluid luminous orbs across rich deep gradients,
/// giving the underlying app an iridescent, glass-refracting depth.
class LiquidCrystalBackground extends StatelessWidget {
  final Widget child;

  const LiquidCrystalBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ambient liquid gradients
    final baseGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 0.85, 1.0],
            colors: [
              Color(0xFF04180F), // Ultra deep abyss
              Color(0xFF082618), // Deep emerald
              Color(0xFF0D3B25), // Forest jade
              Color(0xFF061A10), // Shadow green
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 0.85, 1.0],
            colors: [
              Color(0xFFEDF6F0), // Pure morning mist
              Color(0xFFDEEFE4), // Soft jade glow
              Color(0xFFE4F3EB), // Crystal mint
              Color(0xFFF3FAF6), // Frosted pearlescent
            ],
          );

    return Stack(
      children: [
        // 1. Primary Liquid Canvas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: baseGradient),
          ),
        ),

        // 2. Liquid Crystal Ambient Glowing Orbs
        // Top-Right Luminous Orb (Emerald / Jade Crystal)
        Positioned(
          top: -80,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF10B981) : const Color(0xFF34D399))
                        .withValues(alpha: isDark ? 0.22 : 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mid-Left Liquid Orb (Warm Gold / Sun reflection on glass)
        Positioned(
          top: 240,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFFD4A62A) : const Color(0xFFFBBF24))
                        .withValues(alpha: isDark ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom-Right Deep Specular Orb (Deep Mint Wave)
        Positioned(
          bottom: -60,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF0F6B3C) : const Color(0xFF10B981))
                        .withValues(alpha: isDark ? 0.20 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Child Application Surface
        Positioned.fill(child: child),
      ],
    );
  }
}

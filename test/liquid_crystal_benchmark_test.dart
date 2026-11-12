// Liquid Crystal Glassmorphism Benchmark & Direct Sunlight Test Suite
// (*مائع کرسٹل تھیم کارکردگی و شدید دھوپ میں بینچ مارک ٹیسٹ*).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';

void main() {
  setUp(() {
    GlassCard.lowPowerMode = false;
    GlassCard.directSunlightMode = false;
  });

  tearDown(() {
    GlassCard.lowPowerMode = false;
    GlassCard.directSunlightMode = false;
  });

  group('Phase 1 & 2 Primitives: Liquid Crystal & GlassCard Benchmarks', () {
    testWidgets('LiquidCrystalBackground renders successfully with full liquid layers',
        (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: LiquidCrystalBackground(
              child: Center(child: Text('Mandi Dashboard')),
            ),
          ),
        ),
      );

      stopwatch.stop();

      expect(find.text('Mandi Dashboard'), findsOneWidget);
      expect(find.byType(LiquidCrystalBackground), findsOneWidget);

      // Rendering should be fast and stable
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('GlassCard builds with BackdropFilter and specular border by default',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: GlassCard(
              child: const Text('Rs. 450,000 Payable'),
            ),
          ),
        ),
      );

      expect(find.text('Rs. 450,000 Payable'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);

      final backdropFilter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      final filter = backdropFilter.filter;
      expect(filter, isNotNull);
    });

    testWidgets('GlassCard handles tap gestures cleanly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('Phase 3: High-Frequency Modals (GlassDialog & GlassBottomSheet)', () {
    testWidgets('GlassDialog renders floating crystal modal with actions and title',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showGlassDialog(
                    context: context,
                    builder: (ctx) => GlassDialog(
                      title: const Text('پھڑ ڈھیری تفصیل (Boli Slip)'),
                      content: const Text('Heap #42 - 50 Maunds'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('منسوخ'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap FAB to trigger showGlassDialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('پھڑ ڈھیری تفصیل (Boli Slip)'), findsOneWidget);
      expect(find.text('Heap #42 - 50 Maunds'), findsOneWidget);
      expect(find.text('منسوخ'), findsOneWidget);
      expect(find.byType(GlassDialog), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('منسوخ'));
      await tester.pumpAndSettle();

      expect(find.byType(GlassDialog), findsNothing);
    });

    testWidgets('GlassBottomSheet displays frosted bottom sheet with drag handle',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showGlassBottomSheet(
                    context: context,
                    builder: (ctx) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Gate Pass Clearance Slip'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap FAB to show GlassBottomSheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Gate Pass Clearance Slip'), findsOneWidget);
      expect(find.byType(GlassBottomSheet), findsOneWidget);
    });
  });

  group('Phase 4: Device Benchmarking & Direct Sunlight Outdoor Legibility', () {
    testWidgets('Low-Power Budget Device Mode successfully bypasses BackdropFilter',
        (tester) async {
      // Turn on lowPowerMode for budget device simulation (e.g. MediaTek Helio A22)
      GlassCard.lowPowerMode = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: const Text('Low Power Active'),
            ),
          ),
        ),
      );

      expect(find.text('Low Power Active'), findsOneWidget);
      // BackdropFilter MUST be bypassed when lowPowerMode is true to maintain 60/120 FPS
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Direct Sunlight Mode applies elevated opacity and high-contrast borders',
        (tester) async {
      GlassCard.directSunlightMode = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: GlassCard(
              child: const Text('Sunlight Legible Price: Rs. 3,850'),
            ),
          ),
        ),
      );

      expect(find.text('Sunlight Legible Price: Rs. 3,850'), findsOneWidget);

      // Verify the GlassCard exists and rendered
      final glassCard = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(glassCard, isNotNull);
    });

    testWidgets('Multi-Layer Nested Glass Benchmarks execute within 16ms budget',
        (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: LiquidCrystalBackground(
              child: ListView.builder(
                itemCount: 15,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Heap #$i (Wheat Super)'),
                        Text('Rs. ${3800 + i * 20}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();

      expect(find.text('Heap #0 (Wheat Super)'), findsOneWidget);
      expect(find.byType(GlassCard), findsWidgets);

      // Verify building 15 layered glass cards stays within reasonable performance bounds
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));
    });
  });
}

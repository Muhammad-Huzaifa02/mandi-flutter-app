import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/responsive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive Breakpoints & Context Helpers', () {
    testWidgets('identifies Mobile breakpoint (< 650px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isMobile, isTrue);
              expect(context.isTablet, isFalse);
              expect(context.isDesktop, isFalse);
              expect(context.isWide, isFalse);
              expect(context.screenType, equals(ScreenType.mobile));
              expect(
                context.responsive<String>(
                  mobile: 'Phone',
                  tablet: 'Tablet',
                  desktop: 'Web',
                ),
                equals('Phone'),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('identifies Tablet breakpoint (650px - 1100px)', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isMobile, isFalse);
              expect(context.isTablet, isTrue);
              expect(context.isDesktop, isFalse);
              expect(context.isWide, isTrue);
              expect(context.screenType, equals(ScreenType.tablet));
              expect(
                context.responsive<String>(
                  mobile: 'Phone',
                  tablet: 'Tablet',
                  desktop: 'Web',
                ),
                equals('Tablet'),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('identifies Web & Desktop breakpoint (>= 1100px)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isMobile, isFalse);
              expect(context.isTablet, isFalse);
              expect(context.isDesktop, isTrue);
              expect(context.isWide, isTrue);
              expect(context.screenType, equals(ScreenType.desktop));
              expect(
                context.responsive<String>(
                  mobile: 'Phone',
                  tablet: 'Tablet',
                  desktop: 'Web',
                ),
                equals('Web'),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('AdaptiveContainer enforces maxWidth on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveContainer(
              maxWidth: 1200,
              child: Text('Adaptive Content'),
            ),
          ),
        ),
      );

      final constrainedBoxFinder = find.byType(ConstrainedBox);
      expect(constrainedBoxFinder, findsWidgets);

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(constrainedBoxFinder);
      final has1200Constraint = constrainedBoxes.any(
        (box) => box.constraints.maxWidth == 1200,
      );
      expect(has1200Constraint, isTrue);
    });

    test('MandiScrollBehavior includes mouse, touch, stylus, and trackpad drag devices', () {
      const behavior = MandiScrollBehavior();
      final devices = behavior.dragDevices;

      expect(devices.contains(PointerDeviceKind.touch), isTrue);
      expect(devices.contains(PointerDeviceKind.mouse), isTrue);
      expect(devices.contains(PointerDeviceKind.stylus), isTrue);
      expect(devices.contains(PointerDeviceKind.trackpad), isTrue);
    });
  });
}

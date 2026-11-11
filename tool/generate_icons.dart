import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  print('Generating Mandi App Icons & Logos...');

  // Target 1: 1024x1024 Master App Icon (for flutter_launcher_icons)
  final appIcon = img.Image(width: 1024, height: 1024);

  // Background: Rich Deep Forest Emerald Gradient (#0A3D24 to #0E6038)
  for (int y = 0; y < 1024; y++) {
    final t = y / 1024.0;
    final r = (10 + (4 * t)).round();
    final g = (61 + (35 * t)).round();
    final b = (36 + (20 * t)).round();
    final color = img.ColorRgb8(r, g, b);
    for (int x = 0; x < 1024; x++) {
      appIcon.setPixel(x, y, color);
    }
  }

  // Draw Subtle Golden Circular Ring / Seal in the center
  final goldColor = img.ColorRgba8(228, 185, 68, 255); // Rich Warm Gold (#E4B944)
  final goldDark = img.ColorRgba8(195, 145, 30, 255);
  final goldLight = img.ColorRgba8(250, 215, 110, 255);
  final whiteColor = img.ColorRgba8(255, 255, 255, 255);
  final softWhite = img.ColorRgba8(240, 248, 242, 230);

  // Draw concentric glow
  img.drawCircle(
    appIcon,
    x: 512,
    y: 512,
    radius: 440,
    color: img.ColorRgba8(20, 95, 56, 120),
  );

  img.drawCircle(
    appIcon,
    x: 512,
    y: 512,
    radius: 410,
    color: img.ColorRgba8(228, 185, 68, 40),
  );

  // Outer Golden Ring
  for (int r = 385; r <= 392; r++) {
    img.drawCircle(appIcon, x: 512, y: 512, radius: r, color: goldColor);
  }

  // Draw Golden Wheat Sheaf / Crop Ear (گندم کی بالی) in the center
  // Central Stem (Vertical Golden Pillar)
  for (int x = 506; x <= 518; x++) {
    for (int y = 230; y <= 770; y++) {
      appIcon.setPixel(x, y, goldColor);
    }
  }

  // Top Seed Pearl
  img.fillCircle(appIcon, x: 512, y: 220, radius: 22, color: goldLight);

  // Grains (Gilded Wheat Grains on left and right)
  final grainLevels = [
    {'y': 280, 'len': 70, 'thick': 12},
    {'y': 340, 'len': 110, 'thick': 14},
    {'y': 400, 'len': 145, 'thick': 16},
    {'y': 460, 'len': 170, 'thick': 18},
    {'y': 520, 'len': 185, 'thick': 18},
    {'y': 580, 'len': 195, 'thick': 18},
    {'y': 640, 'len': 180, 'thick': 16},
    {'y': 700, 'len': 140, 'thick': 14},
  ];

  for (final g in grainLevels) {
    final yCenter = g['y'] as int;
    final len = g['len'] as int;
    final thick = g['thick'] as int;

    // Left Grain (pointing up-left at 45 degrees)
    for (int d = 0; d < len; d++) {
      final px = 512 - (d * 0.95).round();
      final py = yCenter - (d * 0.95).round();
      for (int t = -thick ~/ 2; t <= thick ~/ 2; t++) {
        img.drawCircle(appIcon, x: px + t, y: py, radius: 5, color: goldLight);
      }
    }

    // Right Grain (pointing up-right at 45 degrees)
    for (int d = 0; d < len; d++) {
      final px = 512 + (d * 0.95).round();
      final py = yCenter - (d * 0.95).round();
      for (int t = -thick ~/ 2; t <= thick ~/ 2; t++) {
        img.drawCircle(appIcon, x: px + t, y: py, radius: 5, color: goldLight);
      }
    }
  }

  // Save assets/icons/app_icon.png
  final appIconBytes = img.encodePng(appIcon);
  File('assets/icons/app_icon.png').writeAsBytesSync(appIconBytes);
  print('Saved assets/icons/app_icon.png (${appIconBytes.length} bytes)');

  // Target 2: Splash/Login Brand Logo (Transparent PNG with Wheat Emblem + MANDI Typography)
  // 600x600 transparent canvas
  final brandLogo = img.Image(width: 600, height: 600, numChannels: 4);
  brandLogo.clear(img.ColorRgba8(0, 0, 0, 0)); // transparent

  // Draw Golden Wheat Sheaf on brand logo (scaled to fit top 400px)
  for (int x = 296; x <= 304; x++) {
    for (int y = 90; y <= 420; y++) {
      brandLogo.setPixel(x, y, goldColor);
    }
  }
  img.fillCircle(brandLogo, x: 300, y: 82, radius: 14, color: goldLight);

  final brandGrains = [
    {'y': 120, 'len': 40, 'thick': 8},
    {'y': 160, 'len': 65, 'thick': 9},
    {'y': 200, 'len': 85, 'thick': 10},
    {'y': 240, 'len': 100, 'thick': 11},
    {'y': 280, 'len': 110, 'thick': 11},
    {'y': 320, 'len': 110, 'thick': 10},
    {'y': 360, 'len': 95, 'thick': 9},
    {'y': 400, 'len': 70, 'thick': 8},
  ];

  for (final g in brandGrains) {
    final yCenter = g['y'] as int;
    final len = g['len'] as int;

    // Left Grain
    for (int d = 0; d < len; d++) {
      final px = 300 - (d * 0.95).round();
      final py = yCenter - (d * 0.95).round();
      img.drawCircle(brandLogo, x: px, y: py, radius: 4, color: goldLight);
    }
    // Right Grain
    for (int d = 0; d < len; d++) {
      final px = 300 + (d * 0.95).round();
      final py = yCenter - (d * 0.95).round();
      img.drawCircle(brandLogo, x: px, y: py, radius: 4, color: goldLight);
    }
  }

  // Draw Elegant "M A N D I" and "غلہ منڈی" Text Emblems on Brand Logo
  // Letter M
  _drawThickLine(brandLogo, 170, 480, 170, 530, 6, whiteColor);
  _drawThickLine(brandLogo, 170, 480, 195, 510, 5, whiteColor);
  _drawThickLine(brandLogo, 195, 510, 220, 480, 5, whiteColor);
  _drawThickLine(brandLogo, 220, 480, 220, 530, 6, whiteColor);

  // Letter A
  _drawThickLine(brandLogo, 240, 530, 260, 480, 6, whiteColor);
  _drawThickLine(brandLogo, 260, 480, 280, 530, 6, whiteColor);
  _drawThickLine(brandLogo, 248, 512, 272, 512, 5, whiteColor);

  // Letter N
  _drawThickLine(brandLogo, 305, 530, 305, 480, 6, whiteColor);
  _drawThickLine(brandLogo, 305, 480, 340, 530, 6, whiteColor);
  _drawThickLine(brandLogo, 340, 530, 340, 480, 6, whiteColor);

  // Letter D
  _drawThickLine(brandLogo, 365, 480, 365, 530, 6, whiteColor);
  _drawThickLine(brandLogo, 365, 480, 390, 480, 5, whiteColor);
  _drawThickLine(brandLogo, 390, 480, 405, 495, 5, whiteColor);
  _drawThickLine(brandLogo, 405, 495, 405, 515, 5, whiteColor);
  _drawThickLine(brandLogo, 405, 515, 390, 530, 5, whiteColor);
  _drawThickLine(brandLogo, 390, 530, 365, 530, 5, whiteColor);

  // Letter I
  _drawThickLine(brandLogo, 430, 480, 430, 530, 6, whiteColor);

  // Subtitle Golden Bar
  for (int x = 200; x <= 400; x++) {
    for (int y = 555; y <= 557; y++) {
      brandLogo.setPixel(x, y, goldColor);
    }
  }

  final brandLogoBytes = img.encodePng(brandLogo);
  File('assets/images/logo.png').writeAsBytesSync(brandLogoBytes);
  print('Saved assets/images/logo.png (${brandLogoBytes.length} bytes)');

  print('Logo generation completed successfully!');
}

void _drawThickLine(img.Image image, int x1, int y1, int x2, int y2, int thickness, img.Color color) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final steps = math.max(dx.abs(), dy.abs());
  if (steps == 0) return;

  final xInc = dx / steps;
  final yInc = dy / steps;

  double cx = x1.toDouble();
  double cy = y1.toDouble();

  for (int i = 0; i <= steps; i++) {
    img.fillCircle(image, x: cx.round(), y: cy.round(), radius: thickness ~/ 2, color: color);
    cx += xInc;
    cy += yInc;
  }
}

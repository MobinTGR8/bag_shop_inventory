import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates a 1024×1024 app icon with a bag/shopping icon
/// on a gradient blue-to-teal background.
void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // ── Background gradient (top-left to bottom-right) ──
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final t = (x + y) / (2.0 * size); // 0..1 diagonal gradient
      final r = (24 + (40 - 24) * t).round();    // #182C → #285A
      final g = (44 + (90 - 44) * t).round();
      final b = (60 + (143 - 60) * t).round();
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // ── Helper: draw a filled rounded rectangle ──
  void fillRoundedRect(int cx, int cy, int w, int h, int radius, int r, int g, int b) {
    final x1 = cx - w ~/ 2;
    final y1 = cy - h ~/ 2;
    final x2 = cx + w ~/ 2;
    final y2 = cy + h ~/ 2;
    for (int y = y1; y < y2; y++) {
      for (int x = x1; x < x2; x++) {
        if (x < 0 || x >= size || y < 0 || y >= size) continue;
        // Simple rounded-corner check
        final bool inTopLeft = x < x1 + radius && y < y1 + radius;
        final bool inTopRight = x >= x2 - radius && y < y1 + radius;
        final bool inBottomLeft = x < x1 + radius && y >= y2 - radius;
        final bool inBottomRight = x >= x2 - radius && y >= y2 - radius;
        if (inTopLeft || inTopRight || inBottomLeft || inBottomRight) {
          // Distance to nearest corner center
          int cx2 = inTopLeft || inBottomLeft ? x1 + radius : x2 - radius - 1;
          int cy2 = inTopLeft || inTopRight ? y1 + radius : y2 - radius - 1;
          int dx = x - cx2;
          int dy = y - cy2;
          if (dx * dx + dy * dy > radius * radius) continue;
        }
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  // ── Bag icon body (white, slightly rounded) ──
  // Main bag body
  fillRoundedRect(size ~/ 2, size ~/ 2 + 40, 420, 480, 60, 255, 255, 255);

  // Bag flap / top strip
  fillRoundedRect(size ~/ 2, size ~/ 2 - 80, 300, 60, 20, 255, 255, 255);

  // Handle (arc-like) — draw as two vertical strips
  const handleW = 20;
  const handleLeft = size ~/ 2 - 80;
  const handleRight = size ~/ 2 + 80;
  const handleTop = size ~/ 2 - 220;
  const handleBottom = size ~/ 2 - 80;

  for (int y = handleTop; y < handleBottom; y++) {
    for (int x = handleLeft; x < handleLeft + handleW; x++) {
      if (x >= 0 && x < size && y >= 0 && y < size) {
        image.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    for (int x = handleRight; x < handleRight + handleW; x++) {
      if (x >= 0 && x < size && y >= 0 && y < size) {
        image.setPixelRgb(x, y, 255, 255, 255);
      }
    }
  }

  // Handle top curve (simple arc approximation)
  for (int a = 180; a <= 360; a += 5) {
    double rad = a * 3.14159 / 180;
    int x = (size ~/ 2 + (120 * cos(rad)).round());
    int y = (size ~/ 2 - 220 + (80 * sin(rad)).round());
    for (int dx = -6; dx <= 6; dx++) {
      for (int dy = -6; dy <= 6; dy++) {
        int px = x + dx, py = y + dy;
        if (px >= 0 && px < size && py >= 0 && py < size) {
          if (dx * dx + dy * dy <= 36) {
            image.setPixelRgb(px, py, 255, 255, 255);
          }
        }
      }
    }
  }

  // ── Save ──
  final pngBytes = img.encodePng(image);
  final outDir = Directory('assets/icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('assets/icons/app_icon.png');
  outFile.writeAsBytesSync(pngBytes);
  // ignore: avoid_print — script output
  print('Icon saved to ${outFile.absolute.path}');
}

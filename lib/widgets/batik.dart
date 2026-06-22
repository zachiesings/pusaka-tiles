import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared painting helpers so the board, tray and drag-feedback all render tiles
/// identically. Batik motifs are drawn procedurally — no image assets, no
/// copyright. A tile gets a bevel + a subtle motif derived from its color.
class BatikTile {
  BatikTile._();

  /// Paint one filled block tile inside [rect].
  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.06);
    final radius = Radius.circular(rect.width * 0.18);
    final rr = RRect.fromRectAndRadius(r, radius);

    // Body
    canvas.drawRRect(rr, Paint()..color = color.withOpacity(opacity));

    // Top bevel highlight
    final hi = Paint()
      ..color = Colors.white.withOpacity(0.14 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.42),
        radius,
      ),
      hi,
    );

    // Bottom shade
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.bottom - r.height * 0.3, r.width, r.height * 0.3),
        radius,
      ),
      Paint()..color = Colors.black.withOpacity(0.16 * opacity),
    );

    // Batik motif: a small cream "kawung" diamond + center dot.
    final cx = r.center.dx, cy = r.center.dy, s = r.width * 0.26;
    final motif = Paint()
      ..color = Palette.cream.withOpacity(0.26 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.045;
    final path = Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy)
      ..lineTo(cx, cy + s)
      ..lineTo(cx - s, cy)
      ..close();
    canvas.drawPath(path, motif);
    canvas.drawCircle(Offset(cx, cy), r.width * 0.06,
        Paint()..color = Palette.cream.withOpacity(0.3 * opacity));

    // Border
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.black.withOpacity(0.28 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.03,
    );
  }
}

/// A subtle full-screen "parang" diagonal batik background.
class BatikBackground extends StatelessWidget {
  final Widget child;
  const BatikBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bg1, Palette.bg0],
        ),
      ),
      child: CustomPaint(
        painter: _ParangPainter(),
        child: child,
      ),
    );
  }
}

class _ParangPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.gold.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    const gap = 46.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      final path = Path();
      for (double y = 0; y <= size.height; y += 8) {
        final x = d + y + math.sin(y / 26) * 10;
        if (y == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParangPainter oldDelegate) => false;
}

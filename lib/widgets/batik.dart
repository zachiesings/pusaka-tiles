import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared tile painter for the falling tiles — luminous, glassy, cool. A glossy
/// top + soft glow rim, distinct from Blast's matte wooden blocks.
class BatikTile {
  BatikTile._();

  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.07);
    final radius = Radius.circular(rect.width * 0.16);
    final rr = RRect.fromRectAndRadius(r, radius);
    // outer glow
    canvas.drawRRect(
      rr.inflate(rect.width * 0.02),
      Paint()
        ..color = color.withOpacity(0.35 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * 0.08),
    );
    // glassy body
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.30)!, color, Color.lerp(color, Colors.black, 0.18)!],
        ).createShader(r),
    );
    // top sheen
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.34), radius),
      Paint()..color = Colors.white.withOpacity(0.22 * opacity),
    );
    // bright rim
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withOpacity(0.35 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.02,
    );
  }
}

/// Premium living background: indigo-night gradient + drifting cool glows + a
/// cached MEGA MENDUNG cloud-scallop motif (Pusaka Tiles "Panggung Malam"
/// identity — deliberately different from Blast).
class BatikBackground extends StatefulWidget {
  final Widget child;
  final bool dim;
  const BatikBackground({super.key, required this.child, this.dim = false});

  @override
  State<BatikBackground> createState() => _BatikBackgroundState();
}

class _BatikBackgroundState extends State<BatikBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _GlowPainter(_c.value)),
              ),
            ),
          ),
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _MendungPainter()))),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          widget.child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t;
  _GlowPainter(this.t);

  static const _blobs = [
    (Palette.indigo, 0.18, 0.12, 360.0, 0.0),
    (Palette.teal, 0.88, 0.84, 360.0, 0.5),
    (Palette.pink, 0.90, 0.18, 300.0, 0.25),
    (Palette.violet, 0.10, 0.76, 320.0, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _blobs) {
      final phase = (t + b.$5) * 2 * math.pi;
      final cx = b.$2 * size.width + math.sin(phase) * 28;
      final cy = b.$3 * size.height + math.cos(phase) * 28;
      final r = b.$4;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [b.$1.withOpacity(0.24), b.$1.withOpacity(0.0)])
              .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
    final spark = Paint();
    for (var i = 0; i < 14; i++) {
      final seed = i * 0.121;
      final x = ((seed + 0.04) % 1.0) * size.width;
      final prog = (t * (0.35 + seed) + seed) % 1.0;
      final y = size.height * (1.05 - prog);
      final a = math.sin(prog * math.pi) * 0.24;
      spark.color = (i.isEven ? Palette.cyan : Palette.goldLt).withOpacity(a);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3), spark);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.t != t;
}

/// MEGA MENDUNG — rows of nested cloud scallops (Cirebon batik).
class _MendungPainter extends CustomPainter {
  const _MendungPainter();

  @override
  void paint(Canvas c, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Palette.cyan.withOpacity(0.07);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Palette.indigo.withOpacity(0.06);
    const gap = 58.0, bump = 28.0;
    for (double y = 0; y < size.height + gap; y += gap) {
      for (var layer = 0; layer < 3; layer++) {
        final yy = y + layer * 4.5;
        final p = layer == 0 ? stroke : faint;
        final path = Path()..moveTo(-bump, yy);
        for (double x = -bump; x < size.width + bump; x += bump) {
          path.arcToPoint(Offset(x + bump, yy),
              radius: const Radius.circular(bump / 2), clockwise: false);
        }
        c.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MendungPainter old) => false;
}

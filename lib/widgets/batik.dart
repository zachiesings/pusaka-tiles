import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Glassy, luminous falling-tile painter (distinct from Blast's matte wood).
class BatikTile {
  BatikTile._();

  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.07);
    final radius = Radius.circular(rect.width * 0.16);
    final rr = RRect.fromRectAndRadius(r, radius);
    canvas.drawRRect(
      rr.inflate(rect.width * 0.02),
      Paint()
        ..color = color.withOpacity(0.4 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * 0.09),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.32)!, color, Color.lerp(color, Colors.black, 0.2)!],
        ).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.34), radius),
      Paint()..color = Colors.white.withOpacity(0.24 * opacity),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.02,
    );
  }
}

/// PANGGUNG MALAM background — a night stage: swaying overhead spotlight beams,
/// a glowing stage-floor horizon, and rising music specks. Deliberately NOT the
/// drifting glow-blob look; a theatrical identity unique to Tiles.
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
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

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
          colors: [Palette.bg0, Palette.bg1, Palette.bg0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _StagePainter(_c.value)),
              ),
            ),
          ),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          widget.child,
        ],
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  final double t;
  _StagePainter(this.t);

  static const _beams = [
    (Palette.indigo, 0.22, 0.6),
    (Palette.teal, 0.5, -0.5),
    (Palette.pink, 0.78, 0.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // overhead spotlight beams (trapezoids sweeping slowly)
    for (final b in _beams) {
      final sway = math.sin(t * 2 * math.pi + b.$3) * size.width * 0.06;
      final topX = b.$2 * size.width + sway;
      final spread = size.width * 0.18;
      final path = Path()
        ..moveTo(topX - size.width * 0.03, 0)
        ..lineTo(topX + size.width * 0.03, 0)
        ..lineTo(topX + spread, size.height * 0.85)
        ..lineTo(topX - spread, size.height * 0.85)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [b.$1.withOpacity(0.16), b.$1.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.85)),
      );
    }
    // glowing stage-floor horizon
    final floor = Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.violet.withOpacity(0.0), Palette.violet.withOpacity(0.22)],
        ).createShader(floor),
    );
    canvas.drawLine(
      Offset(0, size.height * 0.82),
      Offset(size.width, size.height * 0.82),
      Paint()..color = Palette.gold.withOpacity(0.12)..strokeWidth = 1.5,
    );
    // rising music specks
    final spark = Paint();
    for (var i = 0; i < 16; i++) {
      final seed = i * 0.111;
      final x = ((seed * 1.7 + 0.05) % 1.0) * size.width;
      final prog = (t * (0.3 + seed) + seed) % 1.0;
      final y = size.height * (1.0 - prog);
      final a = math.sin(prog * math.pi) * 0.3;
      spark.color = (i.isEven ? Palette.cyan : Palette.goldLt).withOpacity(a);
      canvas.drawCircle(Offset(x, y), 1.3 + (i % 3), spark);
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) => old.t != t;
}

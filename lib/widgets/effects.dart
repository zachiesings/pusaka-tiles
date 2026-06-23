import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/constants.dart';

/// A field of slowly drifting, twinkling motes — cheap ambient "stage dust" for
/// premium screens. Self-animated via a [Ticker]; drop into a Stack with
/// `Positioned.fill` behind your content.
class SparkleField extends StatefulWidget {
  final int count;
  final Color color;
  final double maxRadius;
  final bool rising; // motes drift upward (true) or just twinkle in place
  const SparkleField({
    super.key,
    this.count = 26,
    this.color = Palette.goldLt,
    this.maxRadius = 2.2,
    this.rising = true,
  });

  @override
  State<SparkleField> createState() => _SparkleFieldState();
}

class _SparkleFieldState extends State<SparkleField> {
  Ticker? _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((d) => setState(() => _t = d.inMicroseconds / 1e6))..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SparklePainter(
            t: _t,
            count: widget.count,
            color: widget.color,
            maxR: widget.maxRadius,
            rising: widget.rising,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  final int count;
  final Color color;
  final double maxR;
  final bool rising;
  _SparklePainter({
    required this.t,
    required this.count,
    required this.color,
    required this.maxR,
    required this.rising,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (var i = 0; i < count; i++) {
      final seed = i * 0.6180339887;
      final fx = (seed * 7.13) % 1.0;
      final baseY = (seed * 11.7) % 1.0;
      final speed = 6 + (i % 5) * 4.0;
      final drift = rising ? ((t * speed + i * 53.0) % (h + 40)) : 0.0;
      final x = w * fx + math.sin(t * 0.5 + i) * 10;
      final y = rising ? (h - drift + 20) : h * baseY + math.sin(t * 0.4 + i) * 8;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2.2 + i * 1.3));
      final r = (0.8 + (i % 3) * 0.6).clamp(0.6, maxR);
      final p = Paint()..color = color.withOpacity(0.5 * tw);
      canvas.drawCircle(Offset(x, y), r, p);
      if (tw > 0.85) {
        final s = r * 2.4;
        final star = Paint()
          ..color = color.withOpacity(0.7 * tw)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - s, y), Offset(x + s, y), star);
        canvas.drawLine(Offset(x, y - s), Offset(x, y + s), star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}

/// A premium sheen that sweeps across [child] (e.g. the gold wordmark) on a loop.
class ShimmerSweep extends StatefulWidget {
  final Widget child;
  final Duration period;
  const ShimmerSweep({super.key, required this.child, this.period = const Duration(seconds: 4)});

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = (_c.value * 1.6) - 0.3; // -0.3 .. 1.3
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.55),
                Colors.white.withOpacity(0.0),
              ],
              stops: [
                (p - 0.12).clamp(0.0, 1.0),
                p.clamp(0.0, 1.0),
                (p + 0.12).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

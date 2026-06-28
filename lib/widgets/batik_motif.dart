import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../state/game_controller.dart';

/// A germinating batik motif (kawung/ceplok-inspired): a central rosette of
/// radial petals that blooms outward in rings as [bloom] (0..1) grows, with a
/// seed at the centre. Used both as a live bloom behind the play and as the
/// grown motif on the result card. Pure painting — cheap enough to animate.
class BatikMotifPainter extends CustomPainter {
  final double bloom; // 0..1 how far the motif has germinated
  final Color color;
  final double opacity; // master alpha
  final double phase; // 0..1 gentle counter-rotation between rings
  BatikMotifPainter({
    required this.bloom,
    required this.color,
    this.opacity = 1,
    this.phase = 0,
  });

  static const int _petals = 8;
  static const int _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final b = bloom.clamp(0.0, 1.0);
    if (b <= 0.01 || opacity <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.5;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.02).clamp(1.0, 4.0);

    for (var ring = 0; ring < _rings; ring++) {
      final ringBloom = (b * _rings - ring).clamp(0.0, 1.0);
      if (ringBloom <= 0) break;
      final rr = radius * (0.22 + ring * 0.27) * ringBloom;
      final spin = phase * 2 * math.pi * 0.06 * (ring.isEven ? 1 : -1);
      for (var i = 0; i < _petals; i++) {
        final ang = i / _petals * 2 * math.pi + spin;
        final px = c.dx + math.cos(ang) * rr;
        final py = c.dy + math.sin(ang) * rr;
        final petal = Rect.fromCenter(
          center: Offset(px, py),
          width: radius * 0.16 * ringBloom,
          height: radius * 0.34 * ringBloom,
        );
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(ang + math.pi / 2);
        canvas.translate(-px, -py);
        canvas.drawOval(petal, stroke..color = color.withOpacity(0.5 * opacity * ringBloom));
        canvas.restore();
      }
    }
    canvas.drawCircle(
        c, radius * 0.06 * (0.5 + 0.5 * b), Paint()..color = color.withOpacity(0.85 * opacity * b));
  }

  @override
  bool shouldRepaint(covariant BatikMotifPainter o) =>
      o.bloom != bloom || o.color != color || o.opacity != opacity || o.phase != phase;
}

/// A static grown motif for the result card / shop preview.
class BatikMotifView extends StatelessWidget {
  final double bloom;
  final Color color;
  final double size;
  const BatikMotifView({super.key, this.bloom = 1, required this.color, this.size = 72});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: BatikMotifPainter(bloom: bloom, color: color)),
      );
}

/// Live batik bloom over the board: germinates with the combo and the ensemble's
/// fullness, settles back when the run ends. Subtle (low opacity) so it never
/// fights the tiles. Off-ish under reduced motion (no rotation, lower alpha).
class BatikBloomOverlay extends StatelessWidget {
  final TilesGameController gc;
  final bool reduceMotion;
  const BatikBloomOverlay({super.key, required this.gc, this.reduceMotion = false});

  @override
  Widget build(BuildContext context) {
    // Bloom grows with combo, reinforced by how awake the ensemble is.
    final bloom =
        ((gc.combo / 36).clamp(0.0, 1.0) * 0.7 + gc.ensemble.fullness * 0.3).clamp(0.0, 1.0);
    if (bloom <= 0.02) return const SizedBox.shrink();
    final warm = Color.lerp(Palette.violet, Palette.gold, gc.ensemble.fullness)!;
    return IgnorePointer(
      child: Opacity(
        opacity: reduceMotion ? 0.08 : 0.14,
        child: CustomPaint(
          painter: BatikMotifPainter(
            bloom: bloom,
            color: warm,
            phase: reduceMotion ? 0.0 : gc.ensemble.gongPhase,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

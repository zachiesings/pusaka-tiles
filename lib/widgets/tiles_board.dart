import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/engine/tiles_engine.dart';
import 'batik.dart';

/// Paints the 4-lane falling-tiles board. Tiles are positioned + sized by their
/// beat span, so longer notes are taller tiles and the song scrolls in rhythm.
class TilesBoardPainter extends CustomPainter {
  final TilesEngine engine;
  final int flashLane;
  final double flashT;
  final double repaint;

  TilesBoardPainter({required this.engine, this.flashLane = -1, this.flashT = 0})
      : repaint = engine.scroll + flashT;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = engine.columns;
    final laneW = size.width / cols;
    final pxPerBeat = size.height / K.visibleRows;

    // Lane backgrounds + dividers
    for (var c = 0; c < cols; c++) {
      canvas.drawRect(Rect.fromLTWH(c * laneW, 0, laneW, size.height),
          Paint()..color = c.isEven ? Palette.gridCell : Palette.panel);
    }
    final divider = Paint()..color = Palette.gridLine..strokeWidth = 1;
    for (var c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * laneW, 0), Offset(c * laneW, size.height), divider);
    }

    // Tap flash glow + spark burst rising from the tapped lane
    if (flashLane >= 0 && flashT > 0) {
      final x = flashLane * laneW;
      final r = Rect.fromLTWH(x, size.height - pxPerBeat * 1.4, laneW, pxPerBeat * 1.4);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Palette.gold.withOpacity(0.5 * flashT), Palette.gold.withOpacity(0)],
          ).createShader(r),
      );
      // sparks flying up & out (deterministic from flashT — no per-particle state)
      final cxp = x + laneW / 2;
      final baseY = size.height - pxPerBeat;
      final spark = Paint()..color = Palette.cream.withOpacity(flashT);
      for (var i = 0; i < 7; i++) {
        final ang = -math.pi / 2 + (i - 3) * 0.32;
        final dist = (1 - flashT) * pxPerBeat * 1.8;
        final px = cxp + math.cos(ang) * dist;
        final py = baseY + math.sin(ang) * dist;
        canvas.drawCircle(Offset(px, py), laneW * 0.05 * (0.4 + flashT * 0.6), spark);
      }
    }

    // Hit line near the bottom (1 beat up)
    final hitY = size.height - pxPerBeat;
    canvas.drawLine(Offset(0, hitY), Offset(size.width, hitY),
        Paint()..color = Palette.gold.withOpacity(0.35)..strokeWidth = 2);

    // Visible tiles (rows are sorted by startBeat)
    final start = engine.nextTap - 4 < 0 ? 0 : engine.nextTap - 4;
    for (var i = start; i < engine.rows.length; i++) {
      final t = engine.rows[i];
      final top = size.height - (t.startBeat + t.beats - engine.scroll) * pxPerBeat;
      final h = t.beats * pxPerBeat;
      if (top > size.height) break;      // this and all later tiles are below
      if (top + h < 0) continue;          // already scrolled off the top
      final rect = Rect.fromLTWH(t.activeColumn * laneW, top, laneW, h);
      final color = Palette.laneColors[t.activeColumn % Palette.laneColors.length];
      BatikTile.paint(canvas, rect, color);
      if (t.tapped) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(laneW * 0.08), Radius.circular(laneW * 0.12)),
          Paint()..color = Palette.gold.withOpacity(0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilesBoardPainter old) => old.repaint != repaint;
}

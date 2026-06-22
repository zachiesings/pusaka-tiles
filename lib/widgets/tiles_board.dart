import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/engine/tiles_engine.dart';
import 'batik.dart';

/// Paints the 4-lane falling-tiles board from the engine state. The hit line
/// sits at the bottom; active tiles scroll down and light up gold once tapped.
class TilesBoardPainter extends CustomPainter {
  final TilesEngine engine;
  final int flashLane;
  final double flashT;
  final double repaint; // drives shouldRepaint

  TilesBoardPainter({required this.engine, this.flashLane = -1, this.flashT = 0})
      : repaint = engine.scroll + flashT;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = engine.columns;
    final laneW = size.width / cols;
    final rowH = size.height / K.visibleRows;

    // Lane backgrounds (subtle alternating wood) + dividers.
    for (var c = 0; c < cols; c++) {
      final paint = Paint()..color = c.isEven ? Palette.gridCell : Palette.panel;
      canvas.drawRect(Rect.fromLTWH(c * laneW, 0, laneW, size.height), paint);
    }
    final divider = Paint()
      ..color = Palette.gridLine
      ..strokeWidth = 1;
    for (var c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * laneW, 0), Offset(c * laneW, size.height), divider);
    }

    // Tap flash: a gold glow rising from the bottom of the tapped lane.
    if (flashLane >= 0 && flashT > 0) {
      final x = flashLane * laneW;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - rowH * 1.4, laneW, rowH * 1.4),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Palette.gold.withOpacity(0.45 * flashT), Palette.gold.withOpacity(0)],
          ).createShader(Rect.fromLTWH(x, size.height - rowH * 1.4, laneW, rowH * 1.4)),
      );
    }

    // Hit line near the bottom.
    final hitY = size.height - rowH;
    canvas.drawLine(
      Offset(0, hitY),
      Offset(size.width, hitY),
      Paint()
        ..color = Palette.gold.withOpacity(0.35)
        ..strokeWidth = 2,
    );

    // Visible rows.
    final first = engine.scroll.floor() - 1;
    final last = (engine.scroll + K.visibleRows).ceil() + 1;
    for (var r = first; r <= last; r++) {
      if (r < 0 || r >= engine.rows.length) continue;
      final row = engine.rows[r];
      final topY = size.height - (r - engine.scroll + 1) * rowH;
      if (topY > size.height || topY + rowH < 0) continue;
      final rect = Rect.fromLTWH(row.activeColumn * laneW, topY, laneW, rowH);
      final color = Palette.laneColors[row.activeColumn % Palette.laneColors.length];
      BatikTile.paint(canvas, rect, color);
      if (row.tapped) {
        // gold "played" glow
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(laneW * 0.08), Radius.circular(laneW * 0.12)),
          Paint()..color = Palette.gold.withOpacity(0.32),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilesBoardPainter old) => old.repaint != repaint;
}

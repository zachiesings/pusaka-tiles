import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/engine/tiles_engine.dart';
import '../game/tile_themes.dart';
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
    // Hit line sits high (80% down) so the first tile appears clearly ON the
    // line with runway below — not crammed at the very bottom edge.
    final hitY = size.height * 0.80;

    // Lane backgrounds + dividers
    for (var c = 0; c < cols; c++) {
      canvas.drawRect(Rect.fromLTWH(c * laneW, 0, laneW, size.height),
          Paint()..color = c.isEven ? Palette.gridCell : Palette.panel);
    }
    final divider = Paint()..color = Palette.gridLine..strokeWidth = 1;
    for (var c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * laneW, 0), Offset(c * laneW, size.height), divider);
    }

    // Tap flash glow lighting up the struck lane's hit zone (rich particle
    // bursts/ripples are drawn by the overlaid _GameFxLayer).
    final pulse = flashLane >= 0 ? flashT.clamp(0.0, 1.0) : 0.0;
    if (flashLane >= 0 && flashT > 0) {
      final x = flashLane * laneW;
      final r = Rect.fromLTWH(x, hitY - pxPerBeat * 1.4, laneW, pxPerBeat * 1.8);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Palette.gold.withOpacity(0.55 * flashT), Palette.gold.withOpacity(0)],
          ).createShader(r),
      );
    }

    // Glowing hit line — brightens + thickens with the most recent tap (pulse).
    canvas.drawLine(Offset(0, hitY), Offset(size.width, hitY),
        Paint()
          ..color = Palette.gold.withOpacity(0.5 + 0.4 * pulse)
          ..strokeWidth = 2.5 + 5 * pulse
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 7 * pulse));
    canvas.drawLine(Offset(0, hitY), Offset(size.width, hitY),
        Paint()
          ..color = Color.lerp(Palette.goldLt, Colors.white, pulse * 0.7)!
          ..strokeWidth = 1.4 + pulse * 1.6);

    // Visible tiles (rows sorted by startBeat). A tile's bottom edge reaches the
    // hit line exactly when scroll == its startBeat.
    final start = engine.nextTap - 4 < 0 ? 0 : engine.nextTap - 4;
    for (var i = start; i < engine.rows.length; i++) {
      final t = engine.rows[i];
      final h = t.beats * pxPerBeat;
      final bottom = hitY + (engine.scroll - t.startBeat) * pxPerBeat;
      final top = bottom - h;
      if (bottom < 0) break;             // fully above the screen (so are later tiles)
      if (top > size.height) continue;   // below the visible area
      final rect = Rect.fromLTWH(t.activeColumn * laneW, top, laneW, h);
      final lane = TileTheme.active;
      final color = lane[t.activeColumn % lane.length];
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

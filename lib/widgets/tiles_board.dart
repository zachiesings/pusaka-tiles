import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/chart.dart';
import '../game/engine/tiles_engine.dart';
import '../game/tile_themes.dart';
import 'batik.dart';

/// Paints the 4-lane falling-tiles board. Tiles are positioned + sized by their
/// beat span, so longer notes are taller tiles and the song scrolls in rhythm.
class TilesBoardPainter extends CustomPainter {
  final TilesEngine engine;
  final int flashLane;
  final double flashT;
  final bool colorblind; // draw a per-lane shape so cues aren't colour-only
  final int imbalGlow; // # of upcoming tiles that form the active imbal "call"
  final double tileDim; // Bayangan modifier: tile opacity multiplier (1 = none)
  final double repaint;

  TilesBoardPainter({
    required this.engine,
    this.flashLane = -1,
    this.flashT = 0,
    this.colorblind = false,
    this.imbalGlow = 0,
    this.tileDim = 1.0,
  }) : repaint = engine.scroll + flashT + imbalGlow + tileDim;

  /// A distinct shape per lane (circle/triangle/square/diamond) drawn on a tile
  /// when the colourblind-safe setting is on — shape + lane position carry the
  /// cue without relying on colour.
  static void _laneShape(Canvas canvas, Offset c, double s, int lane, Paint p) {
    switch (lane % 4) {
      case 0:
        canvas.drawCircle(c, s * 0.5, p);
        break;
      case 1:
        final path = Path()
          ..moveTo(c.dx, c.dy - s * 0.55)
          ..lineTo(c.dx + s * 0.55, c.dy + s * 0.45)
          ..lineTo(c.dx - s * 0.55, c.dy + s * 0.45)
          ..close();
        canvas.drawPath(path, p);
        break;
      case 2:
        canvas.drawRect(Rect.fromCenter(center: c, width: s, height: s), p);
        break;
      default:
        final path = Path()
          ..moveTo(c.dx, c.dy - s * 0.6)
          ..lineTo(c.dx + s * 0.6, c.dy)
          ..lineTo(c.dx, c.dy + s * 0.6)
          ..lineTo(c.dx - s * 0.6, c.dy)
          ..close();
        canvas.drawPath(path, p);
    }
  }

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
      BatikTile.paint(canvas, rect, color, opacity: tileDim);
      // Chord: paint the second simultaneous lane so it reads (and cues the
      // optional second tap). Hold: a slim gold sustain cap down the tile.
      if (t.kind == NoteKind.chord && t.chordLane >= 0) {
        final r2 = Rect.fromLTWH(t.chordLane * laneW, top, laneW, h);
        BatikTile.paint(canvas, r2, lane[t.chordLane % lane.length], opacity: tileDim);
      } else if (t.kind == NoteKind.hold && h > pxPerBeat * 0.6) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.center.dx - laneW * 0.06, top + h * 0.12,
                  laneW * 0.12, h * 0.76),
              Radius.circular(laneW * 0.06)),
          Paint()..color = Palette.goldLt.withOpacity(0.55),
        );
      }
      // Imbal "call": ghost-glow the next few upcoming tiles the player must
      // answer, so the figure reads as a single phrase across the lanes.
      if (imbalGlow > 0 &&
          i >= engine.nextTap &&
          i < engine.nextTap + imbalGlow &&
          !t.tapped) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect.deflate(laneW * 0.04), Radius.circular(laneW * 0.14)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Palette.violet.withOpacity(0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      if (colorblind && !t.tapped) {
        final s = (laneW * 0.30).clamp(7.0, 20.0);
        final cyTop = top + s + 2; // sit just inside the tile's top edge
        final cy = cyTop < bottom ? cyTop : (top + bottom) / 2;
        _laneShape(canvas, Offset(rect.center.dx, cy), s, t.activeColumn,
            Paint()..color = Colors.white.withOpacity(0.85));
      }
      if (t.tapped) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(laneW * 0.08), Radius.circular(laneW * 0.12)),
          Paint()..color = Palette.gold.withOpacity(0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilesBoardPainter old) =>
      old.repaint != repaint ||
      old.colorblind != colorblind ||
      old.imbalGlow != imbalGlow ||
      old.tileDim != tileDim;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'mascot.dart';

/// "Si Batik" out for a stroll across the stage — the little mascot walks back
/// and forth along the bottom of a scene, bobbing as it goes, flipping to face
/// its direction, and breaking into a happy hop every so often. Pure code.
///
/// Drop into a [Stack] with `Positioned.fill`; it measures its own width.
class RoamingMascot extends StatefulWidget {
  final double size;
  final double bottom; // gap from the bottom of the band
  final double period; // seconds for one full there-and-back lap
  const RoamingMascot({
    super.key,
    this.size = 66,
    this.bottom = 6,
    this.period = 16,
  });

  @override
  State<RoamingMascot> createState() => _RoamingMascotState();
}

class _RoamingMascotState extends State<RoamingMascot> {
  Ticker? _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((d) {
      setState(() => _t = d.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 320.0;
        const margin = 14.0;
        final span = (w - widget.size - margin * 2).clamp(0.0, w);

        final p = (_t % widget.period) / widget.period; // 0..1
        final tri = p < 0.5 ? p * 2 : 2 - p * 2; // 0..1..0
        final dir = p < 0.5 ? 1.0 : -1.0; // facing
        final x = margin + tri * span;

        final bob = math.sin(_t * 7).abs() * widget.size * 0.05;

        final hop = (p > 0.46 && p < 0.54) || (p > 0.96 || p < 0.04);
        final mood = hop ? MascotMood.happy : MascotMood.idle;

        return Stack(
          children: [
            Positioned(
              left: x,
              bottom: widget.bottom + bob,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(dir, 1.0, 1.0),
                child: MascotView(size: widget.size, mood: mood),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:ui' show FontVariation;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Regal heritage display type (Cinzel) used for the wordmark, screen titles and
/// section headers. Weight is driven through the variable-font `wght` axis so a
/// single TTF gives us Regular→Black. By default it's filled with the cool
/// "Panggung Malam" brand gradient and carries a soft glow for a stage-lit feel.
class DisplayText extends StatelessWidget {
  final String text;
  final double size;
  final double weight; // 400..900 along Cinzel's wght axis
  final double letterSpacing;
  final Gradient? gradient; // null -> use solidColor
  final Color solidColor;
  final bool emboss;
  final TextAlign align;
  final int? maxLines;

  const DisplayText(
    this.text, {
    super.key,
    this.size = 34,
    this.weight = 700,
    this.letterSpacing = 1.5,
    this.gradient = Palette.brand,
    this.solidColor = Palette.gold,
    this.emboss = true,
    this.align = TextAlign.center,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Cinzel',
      fontVariations: [FontVariation('wght', weight)],
      fontSize: size,
      letterSpacing: letterSpacing,
      height: 1.08,
      color: Colors.white,
      shadows: emboss
          ? const [
              Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 3)),
              Shadow(color: Color(0x447E55C6), blurRadius: 18, offset: Offset(0, 0)),
            ]
          : null,
    );
    final child = Text(text, textAlign: align, maxLines: maxLines, style: style);
    if (gradient == null) {
      return Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        style: style.copyWith(color: solidColor),
      );
    }
    return ShaderMask(
      shaderCallback: (r) => gradient!.createShader(r),
      blendMode: BlendMode.srcIn,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'constants.dart';

/// Premium "Panggung Malam" theme — Plus Jakarta Sans + cool indigo tokens.
ThemeData buildTheme() {
  const font = 'Jakarta';
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.bg0,
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.violet,
      secondary: Palette.teal,
      surface: Palette.panel,
      onPrimary: Palette.cream,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: font,
      bodyColor: Palette.cream,
      displayColor: Palette.cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Palette.cream,
      titleTextStyle: TextStyle(
          fontFamily: font, fontWeight: FontWeight.w800, fontSize: 20, color: Palette.cream),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.violet,
        foregroundColor: Palette.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontFamily: font, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
  );
}

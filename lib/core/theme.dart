import 'package:flutter/material.dart';
import 'constants.dart';
import 'motion.dart';

/// Premium "Panggung Malam" theme — Plus Jakarta Sans body + Outfit display
/// (modern geometric face for numbers/headers; replaces the old Cinzel serif).
ThemeData buildTheme() {
  const font = 'Jakarta';
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.bg0,
    pageTransitionsTheme: panggungPageTransitionsTheme,
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.violet,
      secondary: Palette.teal,
      surface: Palette.panel,
      onPrimary: Palette.cream,
    ),
    textTheme: base.textTheme
        .apply(fontFamily: font, bodyColor: Palette.cream, displayColor: Palette.cream)
        .copyWith(
          // headlines/titles use the Outfit display face
          headlineLarge: Typo.h1.copyWith(color: Palette.cream),
          headlineMedium: Typo.h1.copyWith(color: Palette.cream, fontSize: 20),
          titleLarge: Typo.h1.copyWith(color: Palette.cream, fontSize: 18),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Palette.cream,
      titleTextStyle: TextStyle(
          fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 19,
          letterSpacing: 0.3, color: Palette.cream),
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

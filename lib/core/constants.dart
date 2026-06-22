import 'package:flutter/material.dart';

/// Global constants for Pusaka Tiles. (Mirrors the Pusaka Blast layout.)
class K {
  K._();

  // ----- Game rules -----
  static const int columns = 4;          // piano-tile lanes
  static const double startSpeed = 2.4;  // rows scrolled per second at start
  static const double speedStep = 0.06;  // speed added per correct tap
  static const double maxSpeed = 7.5;
  static const double visibleRows = 4.5; // rows shown on screen

  // ----- Ads -----
  static const bool adsEnabled = true;
  static const bool useTestAds = true;
  static const String rewardedAdUnit     = 'ca-app-pub-3940256099942544/5224354917';
  static const String interstitialAdUnit = 'ca-app-pub-3940256099942544/1033173712';
  static const String bannerAdUnit       = 'ca-app-pub-3940256099942544/6300978111';

  // ----- Persistence keys -----
  static const String kHighScore = 'pt_high_score';   // legacy global best
  static const String kSound     = 'pt_sound';
  static const String kMusic     = 'pt_music';
  static const String kInstrument = 'pt_instrument';

  /// Selectable traditional instrument voices (folder id -> display label).
  static const List<MapEntry<String, String>> instruments = [
    MapEntry('piano', 'Piano'),
    MapEntry('angklung', 'Angklung'),
    MapEntry('gamelan', 'Gamelan'),
    MapEntry('suling', 'Suling'),
  ];
  static const String kHaptics   = 'pt_haptics';
  static const String kFirstRun  = 'pt_first_run';
  static String songBestKey(String songId) => 'pt_best_$songId';
  static String songStarsKey(String songId) => 'pt_stars_$songId';
}

/// === "PANGGUNG MALAM" — cool indigo-night stage identity (distinct from Blast) ===
class Palette {
  Palette._();

  static const Color bg0      = Color(0xFF0B0918); // deep indigo-black night
  static const Color bg1      = Color(0xFF161236); // wedelan indigo
  static const Color panel    = Color(0xFF241C4E); // indigo surface
  static const Color panelHi  = Color(0xFF2E2360);
  static const Color gridCell = Color(0xFF181340); // empty lane
  static const Color gridLine = Color(0xFF332A66);

  static const Color gold     = Color(0xFFF2B73C); // prada gold ornament
  static const Color goldLt   = Color(0xFFFCD675);
  static const Color goldSoft = Color(0xFFC8923A);
  static const Color cream    = Color(0xFFF2EEFA); // cool ivory
  static const Color ink      = Color(0xFF0B0918);

  // cool accents
  static const Color indigo   = Color(0xFF5B4BC4); // wedelan
  static const Color violet   = Color(0xFF7E55C6);
  static const Color teal     = Color(0xFF2FA987); // gamelan jade
  static const Color pink     = Color(0xFFE76A93);
  static const Color cyan     = Color(0xFF45C6D4);

  static const LinearGradient brand = LinearGradient(
    colors: [violet, indigo, teal],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color c, {double blur = 26, double y = 10, double a = 0.5}) =>
      [BoxShadow(color: c.withOpacity(a), blurRadius: blur, offset: Offset(0, y))];

  // Lane / active-tile colors — cool, luminous, distinct from Blast's warm set.
  static const List<Color> laneColors = <Color>[
    Color(0xFF5B4BC4), // indigo
    Color(0xFF2FA987), // jade
    Color(0xFFE76A93), // pink
    Color(0xFF45C6D4), // cyan
  ];
}

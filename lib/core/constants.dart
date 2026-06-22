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
  static const String kHaptics   = 'pt_haptics';
  static const String kFirstRun  = 'pt_first_run';
  static String songBestKey(String songId) => 'pt_best_$songId';
  static String songStarsKey(String songId) => 'pt_stars_$songId';
}

/// Batik-inspired palette (shared with Pusaka Blast for brand consistency).
class Palette {
  Palette._();

  static const Color bg0      = Color(0xFF15110A);
  static const Color bg1      = Color(0xFF241B10);
  static const Color panel    = Color(0xFF2E2316);
  static const Color gridCell = Color(0xFF3A2D1C);
  static const Color gridLine = Color(0xFF4A3A24);

  static const Color gold     = Color(0xFFE3B23C);
  static const Color goldSoft = Color(0xFFC8923A);
  static const Color cream    = Color(0xFFF3E5C8);
  static const Color ink      = Color(0xFF1B130A);

  // Lane / active-tile colors (batik tones), one per lane for variety.
  static const List<Color> laneColors = <Color>[
    Color(0xFF7A3B2E),
    Color(0xFF1F4E5F),
    Color(0xFFB5832E),
    Color(0xFF4A6B3A),
  ];
}

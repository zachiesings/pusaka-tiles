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
  static const bool useTestAds = false; // REAL ads (production)
  static const bool adDebug = false; // diagnostic status text OFF for submission
  static const bool interstitialEnabled = false; // Rewarded-only per design
  static const String rewardedAdUnit     = 'ca-app-pub-1298950542115439/6115007852';
  static const String interstitialAdUnit = ''; // disabled (interstitialEnabled=false)
  static const String bannerAdUnit       = '';

  // ----- Persistence keys -----
  static const String kHighScore = 'pt_high_score';   // legacy global best
  static const String kSound     = 'pt_sound';
  static const String kMusic     = 'pt_music';
  static const String kInstrument = 'pt_instrument';
  static const String kBestCombo  = 'pt_best_combo';
  static const String kCoins      = 'pt_coins';
  static const String kThemes     = 'pt_themes';
  static const String kTheme      = 'pt_theme';

  /// Selectable traditional instrument voices (folder id -> display label).
  static const List<MapEntry<String, String>> instruments = [
    MapEntry('piano', 'Piano'),
    MapEntry('angklung', 'Angklung'),
    MapEntry('gamelan', 'Gamelan'),
    MapEntry('suling', 'Suling'),
  ];
  static const String kHaptics   = 'pt_haptics';
  static const String kInGameMusic = 'pt_ingame_music'; // off | pad | groove

  /// In-game accompaniment options ("Musik saat bermain"), separate from the
  /// home BGM. Default = pad (subtle ambient drone).
  static const List<MapEntry<String, String>> inGameMusicOptions = [
    MapEntry('off', 'Mati'),
    MapEntry('pad', 'Pad lembut'),
    MapEntry('groove', 'Groove halus'),
  ];
  static const String kFirstRun  = 'pt_first_run';
  // ----- Campaign ("Perjalanan Nusantara") -----
  static const String kCampaignUnlocked = 'pt_campaign_unlocked'; // highest stage unlocked (1..20)
  static const String kStageStars = 'pt_stage_stars'; // CSV of 20 star counts (0..3)
  static const String kGames     = 'pt_games_played';
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

/// Single source of truth for typography — Outfit (geometric display) for
/// numbers/combo/headlines, Plus Jakarta Sans for body. Use `.copyWith(color:)`
/// at the call site. Replaces the old Cinzel display face.
class Typo {
  Typo._();
  static const String display = 'Outfit';
  static const String body = 'Jakarta';

  static const TextStyle score =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 52, height: 1.0, letterSpacing: -1.5);
  static const TextStyle combo =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.5);
  static const TextStyle judge =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 42, letterSpacing: 1.0, height: 1.0);
  static const TextStyle fever =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 64, letterSpacing: 2, height: 1.0);
  static const TextStyle h1 =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: 0.2);
  static const TextStyle title =
      TextStyle(fontFamily: body, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2);
  static const TextStyle label =
      TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 12);
  static const TextStyle small =
      TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 10.5, letterSpacing: 0.4);
  static const TextStyle chip =
      TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 13);
}

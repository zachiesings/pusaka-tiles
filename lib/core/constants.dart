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

  // ----- Note scroll-speed preference (multiplies the mode's tempo) -----
  // A higher value = tiles fall faster / song plays quicker. Persisted, applied
  // to every run. Default 1.0 (= the original tuned feel). Range clamped 0.7–1.5.
  static const double scrollSpeedMin = 0.7;
  static const double scrollSpeedMax = 1.5;
  static const double scrollSpeedDefault = 1.0;
  static const List<MapEntry<double, String>> scrollSpeedPresets = [
    MapEntry(0.8, 'Santai'),
    MapEntry(1.0, 'Normal'),
    MapEntry(1.2, 'Cepat'),
    MapEntry(1.4, 'Kilat'),
  ];

  // ----- Calibration offsets (milliseconds, per device) -----
  // touchOffset compensates display+input lag (when you SEE the tile hit the
  // line vs when the tap registers); audioOffset compensates audio output lag
  // (when you HEAR the note). Both are added into the timing judged each tap, so
  // a correctly-calibrated device scores a dead-centre tap as Perfect. Clamped.
  static const double offsetMinMs = -200;
  static const double offsetMaxMs = 200;

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
  // ----- Accessibility & the awakening ensemble -----
  static const String kReduceMotion = 'pt_reduce_motion'; // bool, degrade juice
  static const String kColorblind   = 'pt_colorblind';    // bool, shape/position lane cues
  static const String kEnsemble     = 'pt_ensemble';      // bool, "Ensemble Awakens" layering
  static const String kImbal        = 'pt_imbal';         // bool, call-and-response moments
  static const String kMotifs       = 'pt_motifs';        // CSV of unlocked motif (song) ids
  static const String kMotifEquip   = 'pt_motif_equipped'; // equipped motif's song id ('' = none)
  static const String kScrollSpeed   = 'pt_scroll_speed';    // double, tempo multiplier
  static const String kAudioOffsetMs = 'pt_audio_offset_ms'; // double, ms
  static const String kTouchOffsetMs = 'pt_touch_offset_ms'; // double, ms

  // ----- Progression / mastery / missions / daily (Waves T2–T4) -----
  static const String kXp            = 'pt_xp';            // int, lifetime XP
  static const String kMissionDay    = 'pt_mission_day';   // int yyyymmdd
  static const String kMissionProg   = 'pt_mission_prog';  // CSV of 3 ints
  static const String kMissionClaim  = 'pt_mission_claim'; // CSV of 3 0/1
  static const String kDailyDay      = 'pt_daily_day';     // int yyyymmdd last played
  static const String kDailyBest     = 'pt_daily_best';    // int best score today
  static const String kDailyStreak   = 'pt_daily_streak';  // int consecutive days
  static String songMasteryKey(String songId) => 'pt_mastery_$songId';

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

/// Timing-judgment windows, in BEATS (they scale naturally with tempo: the same
/// window is a tighter time-slice at higher speed). Single source of truth for
/// how the game "feels" — tune here. `err` is |scroll − tile.startBeat| AFTER the
/// device offset is applied, i.e. how far the tap landed from the tile reaching
/// the hit line. Ordered tiers; a tap earlier than `bad` simply whiffs (the tile
/// is not consumed) instead of registering, so you can't pre-tap a whole song.
class Judge {
  Judge._();
  static const double perfect = 0.16; // dead-centre
  static const double great   = 0.30;
  static const double good    = 0.50;
  static const double bad     = 0.80; // outer hittable bound (both sides)

  // Tier ids (also the engine's success "judge" code).
  static const int kMiss    = 0; // tile passed untapped (run ends)
  static const int kBad     = 1;
  static const int kGood    = 2;
  static const int kGreat   = 3;
  static const int kPerfect = 4;

  /// Map an absolute timing error (beats) to a hit tier (Bad..Perfect).
  static int tier(double absErr) {
    if (absErr <= perfect) return kPerfect;
    if (absErr <= great) return kGreat;
    if (absErr <= good) return kGood;
    return kBad;
  }

  static const Map<int, String> label = {
    kMiss: 'MISS',
    kBad: 'BAD',
    kGood: 'GOOD',
    kGreat: 'GREAT',
    kPerfect: 'PERFECT',
  };

  /// Base points per tier (before Fever multiplier).
  static const Map<int, int> points = {
    kBad: 10,
    kGood: 30,
    kGreat: 60,
    kPerfect: 100,
  };
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

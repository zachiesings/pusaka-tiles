import 'chart.dart';

/// Player XP + level curve, and per-song mastery. All pure functions so the
/// maths is unit-testable without a device.
class Progression {
  Progression._();

  /// XP needed to advance FROM [level] to [level]+1 (level is 1-based).
  static int xpForNext(int level) => 100 + (level - 1) * 50;

  /// Cumulative XP required to first reach [level] (level 1 == 0).
  static int totalXpForLevel(int level) {
    var sum = 0;
    for (var l = 1; l < level; l++) {
      sum += xpForNext(l);
    }
    return sum;
  }

  /// The level a player with [xp] total XP has reached (>= 1).
  static int levelForXp(int xp) {
    var level = 1;
    var rem = xp;
    while (rem >= xpForNext(level)) {
      rem -= xpForNext(level);
      level++;
    }
    return level;
  }

  /// XP accumulated INTO the current level (0 .. xpForNext(level)-1).
  static int xpIntoLevel(int xp) {
    var level = 1;
    var rem = xp;
    while (rem >= xpForNext(level)) {
      rem -= xpForNext(level);
      level++;
    }
    return rem;
  }

  static const Map<Difficulty, double> _xpDiffMul = {
    Difficulty.mudah: 1.0,
    Difficulty.normal: 1.2,
    Difficulty.sulit: 1.5,
    Difficulty.master: 2.0,
  };

  /// XP awarded for a finished run. Rewards volume (score), precision
  /// (accuracy), difficulty, and clean clears.
  static int runXp({
    required int points,
    required double accuracy,
    required Difficulty difficulty,
    required bool fullCombo,
    required bool allPerfect,
  }) {
    var xp = (points / 20).round();
    xp = (xp * (_xpDiffMul[difficulty] ?? 1.0)).round();
    xp += (accuracy.clamp(0.0, 1.0) * 30).round();
    if (fullCombo) xp += 50;
    if (allPerfect) xp += 100;
    return xp < 1 ? 1 : xp;
  }
}

/// Per-song mastery — a points pool that climbs as you clear a song better and
/// on harder tiers, surfacing a rank the player can chase per heirloom song.
enum MasteryTier { pemula, perunggu, perak, emas, pusaka }

class Mastery {
  Mastery._();

  static const List<String> tierLabel = [
    'Pemula',
    'Perunggu',
    'Perak',
    'Emas',
    'Pusaka',
  ];

  /// Mastery points needed to be AT each tier (index == MasteryTier.index).
  static const List<int> thresholds = [0, 100, 300, 700, 1500];

  static MasteryTier tierFor(int points) {
    var t = MasteryTier.pemula;
    for (var i = 0; i < thresholds.length; i++) {
      if (points >= thresholds[i]) t = MasteryTier.values[i];
    }
    return t;
  }

  /// Points to the NEXT tier (0 once Pusaka is reached).
  static int toNextTier(int points) {
    for (final th in thresholds) {
      if (points < th) return th - points;
    }
    return 0;
  }

  static const Map<Difficulty, int> _diffMul = {
    Difficulty.mudah: 1,
    Difficulty.normal: 2,
    Difficulty.sulit: 3,
    Difficulty.master: 4,
  };

  static const Map<String, int> _gradePts = {
    'F': 1,
    'D': 2,
    'C': 4,
    'B': 6,
    'A': 8,
    'S': 12,
    'SS': 16,
    'SSS': 20,
  };

  /// Mastery points earned by one clear of a song.
  static int runPoints({
    required Difficulty difficulty,
    required String grade,
    required bool fullCombo,
  }) {
    final mul = _diffMul[difficulty] ?? 1;
    final g = _gradePts[grade] ?? 1;
    var p = mul * g;
    if (fullCombo) p += 5;
    return p;
  }
}

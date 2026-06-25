import 'dart:math';
import 'chart.dart';

/// What a single finished run contributes toward missions.
class RunStats {
  final int score;
  final int perfects;
  final int bestCombo;
  final bool fullCombo;
  final bool cleared;       // finite run reached the end
  final int difficultyIndex; // Difficulty.index of the run
  const RunStats({
    required this.score,
    required this.perfects,
    required this.bestCombo,
    required this.fullCombo,
    required this.cleared,
    required this.difficultyIndex,
  });
}

enum MissionKind { play, score, perfects, fullCombo, reachCombo, clearSulit }

/// A daily objective. Progress is normally a running sum; [reachCombo] tracks a
/// max instead. Pure logic — [advance] computes the new progress from a run.
class Mission {
  final MissionKind kind;
  final int target;
  final int rewardCoins;
  final int rewardXp;
  const Mission(this.kind, this.target, this.rewardCoins, this.rewardXp);

  bool get isMax => kind == MissionKind.reachCombo;

  String get label {
    switch (kind) {
      case MissionKind.play:
        return 'Main $target lagu';
      case MissionKind.score:
        return 'Kumpulkan $target skor';
      case MissionKind.perfects:
        return 'Dapatkan $target PERFECT';
      case MissionKind.fullCombo:
        return 'Raih Full Combo';
      case MissionKind.reachCombo:
        return 'Capai combo $target';
      case MissionKind.clearSulit:
        return 'Tamatkan lagu di Sulit+';
    }
  }

  /// New progress value after [s], given the previous [prev].
  int advance(int prev, RunStats s) {
    switch (kind) {
      case MissionKind.play:
        return prev + 1;
      case MissionKind.score:
        return prev + s.score;
      case MissionKind.perfects:
        return prev + s.perfects;
      case MissionKind.fullCombo:
        return prev + (s.fullCombo ? 1 : 0);
      case MissionKind.reachCombo:
        return s.bestCombo > prev ? s.bestCombo : prev;
      case MissionKind.clearSulit:
        return prev +
            ((s.cleared && s.difficultyIndex >= Difficulty.sulit.index) ? 1 : 0);
    }
  }

  bool done(int progress) => progress >= target;

  /// A stable id so persisted progress survives across a session.
  String get id => '${kind.index}:$target';
}

/// Rolls the day's 3 missions deterministically from the date — same calendar
/// day yields the same set for everyone, and a new day rotates them.
class MissionCatalog {
  MissionCatalog._();

  static List<Mission> daily(int year, int month, int day) {
    final rng = Random(stableHash('missions-$year-$month-$day'));
    final templates = <Mission>[
      const Mission(MissionKind.play, 3, 30, 40),
      const Mission(MissionKind.score, 1500, 40, 60),
      const Mission(MissionKind.perfects, 40, 40, 60),
      const Mission(MissionKind.fullCombo, 1, 60, 80),
      const Mission(MissionKind.reachCombo, 30, 40, 50),
      const Mission(MissionKind.clearSulit, 1, 60, 90),
    ];
    final chosen = <int>[];
    while (chosen.length < 3 && chosen.length < templates.length) {
      final j = rng.nextInt(templates.length);
      if (!chosen.contains(j)) chosen.add(j);
    }
    return [for (final j in chosen) templates[j]];
  }
}

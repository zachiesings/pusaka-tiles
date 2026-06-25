import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/chart.dart';
import 'package:pusaka_tiles/game/missions.dart';

RunStats stats({
  int score = 0,
  int perfects = 0,
  int bestCombo = 0,
  bool fullCombo = false,
  bool cleared = false,
  int difficultyIndex = 0,
}) =>
    RunStats(
      score: score,
      perfects: perfects,
      bestCombo: bestCombo,
      fullCombo: fullCombo,
      cleared: cleared,
      difficultyIndex: difficultyIndex,
    );

void main() {
  group('Mission.advance', () {
    test('play counts runs', () {
      const m = Mission(MissionKind.play, 3, 0, 0);
      expect(m.advance(0, stats()), 1);
      expect(m.advance(2, stats()), 3);
      expect(m.done(3), true);
    });

    test('score and perfects accumulate', () {
      const s = Mission(MissionKind.score, 1000, 0, 0);
      expect(s.advance(200, stats(score: 500)), 700);
      const p = Mission(MissionKind.perfects, 40, 0, 0);
      expect(p.advance(10, stats(perfects: 12)), 22);
    });

    test('reachCombo tracks a maximum, not a sum', () {
      const c = Mission(MissionKind.reachCombo, 30, 0, 0);
      expect(c.advance(40, stats(bestCombo: 20)), 40); // keeps the higher
      expect(c.advance(10, stats(bestCombo: 25)), 25);
      expect(c.isMax, true);
    });

    test('clearSulit only counts cleared runs at Sulit or harder', () {
      const m = Mission(MissionKind.clearSulit, 1, 0, 0);
      expect(
          m.advance(0,
              stats(cleared: true, difficultyIndex: Difficulty.sulit.index)),
          1);
      expect(
          m.advance(0,
              stats(cleared: true, difficultyIndex: Difficulty.master.index)),
          1);
      expect(
          m.advance(0,
              stats(cleared: true, difficultyIndex: Difficulty.normal.index)),
          0);
      expect(
          m.advance(0,
              stats(cleared: false, difficultyIndex: Difficulty.master.index)),
          0);
    });
  });

  group('MissionCatalog daily', () {
    test('rolls exactly 3 and is deterministic per day', () {
      List<String> sig(List<Mission> ms) =>
          [for (final m in ms) '${m.kind.index}:${m.target}'];
      final a = MissionCatalog.daily(2026, 6, 25);
      final b = MissionCatalog.daily(2026, 6, 25);
      expect(a.length, 3);
      expect(sig(a), sig(b));
    });
  });
}

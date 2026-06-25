import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/chart.dart';
import 'package:pusaka_tiles/game/progression.dart';

void main() {
  group('Progression XP + levels', () {
    test('level starts at 1 and crosses on the exact threshold', () {
      expect(Progression.levelForXp(0), 1);
      expect(Progression.levelForXp(99), 1);
      expect(Progression.levelForXp(100), 2); // xpForNext(1) == 100
    });

    test('totalXpForLevel is the cumulative curve', () {
      expect(Progression.totalXpForLevel(1), 0);
      expect(Progression.totalXpForLevel(2), Progression.xpForNext(1));
      expect(Progression.totalXpForLevel(3),
          Progression.xpForNext(1) + Progression.xpForNext(2));
    });

    test('xpIntoLevel is the remainder within the current level', () {
      expect(Progression.xpIntoLevel(100), 0);
      expect(Progression.xpIntoLevel(150), 50);
    });

    test('runXp rewards difficulty + clean clears, and is always >= 1', () {
      final base = Progression.runXp(
          points: 1000,
          accuracy: 0.9,
          difficulty: Difficulty.mudah,
          fullCombo: false,
          allPerfect: false);
      final hard = Progression.runXp(
          points: 1000,
          accuracy: 0.9,
          difficulty: Difficulty.master,
          fullCombo: false,
          allPerfect: false);
      expect(hard, greaterThan(base));
      final clean = Progression.runXp(
          points: 1000,
          accuracy: 0.9,
          difficulty: Difficulty.master,
          fullCombo: true,
          allPerfect: true);
      expect(clean, greaterThan(hard));
      expect(
          Progression.runXp(
              points: 0,
              accuracy: 0,
              difficulty: Difficulty.mudah,
              fullCombo: false,
              allPerfect: false),
          greaterThanOrEqualTo(1));
    });
  });

  group('Mastery tiers', () {
    test('tier boundaries', () {
      expect(Mastery.tierFor(0), MasteryTier.pemula);
      expect(Mastery.tierFor(99), MasteryTier.pemula);
      expect(Mastery.tierFor(100), MasteryTier.perunggu);
      expect(Mastery.tierFor(300), MasteryTier.perak);
      expect(Mastery.tierFor(700), MasteryTier.emas);
      expect(Mastery.tierFor(1500), MasteryTier.pusaka);
      expect(Mastery.tierFor(999999), MasteryTier.pusaka);
    });

    test('toNextTier counts down and zeroes at the top', () {
      expect(Mastery.toNextTier(0), 100);
      expect(Mastery.toNextTier(250), 50);
      expect(Mastery.toNextTier(1500), 0);
    });

    test('runPoints scale with difficulty + grade + full combo', () {
      final low = Mastery.runPoints(
          difficulty: Difficulty.mudah, grade: 'F', fullCombo: false);
      final high = Mastery.runPoints(
          difficulty: Difficulty.master, grade: 'SSS', fullCombo: true);
      expect(high, greaterThan(low));
    });
  });
}

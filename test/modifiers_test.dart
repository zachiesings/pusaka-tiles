import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/modifiers.dart';
import 'package:pusaka_tiles/game/ensemble.dart';

void main() {
  group('modifiers', () {
    test('Tempo Naik strengthens the speed ramp; others do not', () {
      expect(modifierSpeedStepMul(<SongModifier>{}), 1.0);
      expect(modifierSpeedStepMul({SongModifier.gongGanda}), 1.0);
      expect(modifierSpeedStepMul({SongModifier.bayangan}), 1.0);
      expect(modifierSpeedStepMul({SongModifier.tempoNaik}), greaterThan(1.0));
      expect(
          modifierSpeedStepMul({SongModifier.tempoNaik, SongModifier.bayangan}),
          greaterThan(1.0));
    });

    test('Bayangan dims tiles only in a bounded window, never to zero', () {
      expect(bayanganTileOpacity(0.0), 1.0); // bright on the downbeat
      expect(bayanganTileOpacity(0.3), 1.0);
      expect(bayanganTileOpacity(0.6), lessThan(1.0)); // dim window
      expect(bayanganTileOpacity(0.6), greaterThanOrEqualTo(0.45));
      expect(bayanganTileOpacity(0.9), 1.0); // bright again
      expect(bayanganTileOpacity(1.6), bayanganTileOpacity(0.6)); // phase wraps
      expect(bayanganTileOpacity(double.nan), 1.0); // safe
    });

    test('Gong Ganda adds a mid-cycle gong accent in the ensemble', () {
      List<ColotomicHit> advance(EnsembleDirector d, double from, double to) {
        final hits = <ColotomicHit>[];
        var s = from;
        while (s < to - 1e-9) {
          s += 0.1;
          hits.addAll(d.tick(s, 0.1));
        }
        return hits;
      }

      final plain = EnsembleDirector(
          config: const EnsembleConfig(gonganBeats: 16, crossfadeBeats: 1));
      final ganda = EnsembleDirector(
          config: const EnsembleConfig(
              gonganBeats: 16, crossfadeBeats: 1, gongGanda: true));
      for (final d in [plain, ganda]) {
        d.onCombo(20); // wake colotomic
        advance(d, 0, 18);
      }
      // Over one cycle, count gong hits. Gong Ganda adds one at the mid-cycle.
      final plainGongs = advance(plain, 31, 47).where((h) => h.voice == 'gong').length;
      final gandaGongs = advance(ganda, 31, 47).where((h) => h.voice == 'gong').length;
      expect(gandaGongs, greaterThan(plainGongs));
    });
  });
}

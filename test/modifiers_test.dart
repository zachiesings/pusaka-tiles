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
      int gongsPerCycle(bool ganda) {
        final d = EnsembleDirector(
            config: EnsembleConfig(
                gonganTaps: 16, crossfadeBeats: 1, gongGanda: ganda));
        d.onCombo(20); // wake colotomic
        d.onTap(8); // apply the wake on the gong tap
        var s = 0.0;
        for (var i = 0; i < 20; i++) {
          s += 0.5;
          d.tick(s, 0.5); // ramp the gain up
        }
        var gongs = 0;
        for (var i = 0; i < 16; i++) {
          for (final h in d.onTap(8)) {
            if (h.voice == 'gong') gongs++;
          }
        }
        return gongs;
      }

      // Plain = one gong (cycle downbeat); Gong Ganda = a second at mid-cycle.
      expect(gongsPerCycle(true), greaterThan(gongsPerCycle(false)));
    });
  });
}

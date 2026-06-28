import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/ensemble.dart';

void main() {
  EnsembleDirector dir({double gongan = 16}) => EnsembleDirector(
      config: EnsembleConfig(gonganBeats: gongan, crossfadeBeats: 1));

  // Advance scroll from->to in small steps, returning every colotomic hit seen.
  // dt == step makes the internal crossfade ramp by step/crossfadeBeats per tick,
  // so advancing scroll by one crossfadeBeats fully completes a wake/sleep.
  List<ColotomicHit> advance(EnsembleDirector d, double from, double to,
      {double step = 0.1}) {
    final hits = <ColotomicHit>[];
    var s = from;
    while (s < to - 1e-9) {
      s += step;
      hits.addAll(d.tick(s, step));
    }
    return hits;
  }

  group('EnsembleDirector', () {
    test('starts lead-only — nothing awake', () {
      final d = dir();
      expect(d.targetLevel, 1);
      expect(d.activeLayers, 0);
      expect(d.fullness, 0);
      expect(d.isAwake(EnsembleLayer.bonang), false);
      expect(d.onTap(3), isNull); // no shimmer while bonang sleeps
    });

    test('reaching a threshold targets a layer but waits for the next gong', () {
      final d = dir();
      d.onCombo(8);
      expect(d.targetLevel, 2);
      advance(d, 0, 15.5); // not yet across the first gong (at beat 16)
      expect(d.isAwake(EnsembleLayer.bonang), false);
    });

    test('bonang wakes on the gong and rings a consonant octave companion', () {
      final d = dir();
      d.onCombo(8);
      advance(d, 0, 18); // cross gong at 16, then ramp over 1 beat
      expect(d.isAwake(EnsembleLayer.bonang), true);
      expect(d.activeLayers, 1);
      final comp = d.onTap(3); // lead = do (index 3)
      expect(comp, isNotNull);
      expect(comp!.note, 10); // 3 + 7 = one octave up, always consonant
      expect(comp.voice, 'gamelan');
      expect(comp.gain, greaterThan(0));
    });

    test('companion never exceeds the note table (clamps to the lead octave)', () {
      final d = dir();
      d.onCombo(8);
      advance(d, 0, 18);
      final comp = d.onTap(9); // 9 + 7 = 16 > 12 → fall back to the lead note
      expect(comp!.note, 9);
    });

    test('a combo break sleeps the most-recently-woken layer', () {
      final d = dir();
      d.onCombo(20); // target colotomic (level 3)
      advance(d, 0, 18);
      expect(d.targetLevel, 3);
      expect(d.activeLayers, 2);
      d.onBreak();
      expect(d.targetLevel, 2);
      advance(d, 18, 20); // ramp the dropped layer down
      expect(d.activeLayers, 1);
    });

    test('the +taps grace re-wakes a dropped layer without re-reaching threshold', () {
      final d = dir();
      d.onCombo(8);
      advance(d, 0, 18);
      d.onBreak();
      expect(d.targetLevel, 1);
      // restoreTaps (default 6) clean taps re-arm the dropped layer.
      for (var i = 0; i < 6; i++) {
        d.onTap(3);
      }
      expect(d.targetLevel, 2);
    });

    test('colotomic punctuation fires gong/kenong/kempul on a full cycle', () {
      final d = dir();
      d.onCombo(20); // wake through the colotomic layer
      advance(d, 0, 18); // both layers up
      final hits = advance(d, 31, 47); // one full 16-beat gong cycle, awake
      final voices = hits.map((h) => h.voice).toSet();
      expect(voices.contains('gong'), true); // gong ageng on the downbeat (32)
      expect(voices.contains('kenong'), true); // quarter points
      expect(voices.contains('kempul'), true); // offbeats
    });

    test('kendang drive only joins at the full stack', () {
      final d = dir();
      d.onCombo(20); // level 3 — colotomic, no kendang yet
      advance(d, 0, 18);
      var hits = advance(d, 18, 34);
      expect(hits.any((h) => h.voice == 'kendang'), false);
      d.onCombo(35); // level 4 — full stack
      advance(d, 34, 52); // wake kendang on the next gong (at 48)
      hits = advance(d, 52, 60);
      expect(hits.any((h) => h.voice == 'kendang'), true);
      expect(d.fullness, greaterThan(0.9));
    });

    test('nextSleeping points at the next instrument to earn', () {
      final d = dir();
      expect(d.nextSleeping, EnsembleLayer.bonang);
      expect(d.comboFor(EnsembleLayer.bonang), 8);
      d.onCombo(8);
      expect(d.nextSleeping, EnsembleLayer.colotomic);
    });

    test('reset returns to a fresh lead-only run', () {
      final d = dir();
      d.onCombo(35);
      advance(d, 0, 60);
      expect(d.activeLayers, greaterThan(0));
      d.reset();
      expect(d.targetLevel, 1);
      expect(d.activeLayers, 0);
      expect(d.fullness, 0);
    });
  });
}

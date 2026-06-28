import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/ensemble.dart';

void main() {
  EnsembleDirector dir({int gongTaps = 16}) => EnsembleDirector(
      config: EnsembleConfig(gonganTaps: gongTaps, crossfadeBeats: 1));

  // Tap n times, collecting every voice the ensemble emits.
  List<ColotomicHit> taps(EnsembleDirector d, int n, {int lead = 8}) {
    final out = <ColotomicHit>[];
    for (var i = 0; i < n; i++) {
      out.addAll(d.onTap(lead));
    }
    return out;
  }

  // Advance scroll so wake/sleep crossfades complete (audio is tap-driven, but
  // the gain ramp is time-driven via tick).
  var _scroll = 0.0;
  void ramp(EnsembleDirector d) {
    for (var i = 0; i < 20; i++) {
      _scroll += 0.5;
      d.tick(_scroll, 0.5);
    }
  }

  setUp(() => _scroll = 0.0);

  group('EnsembleDirector (tap-locked)', () {
    test('starts lead-only — a tap sounds nothing extra', () {
      final d = dir();
      expect(d.targetLevel, 1);
      expect(d.activeLayers, 0);
      expect(d.onTap(5), isEmpty);
    });

    test('bonang wakes on the gong tap and doubles the lead an octave up', () {
      final d = dir();
      d.onCombo(8); // target bonang
      d.onTap(5); // tap at cycle position 0 applies the pending wake goal
      ramp(d); // crossfade the gain up
      expect(d.isAwake(EnsembleLayer.bonang), true);
      final hits = d.onTap(3); // lead = do (3)
      expect(hits.any((h) => h.note == 10), true); // 3 + 7 = octave up, consonant
    });

    test('companion clamps into the note table (never out of range)', () {
      final d = dir();
      d.onCombo(8);
      d.onTap(9);
      ramp(d);
      final hits = d.onTap(9); // 9 + 7 = 16 > 12 → falls back to the lead note
      expect(hits.any((h) => h.note == 9), true);
      expect(hits.every((h) => h.note <= 12), true);
    });

    test('colotomic doubles the lead and punctuates across one gong cycle', () {
      final d = dir();
      d.onCombo(20); // wake through colotomic
      d.onTap(8);
      ramp(d);
      final hits = taps(d, 17, lead: 8); // a full 16-tap cycle, awake
      final voices = hits.map((h) => h.voice).toSet();
      expect(voices.contains('gong'), true); // cycle downbeat
      expect(voices.contains('kenong'), true); // quarter points
      expect(voices.contains('kempul'), true); // offbeats
      // Pitched colotomic never exceeds the table (octave-shifted lead).
      expect(hits.where((h) => h.note >= 0).every((h) => h.note <= 12), true);
    });

    test('kendang drive only joins at the full stack', () {
      final d = dir();
      d.onCombo(20); // level 3 — colotomic, no kendang
      d.onTap(8);
      ramp(d);
      expect(taps(d, 17).any((h) => h.voice == 'kendang'), false);
      d.onCombo(35); // level 4 — full stack
      d.onTap(8); // wake on the next gong tap
      ramp(d);
      expect(taps(d, 17).any((h) => h.voice == 'kendang'), true);
      expect(d.fullness, greaterThan(0.9));
    });

    test('a combo break sleeps the most-recently-woken layer', () {
      final d = dir();
      d.onCombo(20);
      d.onTap(8);
      ramp(d);
      expect(d.activeLayers, 2);
      d.onBreak();
      expect(d.targetLevel, 2);
      ramp(d);
      expect(d.activeLayers, 1);
    });

    test('the +taps grace re-wakes a dropped layer', () {
      final d = dir();
      d.onCombo(8);
      d.onTap(5);
      ramp(d);
      d.onBreak();
      expect(d.targetLevel, 1);
      for (var i = 0; i < 6; i++) {
        d.onTap(5); // restoreTaps clean taps
      }
      expect(d.targetLevel, 2);
    });

    test('nextSleeping points at the next instrument to earn', () {
      final d = dir();
      expect(d.nextSleeping, EnsembleLayer.bonang);
      expect(d.comboFor(EnsembleLayer.bonang), 8);
      d.onCombo(8);
      expect(d.nextSleeping, EnsembleLayer.colotomic);
    });

    test('gong phase + breath track the scroll position (for the visual)', () {
      final d = dir();
      for (var i = 0; i < 80; i++) {
        d.tick((i + 1) * 0.1, 0.1); // advance to scroll 8 (mid 16-beat cycle)
      }
      expect(d.gongPhase, closeTo(0.5, 0.05));
      expect(d.gongBreath, greaterThan(0.9));
    });

    test('reset returns to a fresh lead-only run', () {
      final d = dir();
      d.onCombo(35);
      d.onTap(8);
      ramp(d);
      expect(d.activeLayers, greaterThan(0));
      d.reset();
      expect(d.targetLevel, 1);
      expect(d.activeLayers, 0);
      expect(d.onTap(5), isEmpty);
    });
  });
}

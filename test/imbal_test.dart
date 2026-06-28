import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/imbal.dart';

void main() {
  List<int> pitches(int n) => List<int>.generate(n, (i) => 3 + (i % 5));

  group('ImbalManager', () {
    test('starts inactive and never arms on the opening cycle', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 4));
      expect(m.active, false);
      expect(m.maybeArm(0, pitches(8)), isNull);
    });

    test('arms a call of the configured length and pre-echoes its pitches', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 4));
      final call = m.maybeArm(1, pitches(8));
      expect(call, isNotNull);
      expect(call!.length, 4);
      expect(m.active, true);
      expect(m.total, 4);
      // already active → no re-arm
      expect(m.maybeArm(1, pitches(8)), isNull);
    });

    test('will not arm without enough runway', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 6));
      expect(m.maybeArm(1, pitches(4)), isNull);
      expect(m.active, false);
    });

    test('frequency follows the mode (everyGongans)', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 2, callLength: 4));
      expect(m.maybeArm(1, pitches(8)), isNull); // odd cycle
      final call = m.maybeArm(2, pitches(8));
      expect(call, isNotNull);
    });

    test('a fully clean answer succeeds and ends the lesson', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 3));
      expect(m.teaching, true);
      m.maybeArm(1, pitches(8));
      expect(m.onAnswer(clean: true), isNull); // 1/3
      expect(m.progress, closeTo(1 / 3, 1e-9));
      expect(m.onAnswer(clean: true), isNull); // 2/3
      final r = m.onAnswer(clean: true); // 3/3
      expect(r, isNotNull);
      expect(r!.success, true);
      expect(r.clean, 3);
      expect(m.active, false);
      expect(m.teaching, false); // first imbal taught
    });

    test('one sloppy answer fails the figure (but no exception/punishment)', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 3));
      m.maybeArm(1, pitches(8));
      m.onAnswer(clean: true);
      m.onAnswer(clean: false); // a Bad-timed tile in the figure
      final r = m.onAnswer(clean: true);
      expect(r!.success, false);
      expect(r.clean, 2);
      expect(m.teaching, true); // not taught until a clean one lands
    });

    test('a fresh call can arm on the next eligible cycle after one closes', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 2));
      m.maybeArm(1, pitches(8));
      m.onAnswer(clean: true);
      m.onAnswer(clean: true); // closes
      expect(m.active, false);
      final call = m.maybeArm(2, pitches(8));
      expect(call, isNotNull);
    });

    test('cancel abandons an active call', () {
      final m = ImbalManager(config: const ImbalConfig(everyGongans: 1, callLength: 4));
      m.maybeArm(1, pitches(8));
      m.cancel();
      expect(m.active, false);
      expect(m.onAnswer(clean: true), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/chart.dart';
import 'package:pusaka_tiles/game/songs.dart';

void main() {
  final song = SongCatalog.all.first; // gundul — long, varied, has 2-beat notes
  int nonTap(Chart c) => c.notes.where((n) => n.kind != NoteKind.tap).length;

  group('ChartGenerator onset alignment (locked to the melody)', () {
    test('every note onset == cumulative cycled beat duration', () {
      final c = ChartGenerator.generate(song, Difficulty.master, seed: 3);
      expect(c.length, song.notes.length);
      var expected = 0.0;
      for (var i = 0; i < c.notes.length; i++) {
        final dur = song.beats[i % song.beats.length].toDouble();
        expect(c.notes[i].beat, closeTo(expected, 1e-9),
            reason: 'note $i onset must match the melody');
        expect(c.notes[i].dur, closeTo(dur, 1e-9));
        expect(c.notes[i].pitch, song.notes[i]); // pitch preserved
        expected += dur;
      }
      expect(c.totalBeats, closeTo(expected, 1e-9));
    });
  });

  group('Difficulty scaling', () {
    test('Mudah is taps-only; Master adds vocabulary', () {
      expect(nonTap(ChartGenerator.generate(song, Difficulty.mudah, seed: 1)), 0);
      expect(nonTap(ChartGenerator.generate(song, Difficulty.master, seed: 1)),
          greaterThan(0));
    });

    test('tempo multiplier increases with difficulty', () {
      expect(kDifficulty[Difficulty.mudah]!.speedMul,
          lessThan(kDifficulty[Difficulty.normal]!.speedMul));
      expect(kDifficulty[Difficulty.normal]!.speedMul,
          lessThan(kDifficulty[Difficulty.sulit]!.speedMul));
      expect(kDifficulty[Difficulty.sulit]!.speedMul,
          lessThan(kDifficulty[Difficulty.master]!.speedMul));
    });

    test('holds only ever land on long (>=2 beat) melody notes', () {
      final c = ChartGenerator.generate(song, Difficulty.master, seed: 5);
      for (final n in c.notes) {
        if (n.kind == NoteKind.hold) expect(n.dur, greaterThanOrEqualTo(2.0));
      }
    });

    test('chords use a valid distinct second lane', () {
      final c = ChartGenerator.generate(song, Difficulty.master, seed: 5, columns: 4);
      for (final n in c.notes) {
        if (n.kind == NoteKind.chord) {
          expect(n.chordLane, inInclusiveRange(0, 3));
          expect(n.chordLane == n.lane, false);
        }
      }
    });

    test('legacy charts stay taps-only even at Master (campaign parity)', () {
      expect(
          nonTap(ChartGenerator.generate(song, Difficulty.master,
              seed: 1, legacy: true)),
          0);
    });

    test('generation is deterministic for the same (song, difficulty, seed)', () {
      List<String> sig(Chart c) =>
          [for (final n in c.notes) '${n.lane}:${n.kind.index}:${n.chordLane}'];
      expect(sig(ChartGenerator.generate(song, Difficulty.sulit, seed: 42)),
          sig(ChartGenerator.generate(song, Difficulty.sulit, seed: 42)));
    });
  });

  group('Daily pick determinism', () {
    test('same calendar day → identical pick', () {
      final a = dailyPick(2026, 6, 25, 10);
      final b = dailyPick(2026, 6, 25, 10);
      expect(a.songIndex, b.songIndex);
      expect(a.difficulty, b.difficulty);
      expect(a.seed, b.seed);
      expect(a.songIndex, inInclusiveRange(0, 9));
    });

    test('different days produce different seeds', () {
      expect(dailySeed(2026, 6, 25) == dailySeed(2026, 6, 26), false);
    });
  });
}

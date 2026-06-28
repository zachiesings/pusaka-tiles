import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/motifs.dart';
import 'package:pusaka_tiles/game/songs.dart';

void main() {
  group('motifs', () {
    test('gradeRank orders grades worst→best', () {
      expect(gradeRank('F'), 0);
      expect(gradeRank('A'), 4);
      expect(gradeRank('SSS'), 7);
      expect(gradeRank('A') > gradeRank('B'), true);
      expect(gradeRank('SS') > gradeRank('S'), true);
      expect(gradeRank('???'), -1);
    });

    test('a motif unlocks only on a clear at grade A or better', () {
      expect(unlocksMotif(cleared: true, grade: 'A'), true);
      expect(unlocksMotif(cleared: true, grade: 'S'), true);
      expect(unlocksMotif(cleared: true, grade: 'SSS'), true);
      expect(unlocksMotif(cleared: true, grade: 'B'), false);
      expect(unlocksMotif(cleared: true, grade: 'F'), false);
      expect(unlocksMotif(cleared: false, grade: 'SSS'), false); // didn't finish
    });

    test('every song has exactly one deterministic motif in valid ranges', () {
      expect(MotifCatalog.all.length, SongCatalog.all.length);
      for (final s in SongCatalog.all) {
        final m = MotifCatalog.forSong(s.id);
        expect(m.songId, s.id);
        expect(m.petals, inInclusiveRange(3, 16));
        expect(m.rings, inInclusiveRange(1, 5));
        expect(m.palette.length, greaterThanOrEqualTo(1));
      }
    });

    test('forSong is stable across calls', () {
      final id = SongCatalog.all.first.id;
      final a = MotifCatalog.forSong(id);
      final b = MotifCatalog.forSong(id);
      expect(a.petals, b.petals);
      expect(a.rings, b.rings);
      expect(a.color, b.color);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/engine/tiles_engine.dart';
import 'package:pusaka_tiles/game/models/song.dart';
import 'package:pusaka_tiles/game/songs.dart';

void main() {
  group('TilesEngine', () {
    Song song() => SongCatalog.all.first;

    test('generates rows ahead and starts un-started', () {
      final e = TilesEngine(song: song(), seed: 1);
      expect(e.rows.length, greaterThanOrEqualTo(12));
      expect(e.started, false);
      expect(e.gameOver, false);
    });

    test('does not scroll until the first tap', () {
      final e = TilesEngine(song: song(), seed: 1);
      e.tick(1.0);
      expect(e.scroll, 0); // still waiting for first tap
    });

    test('correct tap scores, plays a valid note, and speeds up', () {
      final e = TilesEngine(song: song(), seed: 2);
      final col = e.rows[e.nextTap].activeColumn;
      final speedBefore = e.speed;
      final note = e.tapColumn(col);
      expect(note, inInclusiveRange(0, NoteTable.freqs.length - 1));
      expect(e.score, 1);
      expect(e.started, true);
      expect(e.speed, greaterThan(speedBefore));
    });

    test('wrong tap ends the game', () {
      final e = TilesEngine(song: song(), seed: 3);
      final wrong = (e.rows[e.nextTap].activeColumn + 1) % e.columns;
      final note = e.tapColumn(wrong);
      expect(note, -1);
      expect(e.gameOver, true);
    });

    test('missing a tile (scrolled past) ends the game', () {
      final e = TilesEngine(song: song(), seed: 4);
      // start, then let lots of time pass without tapping
      e.tapColumn(e.rows[e.nextTap].activeColumn);
      e.tick(0.05);
      for (var i = 0; i < 400 && !e.gameOver; i++) {
        e.tick(0.05);
      }
      expect(e.gameOver, true);
    });

    test('revive clears game-over and keeps score', () {
      final e = TilesEngine(song: song(), seed: 5);
      e.tapColumn(e.rows[e.nextTap].activeColumn);
      final keep = e.score;
      e.gameOver = true;
      e.revive();
      expect(e.gameOver, false);
      expect(e.score, keep);
      expect(e.started, false);
    });
  });
}

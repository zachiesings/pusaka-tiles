import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_tiles/game/chart.dart';
import 'package:pusaka_tiles/game/engine/tiles_engine.dart';
import 'package:pusaka_tiles/game/models/song.dart';
import 'package:pusaka_tiles/game/songs.dart';

void main() {
  Song song() => SongCatalog.all.first;
  Chart chart({Difficulty d = Difficulty.mudah, int seed = 1}) =>
      ChartGenerator.generate(song(), d, seed: seed);

  group('TilesEngine', () {
    test('generates rows ahead and starts un-started', () {
      final e = TilesEngine(chart: chart());
      expect(e.rows.length, greaterThanOrEqualTo(12));
      expect(e.started, false);
      expect(e.gameOver, false);
    });

    test('does not scroll until the first tap', () {
      final e = TilesEngine(chart: chart());
      e.tick(1.0);
      expect(e.scroll, 0); // still waiting for first tap
    });

    test('correct tap scores, plays a valid note, and speeds up', () {
      final e = TilesEngine(chart: chart(seed: 2));
      final col = e.rows[e.nextTap].activeColumn;
      final speedBefore = e.speed;
      final note = e.tapColumn(col);
      expect(note, inInclusiveRange(0, NoteTable.freqs.length - 1));
      expect(e.score, 1);
      expect(e.started, true);
      expect(e.speed, greaterThan(speedBefore));
    });

    test('wrong tap ends the game', () {
      final e = TilesEngine(chart: chart(seed: 3));
      final wrong = (e.rows[e.nextTap].activeColumn + 1) % e.columns;
      final note = e.tapColumn(wrong);
      expect(note, kTapWrong);
      expect(e.gameOver, true);
    });

    test('a tap far ahead of the line whiffs (not consumed)', () {
      final e = TilesEngine(chart: chart(seed: 7));
      e.tapColumn(e.rows[0].activeColumn); // start; scroll stays 0
      // The next tile is a full beat away — tapping its lane now is too early.
      final next = e.rows[e.nextTap];
      final r = e.tapColumn(next.activeColumn);
      expect(r, kTapEarly);
      expect(next.tapped, false); // tile not consumed
    });

    test('missing a tile (scrolled past) ends the game', () {
      final e = TilesEngine(chart: chart(seed: 4));
      e.tapColumn(e.rows[e.nextTap].activeColumn);
      e.tick(0.05);
      for (var i = 0; i < 400 && !e.gameOver; i++) {
        e.tick(0.05);
      }
      expect(e.gameOver, true);
    });

    test('no-fail mode keeps going on a miss', () {
      final e = TilesEngine(chart: chart(seed: 4), loop: true, noFail: true);
      e.tapColumn(e.rows[e.nextTap].activeColumn); // start
      for (var i = 0; i < 400; i++) {
        e.tick(0.05);
      }
      expect(e.gameOver, false);
      expect(e.missCount, greaterThan(0));
    });

    test('finite chart completes when every tile is cleared', () {
      final c = chart(seed: 9);
      final e = TilesEngine(chart: c, finite: true);
      var guard = 0;
      while (!e.completed && guard++ < c.length + 5) {
        if (e.nextTap >= e.rows.length) break;
        e.scroll = e.rows[e.nextTap].startBeat; // line up the tile
        e.tapColumn(e.rows[e.nextTap].activeColumn);
      }
      expect(e.completed, true);
      expect(e.score, c.length);
    });

    test('revive clears game-over and keeps score', () {
      final e = TilesEngine(chart: chart(seed: 5));
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

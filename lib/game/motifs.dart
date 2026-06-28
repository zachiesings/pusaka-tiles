import 'package:flutter/material.dart';
import 'chart.dart' show stableHash;
import 'songs.dart';

/// Performance grades, worst→best. Used to gate motif unlocks by clear quality.
const List<String> kGradeOrder = ['F', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS'];

/// Rank of a grade letter (F=0 … SSS=7); -1 if unknown/empty.
int gradeRank(String grade) => kGradeOrder.indexOf(grade);

/// The clear quality that unlocks a song's signature motif — grade A or better.
const int kMotifUnlockRank = 4; // 'A'

/// True if [grade] on a cleared run is good enough to unlock a motif.
bool unlocksMotif({required bool cleared, required String grade}) =>
    cleared && gradeRank(grade) >= kMotifUnlockRank;

/// A "Pusaka" motif — a song's signature batik, generated procedurally from a
/// small set of shape/palette variants so each region reads distinctly without
/// any hand-drawn art. Rendered by [BatikMotifPainter] (petals/rings/palette).
class Motif {
  final String songId;
  final String name; // display name (region-flavoured)
  final String daerah;
  final int petals;
  final int rings;
  final List<Color> palette; // primary colour first
  const Motif({
    required this.songId,
    required this.name,
    required this.daerah,
    required this.petals,
    required this.rings,
    required this.palette,
  });

  Color get color => palette.first;
}

/// Deterministic motif per song — one signature motif each, drawn from a handful
/// of procedural variants (no parallel art pipeline).
class MotifCatalog {
  MotifCatalog._();

  // A handful of regional-feeling palettes (primary colour first).
  static const List<List<Color>> _palettes = [
    [Color(0xFFF2B73C), Color(0xFFE0913A), Color(0xFFD9A636), Color(0xFFF2C75B)], // emas
    [Color(0xFF2FA987), Color(0xFF3A8FC4), Color(0xFF45C6D4), Color(0xFF1E5A8A)], // samudra
    [Color(0xFFE76A93), Color(0xFF7E55C6), Color(0xFFC9456E), Color(0xFFF2A24B)], // senja
    [Color(0xFF6BBF59), Color(0xFF2E8B57), Color(0xFF7FBF4D), Color(0xFF1F6E4A)], // rimba
    [Color(0xFF5B4BC4), Color(0xFF45C6D4), Color(0xFF7E55C6), Color(0xFFE76A93)], // nila
    [Color(0xFFC02A36), Color(0xFFE0A93A), Color(0xFF7A1F2B), Color(0xFFF2C75B)], // naga
  ];
  static const List<int> _petalOpts = [6, 8, 10, 12];
  static const List<int> _ringOpts = [2, 3, 4];

  static final List<Motif> all = [
    for (final s in SongCatalog.all) _motifFor(s.id, s.daerah),
  ];

  static Motif _motifFor(String id, String daerah) {
    final h = stableHash(id);
    return Motif(
      songId: id,
      name: 'Motif $daerah',
      daerah: daerah,
      petals: _petalOpts[(h >> 2) % _petalOpts.length],
      rings: _ringOpts[(h >> 5) % _ringOpts.length],
      palette: _palettes[h % _palettes.length],
    );
  }

  static Motif forSong(String id) =>
      all.firstWhere((m) => m.songId == id, orElse: () => all.first);
}

/// A melody the player "plays" by tapping tiles. Each note has a pitch (index
/// into NoteTable) AND a duration in beats, so tiles vary in height and the song
/// plays with real rhythm — not a robotic constant pulse. Sequences loop.
///
/// Melodies are transcribed from published not-angka of public-domain folk/
/// children's songs (do=1=index3). No copyrighted recordings — tones are
/// synthesized (see tool/make_notes.py).
class Song {
  final String id;
  final String title;
  final String daerah;
  final List<int> notes;       // pitch indices into NoteTable.freqs
  final List<double> beats;    // duration of each note, in beats (same length)
  final double bpm;            // tempo
  final double speedScale;     // per-song difficulty multiplier

  const Song({
    required this.id,
    required this.title,
    required this.daerah,
    required this.notes,
    required this.beats,
    this.bpm = 100,
    this.speedScale = 1.0,
  });

  int get length => notes.length;
}

/// Diatonic C-major tone table (≈1.7 octaves). not-angka maps as:
/// low 5,6,7 = index 0,1,2 · do(1)=3 re(2)=4 mi(3)=5 fa(4)=6 sol(5)=7 la(6)=8
/// ti(7)=9 · high 1'2'3' = 10,11,12.
class NoteTable {
  NoteTable._();

  static const List<double> freqs = <double>[
    196.00, // 0  G3  (low 5)
    220.00, // 1  A3  (low 6)
    246.94, // 2  B3  (low 7)
    261.63, // 3  C4  do (1)
    293.66, // 4  D4  re (2)
    329.63, // 5  E4  mi (3)
    349.23, // 6  F4  fa (4)
    392.00, // 7  G4  sol (5)
    440.00, // 8  A4  la (6)
    493.88, // 9  B4  ti (7)
    523.25, // 10 C5  do' (1')
    587.33, // 11 D5  re' (2')
    659.25, // 12 E5  mi' (3')
  ];
}

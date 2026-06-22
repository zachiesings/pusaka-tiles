/// A melody the player "plays" by tapping tiles. Notes are indices into the
/// shared diatonic tone table (see NoteTable). Traditional folk / children's
/// melodies are public-domain — no copyright. The sequence loops endlessly.
class Song {
  final String id;
  final String title;
  final String daerah;     // region of origin
  final List<int> notes;   // indices into NoteTable.freqs
  final double speedScale; // per-song difficulty multiplier on scroll speed

  const Song({
    required this.id,
    required this.title,
    required this.daerah,
    required this.notes,
    this.speedScale = 1.0,
  });
}

/// Diatonic C-major tone table (≈1.7 octaves). Songs reference notes by index.
/// Index 3 = "do" (C4); index 10 = high "do" (C5).
class NoteTable {
  NoteTable._();

  static const List<double> freqs = <double>[
    196.00, // 0  G3  (low sol)
    220.00, // 1  A3  (low la)
    246.94, // 2  B3  (low ti)
    261.63, // 3  C4  do
    293.66, // 4  D4  re
    329.63, // 5  E4  mi
    349.23, // 6  F4  fa
    392.00, // 7  G4  sol
    440.00, // 8  A4  la
    493.88, // 9  B4  ti
    523.25, // 10 C5  do'
    587.33, // 11 D5  re'
    659.25, // 12 E5  mi'
  ];
}

import 'models/song.dart';

/// Folk/children's songs transcribed from published not-angka (do=1=index3).
/// notes[] are pitch indices; beats[] is a repeating rhythm pattern (the engine
/// cycles it independently, giving a non-robotic groove). Public-domain tunes,
/// synthesized tones. Low octave: 5,=0 6,=1 7,=2.
class SongCatalog {
  SongCatalog._();

  static const List<Song> all = <Song>[
    Song(
      id: 'gundul', title: 'Gundul-Gundul Pacul', daerah: 'Jawa Tengah',
      bpm: 104, speedScale: 1.05,
      notes: [3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,7,6,6,7,6,5,3,6,5,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,1,1,1,1,1,2],
    ),
    Song(
      id: 'kakaktua', title: 'Burung Kakak Tua', daerah: 'Maluku',
      bpm: 100, speedScale: 1.0,
      notes: [7,7,5,3,5,4, 5,6,8,7,6,5, 7,7,5,3,5,4, 9,8,7,6,5,4,3],
      beats: [1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2],
    ),
    Song(
      id: 'cicak', title: 'Cicak-Cicak di Dinding', daerah: 'Lagu Anak',
      bpm: 96, speedScale: 0.95,
      notes: [7,5,7,5,5,6,7, 6,4,6,8,7,6,5, 8,6,8,6,8,9,10, 10,7,6,5,4,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2],
    ),
    Song(
      id: 'ampar', title: 'Ampar-Ampar Pisang', daerah: 'Kalimantan Selatan',
      bpm: 108, speedScale: 1.1,
      notes: [0,3,3,2,3,4, 0,0,4,4,3,4,5, 6,4,4,5,3,3,4,4,3,2,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'cublak', title: 'Cublak-Cublak Suweng', daerah: 'Jawa Tengah',
      bpm: 100, speedScale: 1.0,
      notes: [7,7,4,5, 3,4,5,3, 4,7,5,4, 3,4,5,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'apuse', title: 'Apuse', daerah: 'Papua',
      bpm: 100, speedScale: 1.05,
      notes: [0,3,5,4,5,4,3,0, 3,5,5,4,5,6,4,0, 3,4,6,7,6,5,4,5,4,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'soleram', title: 'Soleram', daerah: 'Riau',
      bpm: 92, speedScale: 0.95,
      notes: [3,4,5,5,6,7,6,5,4, 5,6,7,7,8,7,6,8,7, 7,8,9,10,7,8,7,6,8,7,6,5,4,3],
      beats: [1,1,2],
    ),
    Song(
      id: 'kambing', title: 'Anak Kambing Saya', daerah: 'Nusa Tenggara Timur',
      bpm: 104, speedScale: 1.1,
      notes: [3,3,3,3,3,2,1,3,2,1,0, 0,4,4,4,4,3,4,5,6,5,4,3,
              6,6,6,6,6,8,8, 5,5,5,5,5,7,7, 4,4,4,4,4,7,6,5,5,4,4,3],
      beats: [1,1,1,1,2],
    ),
    Song(
      id: 'bebek', title: 'Potong Bebek Angsa', daerah: 'Nusa Tenggara Timur',
      bpm: 110, speedScale: 1.15,
      notes: [1,1,3,3,4,4,3,4,3,3,4, 1,1,4,5,6,6,5,6,7,5,6,6,
              7,9,7,5,7,6,8,6,4,6, 5,6,7,4,3,8,9,3,4,6,8],
      beats: [1,1,1,1,2],
    ),
    Song(
      id: 'bungong', title: 'Bungong Jeumpa', daerah: 'Aceh',
      bpm: 96, speedScale: 1.0,
      notes: [8,9,8,8, 8,9,8,7, 8,9,10,9,10, 8,9,8,7,5,7,8],
      beats: [1,1,2],
    ),
    Song(
      id: 'naikgunung', title: 'Naik-Naik ke Puncak Gunung', daerah: 'Maluku',
      bpm: 108, speedScale: 1.05,
      notes: [7,3,3,3,4,5,5,5,3, 6,5,4,2,3,4,3, 7,3,3,3,5,7,7,5,3, 5,4,3,2,3,4,3,
              7,8,8,6,8,7,7,7,5, 7,7,6,4,5,6,5,6,7, 7,8,8,6,8,7,7,7,5, 7,7,6,4,5,4,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'yamko', title: 'Yamko Rambe Yamko', daerah: 'Papua',
      bpm: 120, speedScale: 1.2,
      notes: [3,7,7,8,5,7,8, 7,7,8,4,5,3],
      beats: [1,1,2],
    ),
    Song(
      id: 'rasasayange', title: 'Rasa Sayange', daerah: 'Maluku',
      bpm: 100, speedScale: 1.0,
      notes: [3,3,5,7,7,7,7,8,7, 7,7,6,5,3,5,3,4,5, 5,6,7,7,10,9,8,7,7,5,6,7, 10,9,8,8,7,6,5,6, 5,3,4,4,3,2,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'sipatokaan', title: 'Si Patokaan', daerah: 'Sulawesi Utara',
      bpm: 104, speedScale: 1.05,
      notes: [3,3,3,3,7,7,5,4,3, 6,5,4,3,2,1,2,3,3,3, 7,7,8,10,10,9,8,7,10,12, 8,7,6,5,4,7,6,5,6,7],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'jalijali', title: 'Jali-Jali', daerah: 'DKI Jakarta',
      bpm: 110, speedScale: 1.1,
      notes: [5,7,7,8,7,5,7,7,8,7,5,6,5,6,7, 7,7,7,10,9,7,7,7,6,5,4],
      beats: [1,1,2],
    ),

    // ───────────────────────────────────────────────────────────────
    // Klasik dunia (public domain). Hanya data nada instrumental — tidak
    // ada lirik atau rekaman berhak cipta; nada disintesis sendiri.
    // Komponis wafat >70 tahun lalu → karyanya milik publik. Ditranspose
    // ke C-major agar pas pada tabel nada diatonik.
    // ───────────────────────────────────────────────────────────────
    Song(
      id: 'odetojoy', title: 'Ode to Joy', daerah: 'Beethoven',
      bpm: 108, speedScale: 1.0,
      notes: [5,5,6,7,7,6,5,4,3,3,4,5,5,4,4, 5,5,6,7,7,6,5,4,3,3,4,5,4,3,3],
      beats: [1,1,1,1],
    ),
    Song(
      id: 'einekleine', title: 'Eine kleine Nachtmusik', daerah: 'Mozart',
      bpm: 120, speedScale: 1.15,
      notes: [3,7,3,7,3,5,7,10, 7,11,7,11,7,9,11,7, 10,12,11,10,9,8,7,6, 5,6,7,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'canon', title: 'Canon in D', daerah: 'Pachelbel',
      bpm: 92, speedScale: 0.95,
      notes: [10,9,8,7,6,5,6,7, 8,7,6,5,4,3,4,2, 3,5,7,10,9,7,9,10, 8,6,5,6,7,5,3],
      beats: [2,1,1],
    ),
    Song(
      id: 'minuet', title: 'Minuet', daerah: 'Bach',
      bpm: 110, speedScale: 1.05,
      notes: [0,3,4,5,6,7,3,3, 8,6,7,8,9,10,3,3, 4,5,4,3,4,5,6,7,8, 6,3,5,4,3],
      beats: [1,1,1],
    ),
    Song(
      id: 'twinkle', title: 'Variations K.265', daerah: 'Mozart',
      bpm: 104, speedScale: 1.0,
      notes: [3,3,7,7,8,8,7, 6,6,5,5,4,4,3, 7,7,6,6,5,5,4, 7,7,6,6,5,5,4],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'lullaby', title: 'Wiegenlied (Lullaby)', daerah: 'Brahms',
      bpm: 88, speedScale: 0.9,
      notes: [5,5,7,5,5,7,5,7,10,9,8,8,7, 6,6,5,6,7,3,4,3],
      beats: [1,2],
    ),
    Song(
      id: 'newworld', title: 'Largo (New World)', daerah: 'Dvořák',
      bpm: 84, speedScale: 0.9,
      notes: [5,7,7,5,4,3,4,5,7,5,4, 5,7,10,9,7, 5,7,7,5,4,3,4,5,4,3],
      beats: [1,1,2],
    ),
    Song(
      id: 'spring', title: 'Spring (Four Seasons)', daerah: 'Vivaldi',
      bpm: 112, speedScale: 1.1,
      notes: [5,5,5,7,5,5,5,7, 5,6,5,4,3,4,3, 7,7,8,7,7, 7,8,7,6,5],
      beats: [1,1,1,1],
    ),
    Song(
      id: 'williamtell', title: 'William Tell Finale', daerah: 'Rossini',
      bpm: 124, speedScale: 1.25,
      notes: [7,7,7,10,7,7,10, 7,7,7,12,11,10,9, 8,8,8,10,8,8,10, 12,11,10,9,7],
      beats: [1,1,1],
    ),
    Song(
      id: 'surprise', title: 'Surprise Symphony', daerah: 'Haydn',
      bpm: 108, speedScale: 1.05,
      notes: [3,3,5,5,7,7,5,6,6,4,4,2,2,0, 3,3,5,5,7,7,5,6,4,3],
      beats: [1,1,1,1],
    ),
    Song(
      id: 'moonlight', title: 'Moonlight Sonata', daerah: 'Beethoven',
      bpm: 66, speedScale: 0.85,
      notes: [8,10,12, 8,10,12, 8,9,11, 8,9,11, 7,9,12, 7,9,12, 8,10,12, 8,10,12],
      beats: [1,1,1],
    ),
    Song(
      id: 'furelise', title: 'Für Elise', daerah: 'Beethoven',
      bpm: 116, speedScale: 1.1,
      notes: [5,6,5,6,5,2,4,3,1, 3,5,8,9, 5,7,9,10, 5,6,5,6,5,2,4,3,1],
      beats: [1,1,1],
    ),
    Song(
      id: 'greensleeves', title: 'Greensleeves', daerah: 'Trad. Klasik',
      bpm: 96, speedScale: 0.95,
      notes: [1,3,4,5,6,5,4,2, 0,1,2,3,1,1,0,1, 1,3,4,5,6,5,4,2, 0,1,2,3,4,3,1],
      beats: [1,1,2],
    ),
    Song(
      id: 'jesujoy', title: 'Jesu, Joy of Man', daerah: 'Bach',
      bpm: 100, speedScale: 1.0,
      notes: [3,5,6,7,10,9,7,9,5,6,4, 3,5,6,7,10,12,11,10,12,11,10, 9,10,7,5,3,4,2,3],
      beats: [1,1,1],
    ),
    Song(
      id: 'bluedanube', title: 'Blue Danube', daerah: 'J. Strauss II',
      bpm: 110, speedScale: 1.05,
      notes: [3,5,7,7, 8,7, 3,5,7,7, 8,7, 3,5,7,10,9,8,7,6,5, 4,6,5,4,3],
      beats: [2,1,1],
    ),
  ];

  static Song byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

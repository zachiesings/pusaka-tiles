/// Play modes — each tweaks the scroll speed / ramp for a different feel.
/// [penuh] = "Lagu Penuh": play one song through to the end for a graded result.
enum GameMode { santai, klasik, cepat, penuh }

class ModeParams {
  final String label;
  final String desc;
  final double startSpeed; // beats/sec at the start
  final double speedStep;  // added per correct tap
  final double maxSpeed;
  final bool finite;       // ends after one full pass of the song
  const ModeParams(this.label, this.desc, this.startSpeed, this.speedStep, this.maxSpeed,
      {this.finite = false});
}

const Map<GameMode, ModeParams> kModeParams = {
  GameMode.santai: ModeParams('Santai', 'Tempo tetap, santai', 2.0, 0.0, 2.0),
  GameMode.klasik: ModeParams('Klasik', 'Makin lama makin cepat', 2.4, 0.06, 7.5),
  GameMode.cepat: ModeParams('Cepat', 'Langsung ngebut!', 3.6, 0.09, 9.5),
  GameMode.penuh: ModeParams('Lagu Penuh', 'Tamatkan satu lagu', 2.6, 0.04, 6.0, finite: true),
};

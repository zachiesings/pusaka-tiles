/// Play modes — each tweaks the scroll speed / ramp for a different feel.
enum GameMode { santai, klasik, cepat }

class ModeParams {
  final String label;
  final String desc;
  final double startSpeed; // beats/sec at the start
  final double speedStep;  // added per correct tap
  final double maxSpeed;
  const ModeParams(this.label, this.desc, this.startSpeed, this.speedStep, this.maxSpeed);
}

const Map<GameMode, ModeParams> kModeParams = {
  GameMode.santai: ModeParams('Santai', 'Tempo tetap, santai', 2.0, 0.0, 2.0),
  GameMode.klasik: ModeParams('Klasik', 'Makin lama makin cepat', 2.4, 0.06, 7.5),
  GameMode.cepat: ModeParams('Cepat', 'Langsung ngebut!', 3.6, 0.09, 9.5),
};

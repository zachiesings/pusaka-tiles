/// Wave 6 — rhythm-native per-song modifiers. These are *single-play* challenge
/// toggles chosen on the song-select screen; they change how one run of a song
/// feels and never persist, unlock, or gate progression (HARD CONSTRAINT 4.3a:
/// no run/map/meta structure — these are rhythm flavour only).
library;

enum SongModifier {
  gongGanda, // extra gong/colotomic accents — more driving
  bayangan, // tiles briefly dim each gong cycle (a memory/anticipation test)
  tempoNaik, // a gradual accelerando through the run
}

class ModifierSpec {
  final String label;
  final String desc;
  const ModifierSpec(this.label, this.desc);
}

const Map<SongModifier, ModifierSpec> kModifiers = {
  SongModifier.gongGanda:
      ModifierSpec('Gong Ganda', 'Aksen gong ganda — lebih menghentak'),
  SongModifier.bayangan:
      ModifierSpec('Bayangan', 'Ubin meredup sekejap tiap gong'),
  SongModifier.tempoNaik:
      ModifierSpec('Tempo Naik', 'Tempo perlahan menanjak'),
};

/// Speed-step multiplier from the modifier set (Tempo Naik = stronger ramp).
double modifierSpeedStepMul(Set<SongModifier> mods) =>
    mods.contains(SongModifier.tempoNaik) ? 1.6 : 1.0;

/// Tile opacity for the Bayangan modifier at a given gong-cycle [phase] (0..1):
/// a brief dim window in the back half of each cycle, full brightness otherwise.
/// Bounded to [0.45, 1.0] so tiles never fully vanish (stays playable).
double bayanganTileOpacity(double phase) {
  final p = phase.isNaN ? 0.0 : phase % 1.0;
  return (p >= 0.5 && p < 0.72) ? 0.45 : 1.0;
}

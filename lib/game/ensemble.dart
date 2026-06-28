/// "The Ensemble Awakens" — the layering core of Pusaka Tiles.
///
/// The player's taps carry the lead melody; this director grows a gamelan
/// *around* those taps. Sustained accuracy wakes instruments one by one, each
/// entering on the next gong; a combo break puts the most-recently-woken voice
/// back to sleep. Everything is quantised to the gong cycle (the *gongan*) and
/// crossfaded so the ensemble breathes instead of stuttering.
///
/// IMPORTANT (architecture): the engine's scroll speed ramps per tap, so there
/// is no fixed musical tempo to lock audio stems to. Instead the director works
/// in **scroll-beats** (the same beat space the chart/engine use): layer changes
/// and colotomic punctuation are quantised to beat/gong boundaries the player is
/// actually playing. No Flutter dependency — pure logic, unit-tested.
library;

import 'dart:math' as math;

/// The four ensemble layers, lead first. `lead` is always sounding (the player).
/// The other three wake/sleep with the combo.
enum EnsembleLayer {
  lead, // saron — the player's tapped melody (always on)
  bonang, // L2 elaboration: a shimmering octave above each tapped note
  colotomic, // L3 kenong + kempul: structural punctuation on the gong cycle
  kendang, // L4 drive: the drum + a heavier gong, the full stack
}

/// A short percussive/structural hit the director asks the host to play at a
/// gong-cycle position (not tied to a tap). [voice] names an asset family the
/// AudioService knows how to sound; [note] is a melodic index for pitched
/// colotomic voices (gong/kenong/kempul ring a consonant root or fifth), or -1
/// for unpitched drums.
class ColotomicHit {
  final String voice; // 'gong' | 'kempul' | 'kenong' | 'kendang'
  final int note; // melodic index 0..12, or -1 for unpitched
  final double gain; // 0..1, already faded by the layer's crossfade
  const ColotomicHit(this.voice, this.note, this.gain);
}

/// Tunable defaults (see spec §6). All overridable via the constructor so songs
/// and modes can bend them without touching logic.
class EnsembleConfig {
  final int comboL2; // wake bonang
  final int comboL3; // wake colotomic
  final int comboL4; // wake kendang (full stack)
  final int restoreTaps; // clean taps after a break that re-wake the dropped layer
  final double gonganBeats; // gong cycle in scroll-beats (visual breathing only)
  final int gonganTaps; // gong cycle in PLAYER TAPS — the audible rhythm spine
  final double crossfadeBeats; // wake/sleep ramp length, in beats
  final String ensembleVoice; // asset folder for the pitched ensemble layers
  final bool gongGanda; // Gong Ganda modifier: extra colotomic accents

  const EnsembleConfig({
    this.comboL2 = 8,
    this.comboL3 = 20,
    this.comboL4 = 35,
    this.restoreTaps = 6,
    this.gonganBeats = 16,
    this.gonganTaps = 16,
    this.crossfadeBeats = 1.0,
    this.ensembleVoice = 'gamelan',
    this.gongGanda = false,
  });

  EnsembleConfig copyWith({double? gonganBeats, int? gonganTaps, bool? gongGanda}) =>
      EnsembleConfig(
        comboL2: comboL2,
        comboL3: comboL3,
        comboL4: comboL4,
        restoreTaps: restoreTaps,
        gonganBeats: gonganBeats ?? this.gonganBeats,
        gonganTaps: gonganTaps ?? this.gonganTaps,
        crossfadeBeats: crossfadeBeats,
        ensembleVoice: ensembleVoice,
        gongGanda: gongGanda ?? this.gongGanda,
      );
}

/// Drives ensemble layering from combo + scroll position. The host calls
/// [onCombo]/[onBreak] as the run progresses, [onTap] for the bonang shimmer,
/// and [tick] each frame for crossfades + colotomic scheduling.
class EnsembleDirector {
  EnsembleConfig cfg;

  /// Re-tune the director for a song/mode (e.g. its gong-cycle length). Safe to
  /// call at run start; combine with [reset].
  void configure(EnsembleConfig config) => cfg = config;

  /// 1..4 — how many layers are *targeted* (lead = 1). Wakes are quantised to
  /// the next gong, so [targetLevel] can lead the audible gains by up to a cycle.
  int _target = 1;
  int get targetLevel => _target;

  /// Per-layer audible gain (0..1), index by [EnsembleLayer.index]. Lead is
  /// pinned at 1. The others ramp toward their target (1 if woken, else 0).
  final List<double> _gain = <double>[1, 0, 0, 0];

  /// Per-layer "should be sounding" goal the gains ramp toward.
  final List<double> _goal = <double>[1, 0, 0, 0];

  double _scroll = 0; // last scroll position — drives the VISUAL gong phase only
  int _tap = 0; // player-tap counter — the ensemble's rhythmic spine
  bool _pendingWake = false; // a wake is waiting for the next gong (in taps)
  int _cleanSinceBreak = 0; // clean taps accumulated after a combo break
  bool _restoreArmed = false; // a dropped layer is eligible for the +taps re-wake

  EnsembleDirector({EnsembleConfig? config}) : cfg = config ?? const EnsembleConfig();

  /// Active ensemble layers beyond the lead, 0..3 — the value the colour arc and
  /// instrument icons read (how "awake" the ensemble looks/sounds right now).
  int get activeLayers {
    var n = 0;
    for (var i = 1; i < _gain.length; i++) {
      if (_gain[i] > 0.5) n++;
    }
    return n;
  }

  /// 0..1 "fullness" of the ensemble — drives the indigo→gold colour arc and the
  /// shareable result card. Uses live gains so it moves with the crossfade.
  double get fullness => (_gain[1] + _gain[2] + _gain[3]) / 3.0;

  double gainOf(EnsembleLayer l) => _gain[l.index];
  bool isAwake(EnsembleLayer l) => _gain[l.index] > 0.5;

  /// 0..1 position through the current gong cycle (0 = on the downbeat).
  double get gongPhase {
    final p = (_scroll % cfg.gonganBeats) / cfg.gonganBeats;
    return p.isNaN ? 0 : p;
  }

  /// A gentle 0..1 "breathing" value for the scene, swelling across the gongan
  /// and settling on the gong — drives the subtle scale/zoom on the gong cycle.
  double get gongBreath => 0.5 - 0.5 * math.cos(2 * math.pi * gongPhase);

  /// The combo threshold a given layer requires (for telegraphing the *next*
  /// instrument to wake — see the wordless teaching in §4.8).
  int comboFor(EnsembleLayer l) {
    switch (l) {
      case EnsembleLayer.bonang:
        return cfg.comboL2;
      case EnsembleLayer.colotomic:
        return cfg.comboL3;
      case EnsembleLayer.kendang:
        return cfg.comboL4;
      case EnsembleLayer.lead:
        return 0;
    }
  }

  /// The next layer that is still asleep, or null at full stack — used to pulse
  /// its icon as the combo approaches its threshold.
  EnsembleLayer? get nextSleeping {
    for (final l in [EnsembleLayer.bonang, EnsembleLayer.colotomic, EnsembleLayer.kendang]) {
      if (_target < l.index + 1) return l;
    }
    return null;
  }

  int _levelForCombo(int combo) {
    if (combo >= cfg.comboL4) return 4;
    if (combo >= cfg.comboL3) return 3;
    if (combo >= cfg.comboL2) return 2;
    return 1;
  }

  /// Report the live combo. Climbing past a threshold schedules the next layer
  /// to wake on the upcoming gong (never mid-phrase).
  void onCombo(int combo) {
    final t = _levelForCombo(combo);
    if (t > _target) {
      _target = t;
      _pendingWake = true; // applied at the next gong boundary
      _restoreArmed = false; // a real threshold climb supersedes a pending restore
    }
  }

  /// A combo break (a Bad-timed hit): the most-recently-woken instrument fades
  /// back to sleep — musically, never a harsh full reset. It can be re-earned by
  /// reaching its threshold again, or by [cfg.restoreTaps] clean taps.
  void onBreak() {
    if (_target > 1) {
      _target -= 1;
      _goal[_target] = 0; // sleep the dropped layer (ramps down via tick)
      _restoreArmed = true;
      _cleanSinceBreak = 0;
    }
  }

  /// Lock in a higher layer — the imbal reward. Wakes the next layer on the
  /// upcoming gong and clears any pending sleep, so a nailed call audibly fills
  /// out the ensemble.
  void promote() {
    if (_target < 4) {
      _target += 1;
      _pendingWake = true;
      _restoreArmed = false;
    }
  }

  /// Shift a melodic index by [d] diatonic steps, staying in the note table
  /// (falls back to the original note if it would go out of range) — so every
  /// ensemble voice is an octave-copy of the lead and can NEVER clash.
  static int _shift(int n, int d) {
    final v = n + d;
    return (v >= 0 && v <= 12) ? v : n;
  }

  /// Sound the ensemble *with* a clean tap on [leadNote]. EVERYTHING the gamelan
  /// plays — bonang shimmer, colotomic gong/kenong/kempul, kendang drive — is
  /// emitted here, keyed to the player's TAP (never an independent clock), and
  /// derived from the lead note. So the gamelan plays the melody *together* with
  /// the player, perfectly in time and always consonant. Returns the voices to
  /// play now (already gain-scaled; empty while the ensemble sleeps).
  List<ColotomicHit> onTap(int leadNote) {
    final out = <ColotomicHit>[];
    // Gentle +taps re-wake after a break.
    if (_restoreArmed) {
      _cleanSinceBreak++;
      if (_cleanSinceBreak >= cfg.restoreTaps) {
        _restoreArmed = false;
        _target = math.min(4, _target + 1);
        _pendingWake = true;
      }
    }
    // Tap-quantised gong cycle: position 0 is the gong (cycle start). A pending
    // wake lands here so new layers enter "on the gong" — but in TAP time.
    final gt = cfg.gonganTaps < 2 ? 2 : cfg.gonganTaps;
    final pos = _tap % gt;
    if (pos == 0 && _pendingWake) {
      _pendingWake = false;
      for (var i = 1; i <= _target - 1; i++) {
        _goal[i] = 1;
      }
    }
    _tap++;

    final bonangG = _gain[EnsembleLayer.bonang.index];
    final coloG = _gain[EnsembleLayer.colotomic.index];
    final driveG = _gain[EnsembleLayer.kendang.index];

    // Bonang (L2): the lead an octave up — a shimmer riding your note.
    if (bonangG > 0.02) {
      out.add(ColotomicHit(cfg.ensembleVoice, _shift(leadNote, 7), bonangG * 0.5));
    }
    // Colotomic (L3): structural punctuation that DOUBLES the lead (mostly an
    // octave down) so it reinforces the melody instead of droning against it.
    if (coloG > 0.02) {
      final quarter = (gt / 4).round();
      final half = (gt / 2).round();
      if (pos == 0) {
        out.add(ColotomicHit('gong', _shift(leadNote, -7), coloG * (driveG > 0.5 ? 1.0 : 0.85)));
      } else if (quarter > 0 && pos % quarter == 0) {
        out.add(ColotomicHit('kenong', _shift(leadNote, -7), coloG * 0.7));
      } else if (pos.isEven) {
        out.add(ColotomicHit('kempul', leadNote, coloG * 0.5));
      }
      // Gong Ganda modifier: an extra gong accent on the mid-cycle tap.
      if (cfg.gongGanda && half > 0 && pos == half) {
        out.add(ColotomicHit('gong', _shift(leadNote, -7), coloG * 0.9));
      }
    }
    // Kendang (L4): a soft drum on every other tap — drive, locked to your beat.
    if (driveG > 0.02 && pos.isEven) {
      out.add(ColotomicHit('kendang', -1, driveG * 0.5));
    }
    return out;
  }

  /// Advance the wake/sleep crossfades. [scroll] feeds the VISUAL gong phase only
  /// (the audible rhythm is tap-driven in [onTap]); [dt] is the frame delta.
  void tick(double scroll, double dt) {
    final beatsPerSec = _scroll < scroll && dt > 0 ? (scroll - _scroll) / dt : 0.0;
    _scroll = scroll;
    final rate = cfg.crossfadeBeats > 0 && beatsPerSec > 0
        ? (beatsPerSec / cfg.crossfadeBeats) * dt
        : 1.0; // degenerate: snap
    for (var i = 1; i < _gain.length; i++) {
      final goal = _goal[i];
      if (_gain[i] < goal) {
        _gain[i] = math.min(goal, _gain[i] + rate);
      } else if (_gain[i] > goal) {
        _gain[i] = math.max(goal, _gain[i] - rate);
      }
    }
  }

  /// Reset to a fresh run (lead only).
  void reset() {
    _target = 1;
    _gain
      ..[0] = 1
      ..[1] = 0
      ..[2] = 0
      ..[3] = 0;
    _goal
      ..[0] = 1
      ..[1] = 0
      ..[2] = 0
      ..[3] = 0;
    _scroll = 0;
    _tap = 0;
    _pendingWake = false;
    _cleanSinceBreak = 0;
    _restoreArmed = false;
  }
}

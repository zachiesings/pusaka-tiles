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

/// A note the ensemble plays *with* a tap (the bonang shimmer). Consonant by
/// construction: it is the lead note transposed by whole octaves, so it never
/// clashes with the melody (HARD CONSTRAINT — lead stays in tune).
class CompanionNote {
  final String voice; // instrument folder, e.g. 'gamelan'
  final int note; // melodic index 0..12
  final double gain; // 0..1
  const CompanionNote(this.voice, this.note, this.gain);
}

/// Tunable defaults (see spec §6). All overridable via the constructor so songs
/// and modes can bend them without touching logic.
class EnsembleConfig {
  final int comboL2; // wake bonang
  final int comboL3; // wake colotomic
  final int comboL4; // wake kendang (full stack)
  final int restoreTaps; // clean taps after a break that re-wake the dropped layer
  final double gonganBeats; // length of one gong cycle, in beats
  final double crossfadeBeats; // wake/sleep ramp length, in beats
  final String ensembleVoice; // asset folder for the pitched ensemble layers
  final bool gongGanda; // Gong Ganda modifier: extra colotomic accents

  const EnsembleConfig({
    this.comboL2 = 8,
    this.comboL3 = 20,
    this.comboL4 = 35,
    this.restoreTaps = 6,
    this.gonganBeats = 16,
    this.crossfadeBeats = 1.0,
    this.ensembleVoice = 'gamelan',
    this.gongGanda = false,
  });

  EnsembleConfig copyWith({double? gonganBeats, bool? gongGanda}) => EnsembleConfig(
        comboL2: comboL2,
        comboL3: comboL3,
        comboL4: comboL4,
        restoreTaps: restoreTaps,
        gonganBeats: gonganBeats ?? this.gonganBeats,
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

  double _scroll = 0; // last seen scroll position (beats)
  double _lastGong = 0; // scroll value of the most recent gong boundary
  int _lastBeat = -1; // last integer beat index fired (colotomic dedupe)
  bool _pendingWake = false; // a wake is waiting for the next gong
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

  /// A clean tap (Good or better). Returns the bonang companion note to sound
  /// alongside the lead, or null when that layer is asleep. Also advances the
  /// gentle [cfg.restoreTaps] re-wake after a break.
  CompanionNote? onTap(int leadNote) {
    if (_restoreArmed) {
      _cleanSinceBreak++;
      if (_cleanSinceBreak >= cfg.restoreTaps) {
        _restoreArmed = false;
        _target = math.min(4, _target + 1);
        _pendingWake = true; // re-wake also lands on the next gong
      }
    }
    final g = _gain[EnsembleLayer.bonang.index];
    if (g <= 0.02) return null;
    // Bonang shimmer: the lead note an octave up (7 diatonic steps in the note
    // table). Octaves are always consonant, so the melody can never clash.
    final up = leadNote + 7;
    final note = up <= 12 ? up : leadNote;
    return CompanionNote(cfg.ensembleVoice, note, g * 0.5);
  }

  /// Advance crossfades and surface any colotomic hits due since the last tick.
  /// [scroll] is the engine's beat position; [dt] is the frame delta in seconds.
  /// Returns the hits to play *now* (already gain-scaled; empty when silent).
  List<ColotomicHit> tick(double scroll, double dt) {
    final hits = <ColotomicHit>[];
    // 1) Apply a pending wake when a gong boundary is crossed.
    final gongIndex = (scroll / cfg.gonganBeats).floor();
    final crossedGong = gongIndex * cfg.gonganBeats;
    if (crossedGong > _lastGong + 1e-6) {
      _lastGong = crossedGong;
      if (_pendingWake) {
        _pendingWake = false;
        for (var i = 1; i <= _target - 1; i++) {
          _goal[i] = 1;
        }
      }
    }

    // 2) Ramp gains toward their goals (a linear crossfade over crossfadeBeats,
    //    converted to a per-second rate via the live tempo estimate).
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

    // 3) Colotomic punctuation on integer beats within the gongan. Fires once
    //    per beat crossing; each voice only sounds when its layer is awake.
    final beat = scroll.floor();
    if (beat != _lastBeat && beat >= 0) {
      _lastBeat = beat;
      final inCycle = beat % cfg.gonganBeats.round();
      _appendColotomic(hits, inCycle);
    }
    return hits;
  }

  void _appendColotomic(List<ColotomicHit> hits, int beatInCycle) {
    final gongG = _gain[EnsembleLayer.colotomic.index];
    final driveG = _gain[EnsembleLayer.kendang.index];
    // Gong ageng on the cycle downbeat — the spine. Sounds once the colotomic
    // layer (or the full stack) is awake; louder under the kendang layer.
    if (beatInCycle == 0 && gongG > 0.02) {
      hits.add(ColotomicHit('gong', 3, gongG * (driveG > 0.5 ? 1.0 : 0.8)));
    }
    // Gong Ganda: an extra gong accent on the mid-cycle downbeat — more driving.
    if (cfg.gongGanda && gongG > 0.02) {
      final half = (cfg.gonganBeats / 2).round();
      if (half > 0 && beatInCycle == half) {
        hits.add(ColotomicHit('gong', 7, gongG * 0.85)); // fifth — a consonant accent
      }
    }
    if (gongG > 0.02) {
      // Kenong marks the quarter points (root); kempul the offbeats (fifth).
      final half = (cfg.gonganBeats / 2).round();
      final quarter = (cfg.gonganBeats / 4).round();
      if (beatInCycle != 0 && quarter > 0 && beatInCycle % quarter == 0) {
        hits.add(ColotomicHit('kenong', 7, gongG * 0.7)); // sol — consonant fifth
      } else if (half > 0 && beatInCycle % 2 == 0) {
        hits.add(ColotomicHit('kempul', 3, gongG * 0.5)); // do — consonant root
      }
    }
    // Kendang drive: a soft pulse on every beat once the full stack is awake.
    if (driveG > 0.02) {
      hits.add(ColotomicHit('kendang', -1, driveG * 0.45));
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
    _lastGong = 0;
    _lastBeat = -1;
    _pendingWake = false;
    _cleanSinceBreak = 0;
    _restoreArmed = false;
  }
}

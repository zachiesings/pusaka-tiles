/// Imbal — the signature call-and-response moment (spec §4.3).
///
/// Once per gongan (frequency set by mode), the ensemble states a short
/// interlocking figure — the **call** — by pre-echoing the pitches of the next
/// few tiles and glowing them across the lanes. The player **answers** by
/// playing those tiles cleanly in rhythm. Nail the whole figure and it locks in:
/// an ornamented flourish, a FEVER boost, and a higher ensemble layer. Miss it
/// and the run simply continues — no harsh punishment. The first imbal is
/// telegraphed (slowed/announced) so it teaches itself wordlessly (§4.8).
///
/// Pure logic — no Flutter, unit-tested. The controller feeds it the gong cycle
/// + upcoming pitches and reports each answered tile; this returns when to arm
/// the call and the verdict when the window closes.
library;

/// Per-mode imbal tuning (spec §6). Santai is gentler/rarer; Cepat is frequent
/// with longer figures.
class ImbalConfig {
  final int everyGongans; // arm an imbal every N gong cycles
  final int callLength; // tiles in the call/response figure
  const ImbalConfig({this.everyGongans = 1, this.callLength = 4});
}

/// The verdict when an imbal window closes.
class ImbalResult {
  final bool success; // every call tile answered cleanly (Good+)
  final int clean; // how many were clean
  final int total; // figure length
  const ImbalResult(this.success, this.clean, this.total);
}

class ImbalManager {
  ImbalConfig cfg;
  ImbalManager({ImbalConfig? config}) : cfg = config ?? const ImbalConfig();

  bool _active = false;
  int _remaining = 0; // call tiles still to answer
  int _clean = 0; // clean answers so far
  int _armedCycle = -1; // gong cycle the current/last call armed on
  bool _firstDone = false; // has the player completed their first imbal?

  bool get active => _active;
  int get total => cfg.callLength;
  int get answered => cfg.callLength - _remaining;
  double get progress => cfg.callLength == 0 ? 0 : answered / cfg.callLength;

  /// True until the player finishes their very first imbal — the controller
  /// uses this to telegraph (slow/announce) that first call.
  bool get teaching => !_firstDone;

  void configure(ImbalConfig config) => cfg = config;

  /// At a NEW gong cycle, decide whether to arm an imbal. [upcomingPitches] are
  /// the pitches of the next tiles (from the play head). Returns the call figure
  /// to pre-echo when it arms, else null. Never arms on the opening cycle (0),
  /// so the ensemble has a moment to establish first.
  List<int>? maybeArm(int gongCycle, List<int> upcomingPitches) {
    if (_active || gongCycle <= 0) return null;
    if (gongCycle == _armedCycle) return null;
    if (cfg.everyGongans <= 0 || gongCycle % cfg.everyGongans != 0) return null;
    if (upcomingPitches.length < cfg.callLength) return null; // not enough runway
    _armedCycle = gongCycle;
    _active = true;
    _remaining = cfg.callLength;
    _clean = 0;
    return upcomingPitches.take(cfg.callLength).toList();
  }

  /// Report one answered call tile ([clean] = Good timing or better). Returns the
  /// [ImbalResult] when the figure is complete, else null.
  ImbalResult? onAnswer({required bool clean}) {
    if (!_active) return null;
    _remaining--;
    if (clean) _clean++;
    if (_remaining <= 0) {
      _active = false;
      final ok = _clean == cfg.callLength;
      if (ok) _firstDone = true; // a clean first imbal completes the lesson
      return ImbalResult(ok, _clean, cfg.callLength);
    }
    return null;
  }

  /// Abandon any active call (e.g. on a run-ending miss).
  void cancel() {
    _active = false;
    _remaining = 0;
    _clean = 0;
  }

  void reset() {
    cancel();
    _armedCycle = -1;
    // _firstDone persists across a single session's retries is NOT desired —
    // each fresh run re-teaches if needed, so reset it too.
    _firstDone = false;
  }
}

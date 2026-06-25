import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

/// Calibration: measures this device's audio + touch latency so a dead-centre
/// tap scores Perfect. Two tap-tests share one steady clock; only the cue
/// differs — a metronome TICK (audio offset) or a falling MARKER (touch offset).
/// Each test averages the signed error of your last taps; "Pakai" persists it.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

enum _Test { audio, touch }

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  static const double _period = 1.0; // one beat per second
  late final Ticker _ticker;
  double _elapsed = 0; // seconds since the test clock started
  double _phase = 0; // 0..1 within the current beat
  int _lastBeat = -1;
  _Test _test = _Test.audio;
  final List<double> _samples = <double>[]; // signed errors (ms), most recent last
  static const int _window = 8;

  AppState get _app => context.read<AppState>();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration e) {
    final sec = e.inMicroseconds / 1e6;
    final beat = (sec / _period).floor();
    if (beat != _lastBeat) {
      _lastBeat = beat;
      if (_test == _Test.audio) _app.audio.playTap(); // metronome tick
    }
    setState(() {
      _elapsed = sec;
      _phase = (sec % _period) / _period;
    });
  }

  void _registerTap() {
    // Nearest beat to the tap; signed error in ms (positive = you tapped late).
    final nearest = (_elapsed / _period).round() * _period;
    final errMs = (_elapsed - nearest) * 1000;
    setState(() {
      _samples.add(errMs);
      while (_samples.length > _window) _samples.removeAt(0);
    });
  }

  double get _avg =>
      _samples.isEmpty ? 0 : _samples.reduce((a, b) => a + b) / _samples.length;

  void _switchTest(_Test t) => setState(() {
        _test = t;
        _samples.clear();
      });

  void _apply() {
    final v = _avg;
    if (_test == _Test.audio) {
      _app.setAudioOffsetMs(v);
    } else {
      _app.setTouchOffsetMs(v);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${_test == _Test.audio ? 'Offset audio' : 'Offset sentuh'} diset ke ${v.round()} ms'),
      duration: const Duration(seconds: 2),
    ));
    setState(_samples.clear);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kalibrasi')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                glow: Palette.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.tune_rounded, color: Palette.gold),
                      SizedBox(width: 10),
                      Text('Selaraskan ketukanmu',
                          style: TextStyle(
                              color: Palette.cream,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        'Tiap perangkat punya jeda layar & suara yang beda. Ketuk '
                        'pas di irama beberapa kali, lalu tekan "Pakai" — biar ketukan '
                        'sempurnamu benar-benar dihitung Perfect.',
                        style: TextStyle(
                            color: Palette.cream.withOpacity(0.6), height: 1.4, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Test picker
              Row(
                children: [
                  _segBtn('Suara', Icons.graphic_eq_rounded, _Test.audio),
                  const SizedBox(width: 10),
                  _segBtn('Sentuh', Icons.touch_app_rounded, _Test.touch),
                ],
              ),
              const SizedBox(height: 16),
              SoftCard(
                glow: _test == _Test.audio ? Palette.teal : Palette.indigo,
                child: Column(
                  children: [
                    Text(
                        _test == _Test.audio
                            ? 'Ketuk tombol pas saat mendengar “tik”.'
                            : 'Ketuk tombol pas saat ubin menyentuh garis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Palette.cream.withOpacity(0.7), fontSize: 13)),
                    const SizedBox(height: 12),
                    _stage(),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTapDown: (_) => _registerTap(),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: Palette.brand,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: Palette.glow(Palette.violet, blur: 18, a: 0.4),
                        ),
                        alignment: Alignment.center,
                        child: const Text('KETUK DI IRAMA',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Sampel', '${_samples.length}/$_window'),
                        _stat('Rata-rata',
                            '${_avg >= 0 ? '+' : ''}${_avg.round()} ms'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _samples.isEmpty ? null : () => setState(_samples.clear),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Palette.cream,
                              side: const BorderSide(color: Palette.goldSoft),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Ulangi'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _samples.length < 3 ? null : _apply,
                            child: const Text('Pakai'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Current values + manual fine-tune
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nilai saat ini',
                        style: TextStyle(
                            color: Palette.cream, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _slider('Offset audio', app.audioOffsetMs, app.setAudioOffsetMs),
                    _slider('Offset sentuh', app.touchOffsetMs, app.setTouchOffsetMs),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          app.setAudioOffsetMs(0);
                          app.setTouchOffsetMs(0);
                        },
                        child: const Text('Reset ke 0'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segBtn(String label, IconData icon, _Test t) {
    final sel = _test == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTest(t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: sel ? Palette.indigo : Palette.panelHi.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? Palette.indigo : Palette.gold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sel ? Palette.cream : Palette.goldSoft),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: sel ? Palette.cream : Palette.goldSoft,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  /// The visual cue area: a pulsing ring on the beat (audio), or a falling
  /// marker that lands on the line at each beat (touch).
  Widget _stage() {
    const h = 150.0;
    const lineY = 120.0;
    const top = 8.0;
    final markerY = top + _phase * (lineY - top);
    // Beat pulse: brightest right at the tick, fading across the beat.
    final pulse = (1 - _phase).clamp(0.0, 1.0);
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          // hit line
          Positioned(
            left: 0, right: 0, top: lineY,
            child: Container(height: 3, color: Palette.gold.withOpacity(0.85)),
          ),
          if (_test == _Test.audio)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 60 + pulse * 26,
                  height: 60 + pulse * 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.teal.withOpacity(0.3 + 0.7 * pulse), width: 3),
                    boxShadow: Palette.glow(Palette.teal, blur: 10 + 18 * pulse, a: 0.5 * pulse),
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 0, right: 0, top: markerY,
              child: Center(
                child: Container(
                  width: 64,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Palette.indigo,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: Palette.glow(Palette.violet, blur: 12, a: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Palette.gold, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(color: Palette.cream.withOpacity(0.5), fontSize: 11)),
        ],
      );

  Widget _slider(String label, double value, ValueChanged<double> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: TextStyle(color: Palette.cream.withOpacity(0.8), fontSize: 12)),
            ),
            Expanded(
              child: Slider(
                value: value.clamp(K.offsetMinMs, K.offsetMaxMs),
                min: K.offsetMinMs,
                max: K.offsetMaxMs,
                divisions: ((K.offsetMaxMs - K.offsetMinMs) / 5).round(),
                activeColor: Palette.violet,
                label: '${value.round()} ms',
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 56,
              child: Text('${value >= 0 ? '+' : ''}${value.round()}ms',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Palette.goldLt, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

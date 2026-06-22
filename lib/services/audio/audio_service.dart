import 'package:audioplayers/audioplayers.dart';

/// Plays the synthesized note tones + SFX. A round-robin pool lets fast
/// successive notes overlap naturally. Gated by [enabled] (the sound setting).
class AudioService {
  final List<AudioPlayer> _pool;
  int _next = 0;
  bool enabled = true;

  final AudioPlayer _bgm = AudioPlayer();
  bool musicEnabled = true;
  bool _bgmPlaying = false;

  AudioService({int voices = 5}) : _pool = List.generate(voices, (_) => AudioPlayer()) {
    for (final p in _pool) {
      p.setReleaseMode(ReleaseMode.stop);
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    _bgm.setReleaseMode(ReleaseMode.loop);
  }

  /// Start the looping home background music (gamelan). No-op if music is off.
  Future<void> startBgm() async {
    if (!musicEnabled || _bgmPlaying) return;
    _bgmPlaying = true;
    try {
      await _bgm.play(AssetSource('audio/bgm_home.wav'), volume: 0.55);
    } catch (_) {
      _bgmPlaying = false;
    }
  }

  Future<void> stopBgm() async {
    _bgmPlaying = false;
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  void setMusicEnabled(bool v) {
    musicEnabled = v;
    if (!v) stopBgm();
  }

  Future<void> _play(String asset, {double volume = 0.9}) async {
    if (!enabled) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.stop();
      await p.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // non-essential
    }
  }

  /// Play melody note by table index (clamped to the available files 0..12).
  Future<void> playNote(int index) {
    final i = index < 0 ? 0 : (index > 12 ? 12 : index);
    return _play('audio/note_${i.toString().padLeft(2, '0')}.wav');
  }

  Future<void> playWrong() => _play('audio/wrong.wav', volume: 0.8);
  Future<void> playTap() => _play('audio/tap.wav', volume: 0.6);

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _bgm.dispose();
  }
}

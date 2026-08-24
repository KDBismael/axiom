import 'package:audioplayers/audioplayers.dart';

/// Plays the short chime heard every 25 minutes of active focus time. A
/// playback failure (muted device, missing platform audio session, etc.)
/// must never interrupt the timer, so every call is wrapped defensively.
class FocusChimeService {
  FocusChimeService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> play() async {
    try {
      await _player.play(AssetSource('sounds/focus_chime.wav'));
    } catch (_) {
      // Playback is a nice-to-have; silently ignore any failure.
    }
  }

  void dispose() {
    _player.dispose();
  }
}

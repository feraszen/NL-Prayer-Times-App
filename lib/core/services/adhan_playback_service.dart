import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'custom_adhan_service.dart';

/// Full-length playback begins only after an explicit user action.
class AdhanPlaybackService {
  AdhanPlaybackService._();
  static final instance = AdhanPlaybackService._();
  final playing = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);
  AudioPlayer? _player;

  Future<void> play() async {
    try {
      error.value = null;
      if (_player == null) {
        _player = AudioPlayer();
        _player!.onPlayerComplete.listen((_) => playing.value = false);
      }
      final player = _player!;
      await player.stop();
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      final audio = await CustomAdhanService().selection();
      final path = audio[CustomAdhanService.pathKey];
      playing.value = true;
      await player.play(
        path == null ? AssetSource('audio/adhan.mp3') : DeviceFileSource(path),
      );
    } catch (e) {
      playing.value = false;
      error.value = e.toString();
    }
  }

  Future<void> stop() async {
    await _player?.stop();
    playing.value = false;
  }
}

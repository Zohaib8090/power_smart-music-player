import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.zohaib.powersmart.channel.audio',
      androidNotificationChannelName: 'Power Smart Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Propagate state changes from just_audio to audio_service
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> loadUrl(
    String url, {
    String? title,
    String? artist,
    String? artUri,
  }) async {
    try {
      final source = AudioSource.uri(Uri.parse(url));
      await _player.setAudioSource(source);

      final item = MediaItem(
        id: url,
        title: title ?? "Unknown Title",
        artist: artist ?? "Unknown Artist",
        artUri: artUri != null ? Uri.parse(artUri) : null,
        duration: _player.duration,
      );

      mediaItem.add(item);
      play();
    } catch (e) {
      print("Error loading audio: $e");
    }
  }
}

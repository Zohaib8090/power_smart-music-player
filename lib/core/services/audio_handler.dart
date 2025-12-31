import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:power_player/power_player.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'youtube_service.dart';

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
  final PowerPlayer _powerPlayer = PowerPlayer(id: 'main_audio');

  // Use custom plugin for Windows and Android
  final bool _usePowerPlayer =
      !kIsWeb && (Platform.isWindows || Platform.isAndroid);

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    if (!_usePowerPlayer) {
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
    } else {
      // Initialize our custom PowerPlayer
      await _powerPlayer.initialize();

      // Listen to native events
      _powerPlayer.events.listen((event) {
        final type = event['type'] as String;
        print("PowerPlayer Event: $event");

        switch (type) {
          case 'state':
            final state = event['state'] as String;
            _updateProcessingState(state);
            break;
          case 'isPlaying':
            final isPlaying = event['isPlaying'] as bool;
            _updatePlaybackState(isPlaying);
            break;
          case 'error':
            final message = event['message'] as String?;
            final errorCode = event['errorCode'];
            print("🛑 PowerPlayer Error: $message (Code: $errorCode)");
            // We can also broadcast this error through playbackState if needed
            playbackState.add(
              playbackState.value.copyWith(
                processingState: AudioProcessingState.error,
                errorMessage: message,
              ),
            );
            break;
        }
      });

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          processingState: AudioProcessingState.ready,
          playing: false,
        ),
      );
    }
  }

  void _updateProcessingState(String state) {
    AudioProcessingState audioState;
    switch (state) {
      case 'buffering':
        audioState = AudioProcessingState.buffering;
        break;
      case 'ready':
        audioState = AudioProcessingState.ready;
        break;
      case 'ended':
        audioState = AudioProcessingState.completed;
        break;
      case 'idle':
      default:
        audioState = AudioProcessingState.idle;
    }
    playbackState.add(
      playbackState.value.copyWith(processingState: audioState),
    );
  }

  void _updatePlaybackState(bool isPlaying) {
    playbackState.add(
      playbackState.value.copyWith(
        playing: isPlaying,
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_usePowerPlayer) {
      await _powerPlayer.play();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_usePowerPlayer) {
      await _powerPlayer.pause();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> stop() async {
    if (_usePowerPlayer) {
      await _powerPlayer.stop();
    } else {
      await _player.stop();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_usePowerPlayer) {
      await _powerPlayer.seek(position);
    } else {
      await _player.seek(position);
    }
  }

  final BehaviorSubject<String?> extractionStatus =
      BehaviorSubject<String?>.seeded(null);

  Future<void> playFromVideo({
    required String videoId,
    required String title,
    required String artist,
    required String? artUri,
  }) async {
    // 1. Immediately update UI with song info (provides instant feedback)
    final initialItem = MediaItem(
      id: videoId, // Use videoId as temporary ID
      title: title,
      artist: artist,
      artUri: artUri != null ? Uri.parse(artUri) : null,
    );
    mediaItem.add(initialItem);
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
      ),
    );

    // 2. Fetch URL in "background"
    try {
      extractionStatus.add("Extracting audio for \"$title\"...");
      final YouTubeService youTubeService = YouTubeService();
      final url = await youTubeService.getAudioUrl(videoId);

      if (url != null) {
        extractionStatus.add("Preparing stream...");
        await loadUrl(url, title: title, artist: artist, artUri: artUri);
        extractionStatus.add(null); // Clear status
      } else {
        throw Exception("Could not extract audio URL");
      }
    } catch (e) {
      print("Error in background extraction: $e");
      extractionStatus.add("Extraction failed: $e");
      Future.delayed(
        const Duration(seconds: 3),
        () => extractionStatus.add(null),
      );

      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: "Extraction failed: $e",
        ),
      );
    }
  }

  Future<void> loadUrl(
    String url, {
    String? title,
    String? artist,
    String? artUri,
  }) async {
    try {
      final item = MediaItem(
        id: url,
        title: title ?? "Unknown Title",
        artist: artist ?? "Unknown Artist",
        artUri: artUri != null ? Uri.parse(artUri) : null,
      );
      mediaItem.add(item);

      if (_usePowerPlayer) {
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        };
        await _powerPlayer.setDataSource(url, headers: headers);
        await _powerPlayer.play();
      } else {
        final source = AudioSource.uri(Uri.parse(url));
        await _player.setAudioSource(source);
        await _player.play();
      }
    } catch (e) {
      print("Error loading audio: $e");
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: "Playback failed: $e",
        ),
      );
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    if (_usePowerPlayer) {
      await _powerPlayer.dispose();
    } else {
      await _player.dispose();
    }
    await super.onTaskRemoved();
  }
}

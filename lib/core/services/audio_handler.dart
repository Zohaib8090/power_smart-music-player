import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:power_player/power_player.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';
import 'settings_service.dart';
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
  final SettingsService _settings = GetIt.I<SettingsService>();
  bool _isCrossfading = false;

  // Use custom plugin for Windows and Android
  final bool _usePowerPlayer =
      !kIsWeb && (Platform.isWindows || Platform.isAndroid);

  AudioPlayerHandler() {
    _init();
    _listenToSettings();
  }

  void _listenToSettings() {
    _settings.addListener(() {
      _applyEngineSettings();
    });
  }

  Future<void> _applyEngineSettings() async {
    if (_usePowerPlayer) {
      await _powerPlayer.setEngineConfig({
        'dvc': _settings.dvcEnabled,
        'resampler': _settings.resamplerMode,
        'output': _settings.outputPlugin,
        'chromecast': _settings.chromecastEnabled,
        'gapless': _settings.gaplessPlayback,
        'bit_depth': _settings.audioBitDepth,
        'sample_rate': _settings.audioSampleRate,
        'volume': 1.0, // Base volume
      });
    }
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

      _player.durationStream.listen((dur) {
        if (mediaItem.value != null && dur != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
        }
      });

      _player.positionStream.listen((pos) {
        playbackState.add(playbackState.value.copyWith(updatePosition: pos));
        _checkCrossfade(pos);
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
            playbackState.add(
              playbackState.value.copyWith(
                processingState: AudioProcessingState.error,
                errorMessage: message,
              ),
            );
            break;
        }
      });

      // Sync PowerPlayer progress to audio_service
      _powerPlayer.positionStream.listen((pos) {
        playbackState.add(playbackState.value.copyWith(updatePosition: pos));
        _checkCrossfade(pos);
      });

      _powerPlayer.durationStream.listen((dur) {
        if (mediaItem.value != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
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
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
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
        _onPlaybackEnded();
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

  void _onPlaybackEnded() {
    if (playbackState.value.repeatMode == AudioServiceRepeatMode.one) {
      _powerPlayer.seek(Duration.zero);
      _powerPlayer.play();
    } else {
      skipToNext();
    }
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

  void _checkCrossfade(Duration position) {
    if (_isCrossfading || _settings.crossfadeDuration <= 0) return;

    final duration = mediaItem.value?.duration;
    if (duration == null || duration == Duration.zero) return;

    final crossfadePoint =
        duration - Duration(seconds: _settings.crossfadeDuration);

    if (position >= crossfadePoint) {
      _startCrossfade();
    }
  }

  Future<void> _startCrossfade() async {
    _isCrossfading = true;
    final fadeOutDuration = Duration(seconds: _settings.crossfadeDuration);

    // Fade out
    _fadeVolume(1.0, 0.0, fadeOutDuration).then((_) async {
      await skipToNext();
      // Fade in next track
      _fadeVolume(0.0, 1.0, Duration(seconds: _settings.fadeDuration));
      _isCrossfading = false;
    });
  }

  Future<void> _fadeVolume(double from, double to, Duration duration) async {
    if (duration == Duration.zero) {
      if (_usePowerPlayer) {
        await _powerPlayer.setVolume(to);
      } else {
        await _player.setVolume(to);
      }
      return;
    }

    final steps = 10;
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );
    final volumeStep = (to - from) / steps;

    for (int i = 0; i <= steps; i++) {
      final currentVolume = from + (volumeStep * i);
      if (_usePowerPlayer) {
        await _powerPlayer.setVolume(currentVolume);
      } else {
        await _player.setVolume(currentVolume);
      }
      await Future.delayed(stepDuration);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
    if (_usePowerPlayer) {
      await _powerPlayer.seek(position);
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    if (!_usePowerPlayer) {
      final loopMode = {
        AudioServiceRepeatMode.none: LoopMode.off,
        AudioServiceRepeatMode.one: LoopMode.one,
        AudioServiceRepeatMode.all: LoopMode.all,
      }[repeatMode]!;
      await _player.setLoopMode(loopMode);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    if (!_usePowerPlayer) {
      await _player.setShuffleModeEnabled(
        shuffleMode == AudioServiceShuffleMode.all,
      );
    }
  }

  @override
  Future<void> skipToNext() async {
    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      skipToQueueItem(nextIndex);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final prevIndex = _getPreviousIndex();
    if (prevIndex != -1) {
      skipToQueueItem(prevIndex);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final item = queue.value[index];
    playFromVideo(
      videoId: item.id,
      title: item.title,
      artist: item.artist ?? "",
      artUri: item.artUri?.toString(),
    );
  }

  int _getNextIndex() {
    final curr = _getCurrentIndex();
    if (curr == -1) return -1;

    if (playbackState.value.shuffleMode == AudioServiceShuffleMode.all) {
      final indices = List.generate(queue.value.length, (i) => i)..remove(curr);
      if (indices.isEmpty) return curr;
      return (indices..shuffle()).first;
    }

    if (curr < queue.value.length - 1) {
      return curr + 1;
    } else if (playbackState.value.repeatMode == AudioServiceRepeatMode.all) {
      return 0;
    }
    return -1;
  }

  int _getPreviousIndex() {
    final curr = _getCurrentIndex();
    if (curr == -1) return -1;
    if (curr > 0) {
      return curr - 1;
    } else if (playbackState.value.repeatMode == AudioServiceRepeatMode.all) {
      return queue.value.length - 1;
    }
    return -1;
  }

  int _getCurrentIndex() {
    final id = mediaItem.value?.id;
    if (id == null) return -1;
    return queue.value.indexWhere((item) => item.id == id);
  }

  final BehaviorSubject<String?> extractionStatus =
      BehaviorSubject<String?>.seeded(null);
  String? _currentLoadingVideoId;

  Future<void> playFromVideo({
    required String videoId,
    required String title,
    required String artist,
    required String? artUri,
    List<MediaItem>? newQueue,
  }) async {
    _currentLoadingVideoId = videoId;

    if (newQueue != null && newQueue.isNotEmpty) {
      queue.add(newQueue);
    } else {
      // If the song is already in the queue, we'll keep its metadata.
      // If not, and queue is empty or doesn't have it, we could add it.
      bool exists = queue.value.any((item) => item.id == videoId);
      if (!exists && queue.value.isEmpty) {
        queue.add([
          MediaItem(
            id: videoId,
            title: title,
            artist: artist,
            artUri: artUri != null ? Uri.parse(artUri) : null,
          ),
        ]);
      }
    }

    // 1. Immediately update UI with song info (provides instant feedback)
    final initialItem = MediaItem(
      id: videoId,
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

      // Check if we are still supposed to be playing THIS video
      if (_currentLoadingVideoId != videoId) {
        print(
          "Ignoring extraction result for $videoId: focused moved to $_currentLoadingVideoId",
        );
        return;
      }

      if (url != null) {
        extractionStatus.add("Preparing stream...");
        await loadUrl(
          url,
          id: videoId,
          title: title,
          artist: artist,
          artUri: artUri,
        );
        extractionStatus.add(null); // Clear status
      } else {
        throw Exception("Could not extract audio URL");
      }
    } catch (e) {
      if (_currentLoadingVideoId != videoId) return;

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
    required String id,
    String? title,
    String? artist,
    String? artUri,
  }) async {
    try {
      final item = MediaItem(
        id: id, // KEEP THE ORIGINAL ID (videoId), DON'T USE URL
        title: title ?? "Unknown Title",
        artist: artist ?? "Unknown Artist",
        artUri: artUri != null ? Uri.parse(artUri) : null,
        extras: {'url': url}, // Store URL in extras if needed
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

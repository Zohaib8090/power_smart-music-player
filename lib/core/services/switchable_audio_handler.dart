import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'audio_handler.dart';
import 'stub_audio_handler.dart';

class SwitchableAudioHandler extends BaseAudioHandler {
  AudioHandler _currentHandler = StubAudioHandler();

  final BehaviorSubject<String?> extractionStatus =
      BehaviorSubject<String?>.seeded(null);

  SwitchableAudioHandler() {
    // Start initializing real service in background
    _initRealHandler();
  }

  Future<void> _initRealHandler() async {
    try {
      print("≡ƒôª Initializing real AudioService in background...");
      final realHandler = await initAudioService();
      _currentHandler = realHandler;
      print("✅ Real AudioService initialized and switched!");

      // Sync streams
      playbackState.add(realHandler.playbackState.value);
      mediaItem.add(realHandler.mediaItem.value);
      queue.add(realHandler.queue.value);

      realHandler.playbackState.listen(playbackState.add);
      realHandler.mediaItem.listen(mediaItem.add);
      realHandler.queue.listen(queue.add);

      // Sync extraction status if it's the real handler
      if (realHandler is AudioPlayerHandler) {
        realHandler.extractionStatus.listen(extractionStatus.add);
      }
    } catch (e) {
      print("ΓÜá∩╕Å Failed to initialize real AudioService: $e");
    }
  }

  @override
  Future<void> play() => _currentHandler.play();

  @override
  Future<void> pause() => _currentHandler.pause();

  @override
  Future<void> stop() => _currentHandler.stop();

  @override
  Future<void> seek(Duration position) => _currentHandler.seek(position);

  @override
  Future<void> skipToNext() => _currentHandler.skipToNext();

  @override
  Future<void> skipToPrevious() => _currentHandler.skipToPrevious();

  @override
  Future<void> skipToQueueItem(int index) =>
      _currentHandler.skipToQueueItem(index);

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) => _currentHandler.playFromMediaId(mediaId, extras);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _currentHandler.setRepeatMode(repeatMode);
    // If we're on a stub, we might want to update our local state too
    // but the real handler will update the stream which we're listening to
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _currentHandler.setShuffleMode(shuffleMode);
  }

  // Handle custom method for SearchPage/HomeTab
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) {
    return _currentHandler.customAction(name, extras);
  }

  // Proxy the playFromVideo call
  Future<void> playFromVideo({
    required String videoId,
    required String title,
    required String artist,
    required String? artUri,
    List<MediaItem>? newQueue,
  }) async {
    if (_currentHandler is AudioPlayerHandler) {
      return (_currentHandler as AudioPlayerHandler).playFromVideo(
        videoId: videoId,
        title: title,
        artist: artist,
        artUri: artUri,
        newQueue: newQueue,
      );
    } else if (_currentHandler is StubAudioHandler) {
      return (_currentHandler as StubAudioHandler).playFromVideo(
        videoId: videoId,
        title: title,
        artist: artist,
        artUri: artUri,
        newQueue: newQueue,
      );
    }
  }

  Future<void> playFromLocalTrack(
    Map<dynamic, dynamic> track, {
    List<Map<dynamic, dynamic>>? allTracks,
  }) async {
    if (_currentHandler is AudioPlayerHandler) {
      return (_currentHandler as AudioPlayerHandler).playFromLocalTrack(
        track,
        allTracks: allTracks,
      );
    } else if (_currentHandler is StubAudioHandler) {
      return (_currentHandler as StubAudioHandler).playFromLocalTrack(track);
    }
  }
}

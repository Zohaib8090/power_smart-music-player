import 'package:audio_service/audio_service.dart';

class StubAudioHandler extends BaseAudioHandler {
  final Stream<String?> extractionStatus = Stream.value(null);

  @override
  Future<void> play() async {
    print('⚠️ Audio playback not available');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  // Custom method used in SearchPage and HomeTab
  Future<void> playFromVideo({
    required String videoId,
    required String title,
    required String artist,
    required String? artUri,
    List<MediaItem>? newQueue,
  }) async {
    print('⚠️ playFromVideo not available: $title by $artist');
    // We can at least update the media item so the UI shows something
    final item = MediaItem(
      id: videoId,
      album: 'Stub Album',
      title: title,
      artist: artist,
      artUri: artUri != null ? Uri.parse(artUri) : null,
    );
    mediaItem.add(item);
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  Future<void> playFromLocalTrack(Map<dynamic, dynamic> track) async {
    print('⚠️ playFromLocalTrack not available: ${track['title']}');
  }
}

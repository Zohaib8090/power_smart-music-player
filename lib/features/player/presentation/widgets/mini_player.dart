import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../pages/full_player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<AudioHandler>();

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // If no media item, hide the player
        if (mediaItem == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FullPlayerPage()));
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF282828), // Spotify-like dark grey
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // 1. Main Content Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        // Album Art
                        Hero(
                          tag: 'album_art',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                              image: mediaItem.artUri != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        mediaItem.artUri.toString(),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: mediaItem.artUri == null
                                ? const Icon(
                                    Icons.music_note,
                                    color: Colors.white70,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mediaItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                mediaItem.artist ?? "Unknown Artist",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, snapshot) {
                            final state = snapshot.data;
                            final playing = state?.playing ?? false;
                            final processingState =
                                state?.processingState ??
                                AudioProcessingState.idle;

                            if (processingState ==
                                    AudioProcessingState.loading ||
                                processingState ==
                                    AudioProcessingState.buffering) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      audioHandler.skipToPrevious(),
                                ),
                                IconButton(
                                  icon: Icon(
                                    playing ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => playing
                                      ? audioHandler.pause()
                                      : audioHandler.play(),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => audioHandler.skipToNext(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 2. Tiny Progress Bar at the absolute bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        final duration = mediaItem.duration ?? Duration.zero;

                        return StreamBuilder<Duration>(
                          stream:
                              Stream.periodic(const Duration(milliseconds: 500))
                                  .map(
                                    (_) => audioHandler
                                        .playbackState
                                        .value
                                        .position,
                                  )
                                  .distinct(),
                          builder: (context, posSnapshot) {
                            final position = posSnapshot.data ?? Duration.zero;
                            final double progress =
                                (duration.inMilliseconds > 0)
                                ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                : 0.0;

                            return LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 2,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

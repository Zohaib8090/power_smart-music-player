import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<AudioHandler>();

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // If no media item, hide the player or show placeholder
        if (mediaItem == null) return const SizedBox.shrink();

        return Container(
          height: 64,
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF282828), // Spotify-like dark grey
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Album Art
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                  image: mediaItem.artUri != null
                      ? DecorationImage(
                          image: NetworkImage(mediaItem.artUri.toString()),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: mediaItem.artUri == null
                    ? const Icon(Icons.music_note, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, playbackSnapshot) {
                    final error = playbackSnapshot.data?.errorMessage;

                    if (error != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Error: $error",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return Column(
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
                    );
                  },
                ),
              ),

              // Controls
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final processingState =
                      snapshot.data?.processingState ??
                      AudioProcessingState.idle;
                  final playing = snapshot.data?.playing ?? false;

                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 24.0,
                      height: 24.0,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    );
                  }

                  return IconButton(
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (playing) {
                        audioHandler.pause();
                      } else {
                        audioHandler.play();
                      }
                    },
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => audioHandler.skipToNext(),
              ),
            ],
          ),
        );
      },
    );
  }
}

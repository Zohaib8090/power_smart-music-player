import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class FullPlayerPage extends StatelessWidget {
  const FullPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<AudioHandler>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox.shrink();

          return Stack(
            children: [
              // 1. Blurred Background Image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: mediaItem.artUri != null
                      ? Image.network(
                          mediaItem.artUri.toString(),
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[900]),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 2. Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Column(
                            children: [
                              Text(
                                "PLAYING FROM SEARCH",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Album Art
                      Hero(
                        tag: 'album_art',
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
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
                                    size: 100,
                                    color: Colors.white24,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Title & Artist
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mediaItem.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  mediaItem.artist ?? "Unknown Artist",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Seek Bar
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final duration = mediaItem.duration ?? Duration.zero;

                          return StreamBuilder<Duration>(
                            stream:
                                Stream.periodic(
                                      const Duration(milliseconds: 200),
                                    )
                                    .map(
                                      (_) => audioHandler
                                          .playbackState
                                          .value
                                          .position,
                                    )
                                    .distinct(),
                            builder: (context, posSnapshot) {
                              final position =
                                  posSnapshot.data ??
                                  state?.position ??
                                  Duration.zero;

                              return ProgressBar(
                                progress: position,
                                total: duration,
                                buffered: state?.bufferedPosition,
                                onSeek: (duration) {
                                  audioHandler.seek(duration);
                                },
                                barHeight: 4.0,
                                thumbRadius: 7.0,
                                thumbGlowRadius: 20.0,
                                progressBarColor: Colors.white,
                                baseBarColor: Colors.white24,
                                bufferedBarColor: Colors.white38,
                                thumbColor: Colors.white,
                                barCapShape: BarCapShape.round,
                                timeLabelTextStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                timeLabelPadding: 8.0,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Controls
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final playing = state?.playing ?? false;
                          final repeatMode =
                              state?.repeatMode ?? AudioServiceRepeatMode.none;
                          final shuffleMode =
                              state?.shuffleMode ??
                              AudioServiceShuffleMode.none;
                          final processingState =
                              state?.processingState ??
                              AudioProcessingState.idle;
                          final isLoading =
                              processingState == AudioProcessingState.loading ||
                              processingState == AudioProcessingState.buffering;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color:
                                      shuffleMode == AudioServiceShuffleMode.all
                                      ? const Color(0xFF1DB954)
                                      : Colors.white,
                                ),
                                onPressed: () {
                                  audioHandler.setShuffleMode(
                                    shuffleMode == AudioServiceShuffleMode.none
                                        ? AudioServiceShuffleMode.all
                                        : AudioServiceShuffleMode.none,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressed: () => audioHandler.skipToPrevious(),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.black,
                                          size: 42,
                                        ),
                                        onPressed: () => playing
                                            ? audioHandler.pause()
                                            : audioHandler.play(),
                                      ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressed: () => audioHandler.skipToNext(),
                              ),
                              IconButton(
                                icon: Icon(
                                  repeatMode == AudioServiceRepeatMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  color:
                                      repeatMode != AudioServiceRepeatMode.none
                                      ? const Color(0xFF1DB954)
                                      : Colors.white,
                                ),
                                onPressed: () {
                                  audioHandler.setRepeatMode(
                                    repeatMode == AudioServiceRepeatMode.none
                                        ? AudioServiceRepeatMode.all
                                        : repeatMode ==
                                              AudioServiceRepeatMode.all
                                        ? AudioServiceRepeatMode.one
                                        : AudioServiceRepeatMode.none,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

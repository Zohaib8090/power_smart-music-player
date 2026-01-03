import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

class PlaylistDetailsPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlaylistDetailsPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildPlaylistInfo(context),
          _buildActionsRow(context),
          _buildTracksList(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2A2A), Color(0xFF121212)],
            ),
          ),
          child: Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.star, size: 14, color: Colors.black),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.favorite_border, color: Colors.grey, size: 28),
            const SizedBox(width: 24),
            const Icon(
              Icons.download_for_offline_outlined,
              color: Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 24),
            const Icon(Icons.more_vert, color: Colors.grey, size: 28),
            const Spacer(),
            IconButton(
              onPressed: () {},
              iconSize: 56,
              icon: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1DB954),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow, color: Colors.black, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList(BuildContext context) {
    final tracks = [
      {
        'id': 'kJQP7kiw5Fk',
        'title': 'Despacito',
        'artist': 'Luis Fonsi',
        'artUri': 'https://img.youtube.com/vi/kJQP7kiw5Fk/0.jpg',
      },
      {
        'id': 'hT_nvWreIhg',
        'title': 'One Dance',
        'artist': 'Drake',
        'artUri': 'https://img.youtube.com/vi/hT_nvWreIhg/0.jpg',
      },
      {
        'id': 'JGwWNGJdvx8',
        'title': 'Shape of You',
        'artist': 'Ed Sheeran',
        'artUri': 'https://img.youtube.com/vi/JGwWNGJdvx8/0.jpg',
      },
      {
        'id': 'LSOuI4V6kUM',
        'title': 'Perfect',
        'artist': 'Ed Sheeran',
        'artUri': 'https://img.youtube.com/vi/LSOuI4V6kUM/0.jpg',
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = tracks[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(track['artUri']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            track['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            track['artist']!,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: const Icon(Icons.more_horiz, color: Colors.grey),
          onTap: () async {
            final audioHandler = GetIt.I<AudioHandler>();

            // Create queue from this playlist
            final queue = tracks
                .map(
                  (t) => MediaItem(
                    id: t['id']!,
                    title: t['title']!,
                    artist: t['artist']!,
                    artUri: Uri.parse(t['artUri']!),
                  ),
                )
                .toList();

            await (audioHandler as dynamic).playFromVideo(
              videoId: track['id']!,
              title: track['title']!,
              artist: track['artist']!,
              artUri: track['artUri'],
              newQueue: queue,
            );
          },
        );
      }, childCount: tracks.length),
    );
  }
}

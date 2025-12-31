import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  static const List<Map<String, String>> _featuredSongs = [
    {
      "id": "kJQP7kiw5Fk",
      "title": "Despacito",
      "artist": "Luis Fonsi",
      "artUri": "https://img.youtube.com/vi/kJQP7kiw5Fk/0.jpg",
    },
    {
      "id": "hT_nvWreIhg",
      "title": "One Dance",
      "artist": "Drake",
      "artUri": "https://img.youtube.com/vi/hT_nvWreIhg/0.jpg",
    },
    {
      "id": "JGwWNGJdvx8",
      "title": "Shape of You",
      "artist": "Ed Sheeran",
      "artUri": "https://img.youtube.com/vi/JGwWNGJdvx8/0.jpg",
    },
    {
      "id": "LSOuI4V6kUM",
      "title": "Perfect",
      "artist": "Ed Sheeran",
      "artUri": "https://img.youtube.com/vi/LSOuI4V6kUM/0.jpg",
    },
    {
      "id": "09R8_2nJtjg",
      "title": "Sugar",
      "artist": "Maroon 5",
      "artUri": "https://img.youtube.com/vi/09R8_2nJtjg/0.jpg",
    },
    {
      "id": "fRh_vgS2dFE",
      "title": "Sorry",
      "artist": "Justin Bieber",
      "artUri": "https://img.youtube.com/vi/fRh_vgS2dFE/0.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          floating: true,
          title: const Text(
            "Good Evening",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        // Recommendations Grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemCount: _featuredSongs.length,
              itemBuilder: (context, index) {
                final song = _featuredSongs[index];
                return GestureDetector(
                  onTap: () async {
                    final audioHandler = GetIt.I<AudioHandler>();
                    // Uses the new playFromVideo background flow
                    await (audioHandler as dynamic).playFromVideo(
                      videoId: song['id']!,
                      title: song['title']!,
                      artist: song['artist']!,
                      artUri: song['artUri'],
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(song['artUri']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            song['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

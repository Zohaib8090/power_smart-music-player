import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
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
              itemCount: 6,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    final audioHandler = GetIt.I<AudioHandler>();
                    // Mock Play
                    await (audioHandler as dynamic).loadUrl(
                      "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-${index + 1}.mp3",
                      title: "SoundHelix Song ${index + 1}",
                      artist: "SoundHelix",
                      artUri:
                          "https://via.placeholder.com/150/1DB954/FFFFFF?text=Song+${index + 1}",
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Test Song ${index + 1}",
                            style: const TextStyle(color: Colors.white),
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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'playlist_details_page.dart';
import '../../../home/presentation/pages/profile_page.dart';
import '../../../../core/services/settings_service.dart';
import 'dart:io';
import '../../../../core/services/local_audio_service.dart';
import 'package:audio_service/audio_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final List<String> _filters = [
    'Playlists',
    'Artists',
    'Albums',
    'Downloaded',
    'Local',
  ];
  String _selectedFilter = 'Playlists';
  bool _isGridView = false;
  List<Map<dynamic, dynamic>> _localTracks = [];
  bool _isLoadingLocal = false;

  Future<void> _loadLocalMusic() async {
    if (_localTracks.isNotEmpty) return;
    setState(() => _isLoadingLocal = true);
    final service = GetIt.I<LocalAudioService>();
    final tracks = await service.getLocalTracks();
    setState(() {
      _localTracks = tracks;
      _isLoadingLocal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildFilterChips(),
            _buildSortFilterRow(),
            _buildLibraryItems(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1DB954),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      floating: true,
      pinned: false,
      elevation: 0,
      leading: ListenableBuilder(
        listenable: GetIt.I<SettingsService>(),
        builder: (context, _) {
          final settings = GetIt.I<SettingsService>();
          ImageProvider avatarImage;
          if (settings.avatarPath.startsWith('http')) {
            avatarImage = NetworkImage(settings.avatarPath);
          } else if (settings.avatarPath.isNotEmpty &&
              File(settings.avatarPath).existsSync()) {
            avatarImage = FileImage(File(settings.avatarPath));
          } else {
            avatarImage = const NetworkImage(
              'https://www.w3schools.com/howto/img_avatar.png',
            );
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: avatarImage,
                backgroundColor: const Color(0xFF2A2A2A),
              ),
            ),
          );
        },
      ),
      title: const Text(
        'Your Library',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search Library functionality coming soon'),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add to Library functionality coming soon'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                  if (filter == 'Local') {
                    _loadLocalMusic();
                  }
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFF2A2A2A),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.transparent),
                ),
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortFilterRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.sort, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Recents',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isGridView ? Icons.list : Icons.grid_view,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryItems() {
    if (_selectedFilter == 'Local') {
      return _buildLocalTracks();
    }
    // Dummy Data
    final items = [
      {
        'title': 'Liked Songs',
        'subtitle': 'Playlist • 152 songs',
        'type': 'playlist',
        'isPinned': true,
      },
      {
        'title': 'Discover Weekly',
        'subtitle': 'Playlist • For You',
        'type': 'playlist',
        'isPinned': false,
      },
      {
        'title': 'Artist One',
        'subtitle': 'Artist',
        'type': 'artist',
        'isPinned': false,
      },
      {
        'title': 'Chill Vibes',
        'subtitle': 'Playlist • Zohaib',
        'type': 'playlist',
        'isPinned': false,
      },
      {
        'title': 'Global Top 50',
        'subtitle': 'Playlist • Spotify',
        'type': 'playlist',
        'isPinned': false,
      },
      {
        'title': 'Deep Focus',
        'subtitle': 'Playlist • Ambient',
        'type': 'playlist',
        'isPinned': false,
      },
      {
        'title': 'Artist Two',
        'subtitle': 'Artist',
        'type': 'artist',
        'isPinned': false,
      },
    ];

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailsPage(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(
                          item['type'] == 'artist' ? 100 : 8,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item['type'] == 'artist'
                              ? Icons.person
                              : Icons.music_note,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['subtitle'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }, childCount: items.length),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(
                item['type'] == 'artist' ? 28 : 4,
              ),
            ),
            child: Center(
              child: Icon(
                item['type'] == 'artist' ? Icons.person : Icons.music_note,
                color: Colors.grey,
              ),
            ),
          ),
          title: Row(
            children: [
              if (item['isPinned'] as bool)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.push_pin,
                    color: Color(0xFF1DB954),
                    size: 14,
                  ),
                ),
              Expanded(
                child: Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            item['subtitle'] as String,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailsPage(
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                ),
              ),
            );
          },
        );
      }, childCount: items.length),
    );
  }

  Widget _buildLocalTracks() {
    if (_isLoadingLocal) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }

    if (_localTracks.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No local music found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadLocalMusic,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
              ),
              child: const Text(
                'Scan Device',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _localTracks[index];
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
            ),
            child: const Icon(Icons.music_note, color: Colors.grey),
          ),
          title: Text(
            track['title'] ?? 'Unknown Title',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track['artist'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.more_vert, color: Colors.grey),
          onTap: () {
            final dynamic handler = GetIt.I<AudioHandler>();
            handler.playFromLocalTrack(track, allTracks: _localTracks);
          },
        );
      }, childCount: _localTracks.length),
    );
  }
}

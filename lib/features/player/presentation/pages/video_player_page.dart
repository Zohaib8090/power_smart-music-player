import 'package:flutter/material.dart';
import 'package:power_player/power_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerPage({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late PowerPlayer _player;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _player = PowerPlayer(id: 'video_player_${widget.title.hashCode}');
    _setup();
  }

  Future<void> _setup() async {
    await _player.initialize();
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.youtube.com/',
    };
    await _player.setDataSource(widget.url, headers: headers);
    await _player.play();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _initialized
              ? PowerPlayerView(player: _player)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () => _player.play(),
            ),
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              onPressed: () => _player.pause(),
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: () => _player.stop(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:power_player/power_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _player = PowerPlayer(id: 'example_player');
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.initialize();
    if (!mounted) return;
    setState(() {
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PowerPlayer Example')),
        body: Center(
          child: _initialized
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('PowerPlayer Initialized'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _player.play(),
                      child: const Text('Play'),
                    ),
                    ElevatedButton(
                      onPressed: () => _player.pause(),
                      child: const Text('Pause'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

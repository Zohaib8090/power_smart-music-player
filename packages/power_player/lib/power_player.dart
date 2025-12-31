import 'dart:async';
import 'package:flutter/material.dart';
import 'power_player_platform_interface.dart';

class PowerPlayer {
  final String id;
  int? _textureId;
  bool _isInitialized = false;

  PowerPlayer({this.id = 'default_player'});

  int? get textureId => _textureId;

  Stream<Map<String, dynamic>> get events =>
      PowerPlayerPlatform.instance.playerEvents(id);

  Future<int?> initialize() async {
    if (_isInitialized) return _textureId;
    _textureId = await PowerPlayerPlatform.instance.initialize(id);
    _isInitialized = true;
    return _textureId;
  }

  Future<void> setDataSource(String url, {Map<String, String>? headers}) async {
    await initialize();
    await PowerPlayerPlatform.instance.setDataSource(id, url, headers: headers);
  }

  Future<void> play() async {
    await PowerPlayerPlatform.instance.play(id);
  }

  Future<void> pause() async {
    await PowerPlayerPlatform.instance.pause(id);
  }

  Future<void> stop() async {
    await PowerPlayerPlatform.instance.stop(id);
  }

  Future<void> seek(Duration position) async {
    await PowerPlayerPlatform.instance.seek(id, position);
  }

  Future<void> dispose() async {
    await PowerPlayerPlatform.instance.dispose(id);
    _isInitialized = false;
    _textureId = null;
  }
}

class PowerPlayerView extends StatelessWidget {
  final PowerPlayer player;

  const PowerPlayerView({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    if (player.textureId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Texture(textureId: player.textureId!);
  }
}

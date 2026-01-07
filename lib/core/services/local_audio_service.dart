import 'package:local_audio/local_audio.dart';
import 'permission_service.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class LocalAudioService {
  final _plugin = LocalAudio();
  static const _intentChannel = MethodChannel('intent_channel');

  LocalAudioService() {
    _initIntentListener();
  }

  void _initIntentListener() {
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPlayFile') {
        final uri = call.arguments as String?;
        if (uri != null) {
          _playExternalFile(uri);
        }
      }
    });

    // Check for pending intent on startup
    _intentChannel.invokeMethod('getPendingFile').then((uri) {
      if (uri != null) {
        _playExternalFile(uri as String);
      }
    });
  }

  Future<void> _playExternalFile(String uri) async {
    print("📂 Playing External File: $uri");
    final handler = GetIt.I<AudioHandler>() as AudioPlayerHandler;

    // Decode URI if it's a file path
    String path = uri;
    if (path.startsWith("file://")) {
      path = Uri.decodeComponent(path.replaceFirst("file://", ""));
    }

    await handler.playFromLocalTrack({
      'path': path,
      'title': path.split('/').last,
      'artist': 'External File',
      'id': 'external_${path.hashCode}',
    });
  }

  Future<List<Map<dynamic, dynamic>>> getLocalTracks() async {
    final hasPermission = await PermissionService.hasStoragePermission();
    if (!hasPermission) {
      await PermissionService.requestInitialPermissions();
    }

    try {
      final tracks = await _plugin.getTracks();
      return tracks;
    } catch (e) {
      print("❌ Error scanning local music: $e");
      return [];
    }
  }
}

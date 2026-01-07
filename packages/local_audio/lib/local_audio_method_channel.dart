import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_audio_platform_interface.dart';

/// An implementation of [LocalAudioPlatform] that uses method channels.
class MethodChannelLocalAudio extends LocalAudioPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('local_audio');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<Map<dynamic, dynamic>>> getTracks() async {
    final tracks = await methodChannel.invokeMethod<List<dynamic>>('getTracks');
    return tracks?.map((item) => item as Map<dynamic, dynamic>).toList() ?? [];
  }
}

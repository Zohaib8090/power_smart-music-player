import 'local_audio_platform_interface.dart';

class LocalAudio {
  Future<String?> getPlatformVersion() {
    return LocalAudioPlatform.instance.getPlatformVersion();
  }

  Future<List<Map<dynamic, dynamic>>> getTracks() {
    return LocalAudioPlatform.instance.getTracks();
  }
}

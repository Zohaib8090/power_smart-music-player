import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'local_audio_method_channel.dart';

abstract class LocalAudioPlatform extends PlatformInterface {
  /// Constructs a LocalAudioPlatform.
  LocalAudioPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocalAudioPlatform _instance = MethodChannelLocalAudio();

  /// The default instance of [LocalAudioPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocalAudio].
  static LocalAudioPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocalAudioPlatform] when
  /// they register themselves.
  static set instance(LocalAudioPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Map<dynamic, dynamic>>> getTracks() {
    throw UnimplementedError('getTracks() has not been implemented.');
  }
}

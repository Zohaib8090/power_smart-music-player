import 'package:flutter_test/flutter_test.dart';
import 'package:local_audio/local_audio.dart';
import 'package:local_audio/local_audio_platform_interface.dart';
import 'package:local_audio/local_audio_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocalAudioPlatform
    with MockPlatformInterfaceMixin
    implements LocalAudioPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<Map<dynamic, dynamic>>> getTracks() => Future.value([]);
}

void main() {
  final LocalAudioPlatform initialPlatform = LocalAudioPlatform.instance;

  test('$MethodChannelLocalAudio is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocalAudio>());
  });

  test('getPlatformVersion', () async {
    LocalAudio localAudioPlugin = LocalAudio();
    MockLocalAudioPlatform fakePlatform = MockLocalAudioPlatform();
    LocalAudioPlatform.instance = fakePlatform;

    expect(await localAudioPlugin.getPlatformVersion(), '42');
  });
}

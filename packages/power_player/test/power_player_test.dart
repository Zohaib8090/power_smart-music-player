import 'package:flutter_test/flutter_test.dart';
import 'package:power_player/power_player_platform_interface.dart';
import 'package:power_player/power_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPowerPlayerPlatform
    with MockPlatformInterfaceMixin
    implements PowerPlayerPlatform {
  @override
  Future<int?> initialize(String playerId) => Future.value(0);

  @override
  Future<void> setDataSource(
    String playerId,
    String url, {
    Map<String, String>? headers,
  }) => Future.value();

  @override
  Future<void> play(String playerId) => Future.value();

  @override
  Future<void> pause(String playerId) => Future.value();

  @override
  Future<void> stop(String playerId) => Future.value();

  @override
  Future<void> seek(String playerId, Duration position) => Future.value();

  @override
  Future<void> dispose(String playerId) => Future.value();

  @override
  Future<void> setVolume(String playerId, double volume) => Future.value();

  @override
  Future<void> setEngineConfig(String playerId, Map<String, dynamic> config) =>
      Future.value();

  @override
  Stream<Map<String, dynamic>> playerEvents(String playerId) =>
      const Stream.empty();
}

void main() {
  final PowerPlayerPlatform initialPlatform = PowerPlayerPlatform.instance;

  test('$MethodChannelPowerPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPowerPlayer>());
  });
}

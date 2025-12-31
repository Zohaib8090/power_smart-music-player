import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'power_player_method_channel.dart';

abstract class PowerPlayerPlatform extends PlatformInterface {
  PowerPlayerPlatform() : super(token: _token);

  static final Object _token = Object();
  static PowerPlayerPlatform _instance = MethodChannelPowerPlayer();
  static PowerPlayerPlatform get instance => _instance;

  static set instance(PowerPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int?> initialize(String playerId) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> setDataSource(
    String playerId,
    String url, {
    Map<String, String>? headers,
  }) {
    throw UnimplementedError('setDataSource() has not been implemented.');
  }

  Future<void> play(String playerId) {
    throw UnimplementedError('play() has not been implemented.');
  }

  Future<void> pause(String playerId) {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> stop(String playerId) {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> seek(String playerId, Duration position) {
    throw UnimplementedError('seek() has not been implemented.');
  }

  Future<void> dispose(String playerId) {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Stream<Map<String, dynamic>> playerEvents(String playerId) {
    throw UnimplementedError('playerEvents() has not been implemented.');
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'power_player_platform_interface.dart';

/// An implementation of [PowerPlayerPlatform] that uses method channels.
class MethodChannelPowerPlayer extends PowerPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('power_player');

  @visibleForTesting
  final eventChannel = const EventChannel('power_player_events');

  @override
  Future<int?> initialize(String playerId) async {
    final result = await methodChannel.invokeMethod<int>('initialize', {
      'playerId': playerId,
    });
    return result;
  }

  @override
  Future<void> setDataSource(
    String playerId,
    String url, {
    Map<String, String>? headers,
  }) async {
    await methodChannel.invokeMethod('setDataSource', {
      'playerId': playerId,
      'url': url,
      'headers': headers,
    });
  }

  @override
  Future<void> play(String playerId) async {
    await methodChannel.invokeMethod('play', {'playerId': playerId});
  }

  @override
  Future<void> pause(String playerId) async {
    await methodChannel.invokeMethod('pause', {'playerId': playerId});
  }

  @override
  Future<void> stop(String playerId) async {
    await methodChannel.invokeMethod('stop', {'playerId': playerId});
  }

  @override
  Future<void> seek(String playerId, Duration position) async {
    await methodChannel.invokeMethod('seek', {
      'playerId': playerId,
      'position': position.inMilliseconds,
    });
  }

  @override
  Future<void> dispose(String playerId) async {
    await methodChannel.invokeMethod('dispose', {'playerId': playerId});
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    await methodChannel.invokeMethod('setVolume', {
      'playerId': playerId,
      'volume': volume,
    });
  }

  @override
  Future<void> setEngineConfig(
    String playerId,
    Map<String, dynamic> config,
  ) async {
    await methodChannel.invokeMethod('setEngineConfig', {
      'playerId': playerId,
      'config': config,
    });
  }

  @override
  Stream<Map<String, dynamic>> playerEvents(String playerId) {
    return eventChannel
        .receiveBroadcastStream()
        .map((event) {
          final map = Map<String, dynamic>.from(event as Map);
          return map;
        })
        .where((event) => event['playerId'] == playerId);
  }
}

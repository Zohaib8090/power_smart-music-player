import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_player/power_player_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPowerPlayer platform = MethodChannelPowerPlayer();
  const MethodChannel channel = MethodChannel('power_player');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize', () async {
    await platform.initialize('test_player');
  });
}

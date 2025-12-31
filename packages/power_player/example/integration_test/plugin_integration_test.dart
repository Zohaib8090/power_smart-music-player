import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:power_player/power_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize test', (WidgetTester tester) async {
    final PowerPlayer plugin = PowerPlayer(id: 'test_player');
    final int? textureId = await plugin.initialize();
    // In many cases textureId might be 0 or more
    expect(textureId != null, true);
  });
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

import 'core/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/services/permission_service.dart';

void main() async {
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  // Setup service locator without blocking (audio handler is lazy)
  print('🔧 Setting up service locator...');
  setupServiceLocator();
  print('✅ Service locator ready');

  // Request Initial Permissions (Notifications, Storage)
  await PermissionService.requestInitialPermissions();

  print('🎨 Running app...');
  runApp(const PowerSmartApp());
  print('✅ App widget created');

  // Wake up the backend server (fire and forget)
  _wakeupBackend();
}

Future<void> _wakeupBackend() async {
  try {
    print('🔌 Waking up backend server...');
    final response = await http
        .get(Uri.parse('https://web-backend-3wfv.onrender.com'))
        .timeout(const Duration(seconds: 10));
    print('✅ Backend wakeup status: ${response.statusCode}');
  } catch (e) {
    print('⚠️ Backend wakeup failed (this is usually okay): $e');
  }
}

class PowerSmartApp extends StatelessWidget {
  const PowerSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<SettingsService>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Power Smart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const LoginPage(),
        );
      },
    );
  }
}

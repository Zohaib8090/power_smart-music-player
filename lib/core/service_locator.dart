import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'services/auth_service.dart';
import 'services/switchable_audio_handler.dart';
import 'services/settings_service.dart';
import 'services/local_audio_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  print('  📦 Registering services...');

  // Always register SwitchableAudioHandler immediately.
  // It handles its own background initialization to prevent UI hangs.
  getIt.registerSingleton<AudioHandler>(SwitchableAudioHandler());
  print('  ✅ Switchable audio handler registered');

  // Authentication
  getIt.registerLazySingleton<AuthService>(() => FirebaseAuthService());
  print('  ✅ Auth service registered');

  // Settings
  getIt.registerSingleton<SettingsService>(SettingsService());
  print('  ✅ Settings service registered');

  // Local Music
  getIt.registerLazySingleton<LocalAudioService>(() => LocalAudioService());
  print('  ✅ Local audio service registered');
}

// Deprecated: No longer needed for UI but kept for compatibility
Future<AudioHandler> getAudioHandler() async {
  return getIt<AudioHandler>();
}

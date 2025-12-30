import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'services/audio_handler.dart';
import 'services/auth_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  final audioHandler = await initAudioService();
  getIt.registerSingleton<AudioHandler>(audioHandler);

  // Blocs

  // Authentication
  getIt.registerLazySingleton<AuthService>(() => FirebaseAuthService());
}

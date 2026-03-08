import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration.
class AppConfig {
  /// Backend API base URL.
  /// Priority: --dart-define > .env > fallback.
  static String get backendUrl {
    // 1. Compile-time dart-define (flutter run --dart-define=BACKEND_API_URL=...)
    const define = String.fromEnvironment('BACKEND_API_URL');
    if (define.isNotEmpty) return define;

    // 2. Runtime .env file
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // 3. Dev fallback (Android emulator localhost)
    return 'http://10.0.2.2:8000';
  }

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);
  /// Simulation endpoints call LLMs and can be slow on free-tier Render.
  static const Duration simulationTimeout = Duration(seconds: 90);
}

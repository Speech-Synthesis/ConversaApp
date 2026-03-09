import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../features/voice/voice_service.dart';

/// Provider for the singleton ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for VoiceService with ApiClient dependency injection
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VoiceService(apiClient);
});

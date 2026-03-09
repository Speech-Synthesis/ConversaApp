import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/progress_tracking_service.dart';
import '../models/progress_result.dart';

/// Provider for progress tracking service
final progressTrackingServiceProvider = Provider<ProgressTrackingService>((ref) {
  return ProgressTrackingService();
});

/// Provider for progress results
final progressResultsProvider = FutureProvider<List<ProgressResult>>((ref) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getResults();
});

/// Provider for badges
final badgesProvider = FutureProvider<List<AchievementBadge>>((ref) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getBadges();
});

/// Provider for streak
final streakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getStreak();
});

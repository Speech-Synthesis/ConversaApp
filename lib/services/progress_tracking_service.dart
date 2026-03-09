import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_result.dart';
import '../models/analysis.dart';
import '../models/scenario.dart';

/// Service for storing and retrieving trainee progress.
class ProgressTrackingService {
  static const String _resultsKey = 'trainee_progress_results';
  static const String _badgesKey = 'trainee_badges';
  static const String _streakKey = 'trainee_streak';
  static const String _lastActivityKey = 'trainee_last_activity';

  /// Save a completed simulation result
  Future<void> saveResult({
    required AnalysisResponse analysis,
    required ScenarioSummary scenario,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create progress result
      final result = ProgressResult(
        sessionId: analysis.sessionId,
        scenarioId: analysis.scenarioId,
        scenarioName: scenario.title,
        difficulty: scenario.difficulty,
        completedAt: DateTime.now(),
        overallScore: analysis.overallScore,
        empathyScore: analysis.empathyScore,
        deEscalationScore: analysis.deEscalationScore,
        communicationClarityScore: analysis.communicationClarityScore,
        problemSolvingScore: analysis.problemSolvingScore,
        efficiencyScore: analysis.efficiencyScore,
        grade: analysis.grade,
        durationSeconds: analysis.durationSeconds,
      );

      // Get existing results
      final results = await getResults();
      results.add(result);

      // Save to storage
      final jsonList = results.map((r) => r.toJson()).toList();
      await prefs.setString(_resultsKey, jsonEncode(jsonList));

      // Update streak
      await _updateStreak();

      // Check and unlock badges
      await _checkAndUnlockBadges(results);

      if (kDebugMode) debugPrint('Progress result saved: ${result.scenarioName}');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to save progress result: $e');
    }
  }

  /// Get all saved results
  Future<List<ProgressResult>> getResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resultsKey);
      
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => ProgressResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load progress results: $e');
      return [];
    }
  }

  /// Get results for a specific scenario
  Future<List<ProgressResult>> getResultsForScenario(String scenarioId) async {
    final results = await getResults();
    return results.where((r) => r.scenarioId == scenarioId).toList();
  }

  /// Get all unlocked badges
  Future<List<AchievementBadge>> getBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_badgesKey);
      
      if (jsonString == null) {
        return _getDefaultBadges();
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => AchievementBadge.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load badges: $e');
      return _getDefaultBadges();
    }
  }

  /// Get current streak (days in a row with at least one simulation)
  Future<int> getStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_streakKey) ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load streak: $e');
      return 0;
    }
  }

  /// Clear all progress data
  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resultsKey);
      await prefs.remove(_badgesKey);
      await prefs.remove(_streakKey);
      await prefs.remove(_lastActivityKey);
      if (kDebugMode) debugPrint('Progress data cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to clear progress: $e');
    }
  }

  /// Update streak based on last activity
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastActivityString == null) {
      // First activity ever
      await prefs.setInt(_streakKey, 1);
      await prefs.setString(_lastActivityKey, today.toIso8601String());
      return;
    }

    final lastActivity = DateTime.parse(lastActivityString);
    final lastActivityDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
    final daysDifference = today.difference(lastActivityDay).inDays;

    if (daysDifference == 0) {
      // Same day, no change to streak
      return;
    } else if (daysDifference == 1) {
      // Consecutive day, increment streak
      await prefs.setInt(_streakKey, currentStreak + 1);
      await prefs.setString(_lastActivityKey, today.toIso8601String());
    } else {
      // Streak broken, reset to 1
      await prefs.setInt(_streakKey, 1);
      await prefs.setString(_lastActivityKey, today.toIso8601String());
    }
  }

  /// Check and unlock badges based on achievements
  Future<void> _checkAndUnlockBadges(List<ProgressResult> results) async {
    final badges = await getBadges();
    bool badgesUpdated = false;

    // First Simulation
    final firstSimBadge = badges.firstWhere((b) => b.id == 'first_simulation', orElse: () => _getDefaultBadges()[0]);
    if (!firstSimBadge.isUnlocked && results.isNotEmpty) {
      final index = badges.indexWhere((b) => b.id == 'first_simulation');
      badges[index] = firstSimBadge.copyWith(unlockedAt: DateTime.now());
      badgesUpdated = true;
    }

    // Expert Scenario Completed
    final expertBadge = badges.firstWhere((b) => b.id == 'expert_scenario', orElse: () => _getDefaultBadges()[1]);
    if (!expertBadge.isUnlocked && results.any((r) => r.difficulty.toLowerCase() == 'expert')) {
      final index = badges.indexWhere((b) => b.id == 'expert_scenario');
      badges[index] = expertBadge.copyWith(unlockedAt: DateTime.now());
      badgesUpdated = true;
    }

    // 5-Day Streak
    final streak = await getStreak();
    final streakBadge = badges.firstWhere((b) => b.id == 'five_day_streak', orElse: () => _getDefaultBadges()[2]);
    if (!streakBadge.isUnlocked && streak >= 5) {
      final index = badges.indexWhere((b) => b.id == 'five_day_streak');
      badges[index] = streakBadge.copyWith(unlockedAt: DateTime.now());
      badgesUpdated = true;
    }

    // Empathy Expert (avg empathy score >= 8)
    final empathyBadge = badges.firstWhere((b) => b.id == 'empathy_expert', orElse: () => _getDefaultBadges()[3]);
    if (!empathyBadge.isUnlocked && results.length >= 3) {
      final avgEmpathy = results.map((r) => r.empathyScore).reduce((a, b) => a + b) / results.length;
      if (avgEmpathy >= 8) {
        final index = badges.indexWhere((b) => b.id == 'empathy_expert');
        badges[index] = empathyBadge.copyWith(unlockedAt: DateTime.now());
        badgesUpdated = true;
      }
    }

    // De-escalation Pro (avg de-escalation score >= 8)
    final deescalateBadge = badges.firstWhere((b) => b.id == 'deescalation_pro', orElse: () => _getDefaultBadges()[4]);
    if (!deescalateBadge.isUnlocked && results.length >= 3) {
      final avgDeescalation = results.map((r) => r.deEscalationScore).reduce((a, b) => a + b) / results.length;
      if (avgDeescalation >= 8) {
        final index = badges.indexWhere((b) => b.id == 'deescalation_pro');
        badges[index] = deescalateBadge.copyWith(unlockedAt: DateTime.now());
        badgesUpdated = true;
      }
    }

    // Perfect Score (overall score = 10)
    final perfectBadge = badges.firstWhere((b) => b.id == 'perfect_score', orElse: () => _getDefaultBadges()[5]);
    if (!perfectBadge.isUnlocked && results.any((r) => r.overallScore >= 10)) {
      final index = badges.indexWhere((b) => b.id == 'perfect_score');
      badges[index] = perfectBadge.copyWith(unlockedAt: DateTime.now());
      badgesUpdated = true;
    }

    if (badgesUpdated) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = badges.map((b) => b.toJson()).toList();
      await prefs.setString(_badgesKey, jsonEncode(jsonList));
      if (kDebugMode) debugPrint('Badges updated');
    }
  }

  /// Get default badge definitions
  List<AchievementBadge> _getDefaultBadges() {
    return [
      AchievementBadge(
        id: 'first_simulation',
        name: 'First Steps',
        description: 'Complete your first simulation',
        icon: '🎯',
      ),
      AchievementBadge(
        id: 'expert_scenario',
        name: 'Expert Challenge',
        description: 'Complete an expert-level scenario',
        icon: '🏆',
      ),
      AchievementBadge(
        id: 'five_day_streak',
        name: '5-Day Streak',
        description: 'Practice 5 days in a row',
        icon: '🔥',
      ),
      AchievementBadge(
        id: 'empathy_expert',
        name: 'Empathy Expert',
        description: 'Average empathy score of 8+',
        icon: '💙',
      ),
      AchievementBadge(
        id: 'deescalation_pro',
        name: 'De-escalation Pro',
        description: 'Average de-escalation score of 8+',
        icon: '🧘',
      ),
      AchievementBadge(
        id: 'perfect_score',
        name: 'Perfect Score',
        description: 'Achieve a score of 10/10',
        icon: '⭐',
      ),
    ];
  }
}

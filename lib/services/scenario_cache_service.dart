import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scenario.dart';

/// Service for caching scenarios locally
class ScenarioCacheService {
  static const String _cacheKey = 'cached_scenarios';
  static const String _cacheTimeKey = 'cached_scenarios_time';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// Cache scenarios to local storage
  Future<void> cacheScenarios(List<ScenarioSummary> scenarios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = scenarios.map((s) => s.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail - caching is not critical
      if (kDebugMode) debugPrint('Failed to cache scenarios: $e');
    }
  }

  /// Get cached scenarios
  Future<List<ScenarioSummary>> getCachedScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString == null) return [];

      // Check if cache is still valid
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      
      if (cacheAge > _cacheValidDuration.inMilliseconds) {
        // Cache expired
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ScenarioSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load cached scenarios: $e');
      return [];
    }
  }

  /// Check if we have valid cached data
  Future<bool> hasCachedData() async {
    final scenarios = await getCachedScenarios();
    return scenarios.isNotEmpty;
  }

  /// Clear the cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to clear cache: $e');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../core/api_client.dart';
import '../models/scenario.dart';
import '../services/scenario_cache_service.dart';

/// State notifier for scenarios with caching support
class ScenarioNotifier extends StateNotifier<AsyncValue<List<ScenarioSummary>>> {
  final ApiClient _apiClient;
  final ScenarioCacheService _cacheService;
  String? _selectedCategory;
  String? _selectedDifficulty;

  ScenarioNotifier(this._apiClient, this._cacheService)
      : super(const AsyncValue.loading()) {
    loadScenarios();
  }

  String? get selectedCategory => _selectedCategory;
  String? get selectedDifficulty => _selectedDifficulty;

  Future<void> loadScenarios({String? category, String? difficulty}) async {
    _selectedCategory = category;
    _selectedDifficulty = difficulty;
    
    state = const AsyncValue.loading();

    try {
      // Try to load from API
      final scenarios = await _apiClient.getScenarios(
        category: category,
        difficulty: difficulty,
      );
      
      // Cache the scenarios
      await _cacheService.cacheScenarios(scenarios);
      
      state = AsyncValue.data(scenarios);
    } catch (e, stack) {
      // If API fails, try to load from cache
      final cachedScenarios = await _cacheService.getCachedScenarios();
      
      if (cachedScenarios.isNotEmpty) {
        // Filter cached scenarios if needed
        var filtered = cachedScenarios;
        if (category != null && category.isNotEmpty) {
          filtered = filtered.where((s) => s.category == category).toList();
        }
        if (difficulty != null && difficulty.isNotEmpty) {
          filtered = filtered.where((s) => s.difficulty == difficulty).toList();
        }
        
        state = AsyncValue.data(filtered);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    await loadScenarios(
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
  }

  bool get isOfflineMode {
    return state.hasValue && state.value!.isNotEmpty;
  }
}

/// Provider for scenario cache service
final scenarioCacheServiceProvider = Provider<ScenarioCacheService>((ref) {
  return ScenarioCacheService();
});

/// Provider for scenario state
final scenarioProvider = StateNotifierProvider<ScenarioNotifier, AsyncValue<List<ScenarioSummary>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheService = ref.watch(scenarioCacheServiceProvider);
  return ScenarioNotifier(apiClient, cacheService);
});

/// Provider for categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getCategories();
  } catch (e) {
    // Return default categories on error
    return ['Technical Support', 'Billing', 'General Inquiry'];
  }
});

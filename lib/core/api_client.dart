import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'error_handler.dart';
import '../models/scenario.dart';
import '../models/simulation.dart';
import '../models/analysis.dart';
import '../models/voice.dart';

/// Centralized HTTP client for the ConversaVoice backend.
class ApiClient {
  static String get baseUrl => AppConfig.backendUrl;

  // ─── Helpers ──────────────────────────────────────────────

  /// Log request/response in debug mode only.
  void _log(String msg) {
    if (kDebugMode) debugPrint('[API] $msg');
  }

  /// Parse JSON response or throw ApiException.
  dynamic _decode(http.Response response) {
    _log('${response.statusCode} ${response.request?.url}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    throw ApiException.fromStatus(response.statusCode, body: response.body);
  }

  Future<http.Response> _get(String path,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    _log('GET $uri');
    return http.get(uri).timeout(AppConfig.defaultTimeout);
  }

  Future<http.Response> _post(String path,
      {Map<String, dynamic>? body, Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    _log('POST $uri');
    return http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null)
        .timeout(timeout ?? AppConfig.defaultTimeout);
  }

  Future<http.Response> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    _log('DELETE $uri');
    return http.delete(uri).timeout(AppConfig.defaultTimeout);
  }

  // ─── Health ───────────────────────────────────────────────

  /// Returns true if backend is healthy.
  Future<bool> checkHealth() async {
    try {
      final res = await _get('/api/health');
      final data = _decode(res);
      return data['status'] == 'healthy';
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }

  // ─── Sessions ─────────────────────────────────────────────

  /// Create a new server-side session. Returns session_id.
  Future<String> createSession() async {
    final res = await _post('/api/session');
    final data = _decode(res);
    return data['session_id'];
  }

  /// Delete/cleanup a session.
  Future<void> deleteSession(String sessionId) async {
    try {
      final res = await _delete('/api/session/$sessionId');
      _decode(res);
    } catch (_) {
      // Cleanup is best-effort
    }
  }

  // ─── Chat (assistant mode) ────────────────────────────────

  /// Send text to the LLM and get a response with prosody metadata.
  Future<Map<String, dynamic>> chat(String text, String sessionId) async {
    final res = await _post('/api/chat', body: {
      'text': text,
      'session_id': sessionId,
    });
    return Map<String, dynamic>.from(_decode(res));
  }

  // ─── Transcription ────────────────────────────────────────

  /// Transcribe audio bytes to text.
  Future<String> transcribe(Uint8List audioBytes,
      {String sessionId = '', String filename = 'recording.wav'}) async {
    final uri = Uri.parse('$baseUrl/api/transcribe');
    final request = http.MultipartRequest('POST', uri);
    if (sessionId.isNotEmpty) {
      request.fields['session_id'] = sessionId;
    }
    request.files.add(
        http.MultipartFile.fromBytes('audio', audioBytes, filename: filename));

    _log('POST $uri (multipart)');
    final streamed = await request.send().timeout(AppConfig.defaultTimeout);
    final response = await http.Response.fromStream(streamed);
    final data = _decode(response);
    return data['text'] ?? '';
  }

  // ─── Synthesis ────────────────────────────────────────────

  /// Synthesize text to speech. Returns full audio URL.
  Future<String> synthesize(String text,
      {String? style, String? pitch, String? rate}) async {
    final body = <String, dynamic>{'text': text};
    if (style != null) body['style'] = style;
    if (pitch != null) body['pitch'] = pitch;
    if (rate != null) body['rate'] = rate;

    final res = await _post('/api/synthesize', body: body);
    final data = _decode(res);
    return '$baseUrl${data["audio_url"]}';
  }

  // ─── Simulation: Scenarios ────────────────────────────────

  /// Load all scenarios, optionally filtered.
  Future<List<ScenarioSummary>> getScenarios(
      {String? category, String? difficulty}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }
    final res = await _get('/api/simulation/scenarios',
        query: query.isNotEmpty ? query : null);
    final list = _decode(res) as List<dynamic>;
    return list.map((j) => ScenarioSummary.fromJson(j)).toList();
  }

  /// Get all scenario categories.
  Future<List<String>> getCategories() async {
    final res = await _get('/api/simulation/categories');
    final data = _decode(res);
    if (data is Map && data.containsKey('categories')) {
      return List<String>.from(data['categories']);
    }
    if (data is List) return List<String>.from(data);
    return [];
  }

  // ─── Simulation: Session Flow ─────────────────────────────

  /// Start a simulation. Returns opening message + session info.
  Future<StartSimulationResponse> startSimulation(String scenarioId,
      {String? traineeId}) async {
    final body = <String, dynamic>{'scenario_id': scenarioId};
    if (traineeId != null) body['trainee_id'] = traineeId;

    final res = await _post('/api/simulation/start',
        body: body, timeout: AppConfig.simulationTimeout);
    return StartSimulationResponse.fromJson(_decode(res));
  }

  /// Send trainee response. Returns customer reply + emotion state.
  Future<SimulationTurnResponse> sendResponse(
      String sessionId, String message) async {
    final res = await _post('/api/simulation/respond',
        body: {'session_id': sessionId, 'message': message},
        timeout: AppConfig.simulationTimeout);
    return SimulationTurnResponse.fromJson(_decode(res));
  }

  /// End the simulation session.
  Future<SessionSummary> endSimulation(String sessionId,
      {bool resolutionAchieved = false}) async {
    final res = await _post('/api/simulation/end', body: {
      'session_id': sessionId,
      'resolution_achieved': resolutionAchieved,
    });
    return SessionSummary.fromJson(_decode(res));
  }

  // ─── Simulation: Analysis ─────────────────────────────────

  /// Full LLM-powered analysis (may take a few seconds).
  Future<AnalysisResponse> getAnalysis(String sessionId) async {
    final res = await _get('/api/simulation/analysis/$sessionId');
    return AnalysisResponse.fromJson(_decode(res));
  }

  /// Quick score fallback (faster, less detailed).
  Future<QuickScoreResponse> getQuickScore(String sessionId) async {
    final res = await _get('/api/simulation/analysis/$sessionId/quick');
    return QuickScoreResponse.fromJson(_decode(res));
  }

  /// Get session transcript as text.
  Future<String> getTranscript(String sessionId,
      {String format = 'text'}) async {
    final res = await _get(
      '/api/simulation/sessions/$sessionId/transcript',
      query: {'format': format},
    );
    if (format == 'text') return res.body;
    return jsonEncode(_decode(res));
  }

  // ─── Voice Analysis ───────────────────────────────────────

  /// Analyze trainee voice emotion/delivery (non-blocking).
  Future<VoiceAnalysisResponse> analyzeVoice(Uint8List audioBytes,
      {String filename = 'recording.wav'}) async {
    final uri = Uri.parse('$baseUrl/api/simulation/analyze-voice');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
        http.MultipartFile.fromBytes('audio', audioBytes, filename: filename));

    _log('POST $uri (multipart)');
    final streamed = await request.send().timeout(AppConfig.longTimeout);
    final response = await http.Response.fromStream(streamed);
    return VoiceAnalysisResponse.fromJson(_decode(response));
  }
}

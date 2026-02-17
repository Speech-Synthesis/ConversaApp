import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ApiService {
  // Load base URL from environment, fallback to localhost for dev
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  // Request timeout durations
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _chatTimeout = Duration(seconds: 45);

  String? _sessionId;
  final Uuid _uuid = const Uuid();

  // Create or retrieve session ID
  String get sessionId {
    _sessionId ??= _uuid.v4();
    return _sessionId!;
  }

  // ---------- 1. Health Check ----------
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(_defaultTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } on TimeoutException {
      print('Health check timed out');
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // ---------- 2. Chat with Text ----------
  Future<Map<String, dynamic>> chat(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'session_id': sessionId,
            }),
          )
          .timeout(_chatTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 422) {
        throw ApiException(
          'Invalid request format',
          statusCode: 422,
          body: response.body,
        );
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Chat endpoint not found on server',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'Server error (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on TimeoutException {
      throw ApiException('Request timed out. The server may be waking up — please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not connect to server: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ---------- 3. Upload Audio for Transcription ----------
  Future<String> transcribe(Uint8List audioBytes,
      {String filename = 'recording.wav'}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/transcribe'),
      );

      request.fields['session_id'] = sessionId;
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(_defaultTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '';
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Voice transcription is not available yet. Try typing your message instead.',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'Transcription failed (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on TimeoutException {
      throw ApiException('Transcription timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Transcription connection error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ---------- 4. Synthesize Speech (TTS) ----------
  /// Returns the full URL of the generated audio file
  Future<String> synthesize(String text, {String? style}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/synthesize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'style': style,
            }),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Construct full URL for audio download
        return '$baseUrl${data["audio_url"]}';
      } else if (response.statusCode == 404) {
        throw ApiException(
          'TTS endpoint not available on this server.',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'TTS failed (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on TimeoutException {
      throw ApiException('TTS request timed out.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('TTS connection error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}

/// Custom exception for API errors with status code and body details.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

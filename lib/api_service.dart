import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ApiService {
  // LAN Development Setup:
  // Teammate's backend is running on a different laptop via mobile hotspot.
  // Change this IP if the teammate's IP address changes.
  static const String baseUrl = 'http://10.218.230.91:8000';

  String? _sessionId;
  final Uuid _uuid = const Uuid();

  // Create or retrieve session ID
  String get sessionId {
    _sessionId ??= _uuid.v4();
    return _sessionId!;
  }

  // 1. Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // 2. Chat with Text
  Future<Map<String, dynamic>> chat(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'session_id': sessionId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to chat: ${response.body}');
    }
  }

  // 3. Upload Audio for Transcription (web-compatible using bytes)
  Future<String> transcribe(Uint8List audioBytes, {String filename = 'recording.wav'}) async {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'];
    } else {
      throw Exception('Transcription failed: ${response.body}');
    }
  }

  // 4. Synthesize Speech (TTS)
  // Returns the full URL of the generated audio
  Future<String> synthesize(String text, {String? style}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/synthesize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'style': style,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Construct full URL for audio download
      return '$baseUrl${data["audio_url"]}';
    } else {
      throw Exception('TTS failed: ${response.body}');
    }
  }
}

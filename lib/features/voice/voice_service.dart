import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../core/api_client.dart';
import '../../models/voice.dart';

/// Voice service for recording, transcription, synthesis, and analysis.
/// Works on both web and mobile platforms.
class VoiceService {
  final ApiClient _api;
  final AudioRecorder recorder = AudioRecorder();
  final AudioPlayer player = AudioPlayer();

  VoiceService(this._api);

  /// Check if microphone permission is granted.
  Future<bool> hasPermission() => recorder.hasPermission();

  /// Start recording audio.
  /// On web: encoder config may be ignored; browser uses its default (usually opus/webm).
  /// On mobile: WAV, 16kHz, mono.
  Future<void> startRecording() async {
    debugPrint('[Voice] startRecording, kIsWeb=$kIsWeb');
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '', // On web: ignored. On mobile: uses default location.
    );
    debugPrint('[Voice] recorder.start() completed');
  }

  /// Stop recording and return audio bytes + correct filename.
  /// Returns a record with bytes and the filename (with correct extension).
  Future<RecordingResult?> stopRecording() async {
    final path = await recorder.stop();
    debugPrint('[Voice] recorder.stop() → path=$path');
    if (path == null || path.isEmpty) {
      debugPrint('[Voice] No path returned from recorder');
      return null;
    }

    // Detect file format from the blob URL or path
    String filename = _detectFilename(path);
    debugPrint('[Voice] Detected filename: $filename');

    try {
      final uri = Uri.parse(path);
      final response = await http.get(uri);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        debugPrint('[Voice] Read ${response.bodyBytes.length} bytes');
        return RecordingResult(
          bytes: response.bodyBytes,
          filename: filename,
        );
      } else {
        debugPrint('[Voice] http.get returned status=${response.statusCode}, '
            'bodyLen=${response.bodyBytes.length}');
      }
    } catch (e) {
      debugPrint('[Voice] Error reading recording: $e');
    }

    return null;
  }

  /// Detect filename from blob URL or path.
  String _detectFilename(String path) {
    final lower = path.toLowerCase();
    if (kIsWeb) {
      // Chrome MediaRecorder produces webm/opus by default
      return 'recording.webm';
    }
    if (lower.endsWith('.wav')) return 'recording.wav';
    if (lower.endsWith('.webm')) return 'recording.webm';
    if (lower.endsWith('.m4a')) return 'recording.m4a';
    if (lower.endsWith('.mp4')) return 'recording.mp4';
    if (lower.endsWith('.ogg')) return 'recording.ogg';
    // Default for unknown
    return 'recording.wav';
  }

  /// Transcribe audio bytes to text.
  Future<String> transcribe(Uint8List audioBytes,
      {String sessionId = '', String filename = 'recording.wav'}) {
    return _api.transcribe(audioBytes,
        sessionId: sessionId, filename: filename);
  }

  /// Synthesize text and play audio.
  Future<void> synthesizeAndPlay(String text,
      {String? style, String? pitch, String? rate}) async {
    try {
      final url =
          await _api.synthesize(text, style: style, pitch: pitch, rate: rate);
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      debugPrint('[Voice] TTS error (non-blocking): $e');
    }
  }

  /// Analyze voice emotion/delivery (non-blocking).
  Future<VoiceAnalysisResponse?> analyzeVoice(Uint8List audioBytes) async {
    try {
      return await _api.analyzeVoice(audioBytes);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    recorder.dispose();
    player.dispose();
  }
}

/// Container for recording result with bytes and correct filename.
class RecordingResult {
  final Uint8List bytes;
  final String filename;

  RecordingResult({required this.bytes, required this.filename});
}

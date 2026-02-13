
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Logic to handle different environments (Emulator vs Web vs Device)
  // 10.0.2.2 is for Android Emulator to access localhost
  // localhost is for Web
  // For physical device, you need the machine's local IP (e.g., 192.168.x.x)
  static const String _baseUrlEmulator = 'http://10.0.2.2:8000';
  static const String _baseUrlWeb = 'http://127.0.0.1:8000';

  // Helper to determine base URL
  String get _baseUrl {
    // Simple check for web (you might want 'kIsWeb' from foundation)
    // For now, let's default to localhost (Web) as that's what we are testing
    // If running on emulator, you might need to change this or add platform check
    // import 'package:flutter/foundation.dart' show kIsWeb;
    // if (kIsWeb) return _baseUrlWeb;
    // return _baseUrlEmulator;
    return _baseUrlWeb; 
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }
}

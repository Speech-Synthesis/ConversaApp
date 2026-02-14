
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // LAN Development Setup:
  // Teammate's backend is running on a different laptop via mobile hotspot.
  // Change this IP if the teammate's IP address changes.
  static const String _baseUrl = 'http://10.218.230.91:8000';

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

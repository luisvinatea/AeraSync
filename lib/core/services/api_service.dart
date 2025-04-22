import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer'; // Added for logging

class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8000');

  Future<bool> checkHealth() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        log('API health check result: true'); // Replaced print with log
        return true;
      } else {
        log('API health check failed: ${response.statusCode}', level: 900); // Replaced print with log
        return false;
      }
    } catch (e) {
      log('API health check error: $e', level: 1000); // Replaced print with log
      return false;
    }
  }

  Future<Map<String, dynamic>> compareAerators(Map<String, dynamic> surveyData) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(surveyData),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to compare aerators: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Failed to compare aerators: $e');
    }
  }
}
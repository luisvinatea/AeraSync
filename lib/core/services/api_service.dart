import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({http.Client? client, this.baseUrl = 'http://127.0.0.1:8000'})
      : client = client ?? http.Client();

  Future<bool> checkHealth() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> compareAerators(Map<String, dynamic> surveyData) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(surveyData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to compare aerators: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to compare aerators: $e');
    }
  }
}
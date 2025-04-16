import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:8000'; // Update for production

  Future<Map<String, dynamic>> compareAerators(Map<String, dynamic> inputs) async {
    final url = Uri.parse('$_baseUrl/compare-aerators');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputs),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to compare aerators: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during API call: $e');
    }
  }

  Future<bool> checkHealth() async {
    final url = Uri.parse('$_baseUrl/health');
    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }
}
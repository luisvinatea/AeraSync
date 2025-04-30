import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({
    http.Client? client,
    String? baseUrl,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_URL',
              defaultValue: 'https://aerasync.vercel.app',
            );

  Future<bool> checkHealth() async {
    try {
      // Use /api/health endpoint to match browser requests
      final response = await client.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> compareAerators(
      Map<String, dynamic> inputs) async {
    try {
      // Use /api/compare endpoint to match Vercel routing configuration
      final uri = Uri.parse('$baseUrl/api/compare');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(inputs);

      // Make the POST request with error handling
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
      );

      // Handle HTTP status errors
      if (response.statusCode != 200) {
        throw Exception(
            'API returned status code ${response.statusCode}: ${response.body}');
      }

      // Parse the response body
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw Exception(
            'FormatException: Unexpected character in response - ${e.message}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('FormatException')) {
        rethrow; // Preserve FormatException for specific test cases
      }
      throw Exception('Failed to compare aerators: $e');
    }
  }
}

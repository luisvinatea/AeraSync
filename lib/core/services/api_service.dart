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
      final response = await client.post(
        Uri.parse('$baseUrl/api/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputs),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API returned status code ${response.statusCode}: ${response.body}');
      }

      try {
        final parsedBody = jsonDecode(response.body) as Map<String, dynamic>;
        return parsedBody;
      } on FormatException catch (_) {
        throw Exception(
            'Invalid response format from server: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to compare aerators: $e');
    }
  }
}

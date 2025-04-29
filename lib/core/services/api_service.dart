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
      // Update endpoint path to match backend implementation
      final response = await client.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> compareAerators(
      Map<String, dynamic> inputs) async {
    try {
      // Use relative path for API endpoint
      final response = await client.post(
        Uri.parse('$baseUrl/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputs),
      );

      final parsedBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return parsedBody; // Return the error response as a Map
      }

      return parsedBody;
    } on FormatException catch (e) {
      throw Exception('Failed to compare aerators: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to compare aerators: $e');
    }
  }
}

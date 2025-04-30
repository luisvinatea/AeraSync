import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for making API calls to the AeraSync backend.
/// Implements best practices for error handling and resilience.
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

  /// Checks if the API is healthy by making a GET request to /api/health.
  /// Returns true if healthy, false otherwise.
  Future<bool> checkHealth() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sends aerator comparison data to the API and returns the results.
  ///
  /// Expects a JSON payload with TOD, farm area, financial parameters, and a list
  /// of aerators. Returns a map containing TOD, aerator results, winner label,
  /// and equilibrium prices.
  ///
  /// @param inputs Map containing the survey data for aerator comparison.
  /// @returns Map containing the comparison results.
  /// @throws Exception if there's an error in the API call or response parsing.
  Future<Map<String, dynamic>> compareAerators(
      Map<String, dynamic> inputs) async {
    try {
      final uri = Uri.parse('$baseUrl/api/compare');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(inputs);

      // Make the API request
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
      );

      // Check if the response is successful (status code 200-299)
      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(
              'API error: ${errorData['error'] ?? 'Unknown error'}');
        } catch (_) {
          throw Exception(
              'API returned status code ${response.statusCode}: ${response.body}');
        }
      }

      // Parse the successful response
      try {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result.containsKey('error')) {
          throw Exception('API error: ${result['error']}');
        }
        return result;
      } on FormatException catch (e) {
        throw Exception('Failed to parse response: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to compare aerators: $e');
    }
  }
}
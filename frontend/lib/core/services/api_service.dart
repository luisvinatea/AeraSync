import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for making API calls to the AeraSync backend.
/// Implements best practices for error handling and resilience.
class ApiService {
  final http.Client client;
  final String baseUrl;
  final bool corsRetries;

  ApiService({
    http.Client? client,
    String? baseUrl,
    this.corsRetries = true,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_URL',
              defaultValue: 'https://aerasync-api.vercel.app',
            );

  /// Checks if the API is healthy by making a GET request to /health.
  /// Returns true if healthy, false otherwise.
  Future<bool> checkHealth() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Returns standard headers for all API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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
      final uri = Uri.parse('$baseUrl/compare');
      final headers = _getHeaders();
      final body = jsonEncode(inputs);

      // Make the API request
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
      );

      // Handle CORS errors by checking for empty response with error status
      if (response.statusCode == 0 || 
          (response.statusCode == 400 && response.body.isEmpty) ||
          response.statusCode == 404) {
        // Try alternative approach or endpoint if CORS might be the issue
        if (corsRetries) {
          return _corsRetryCompareAerators(inputs);
        }
      }

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

  /// Fallback method that tries alternative API endpoints if CORS issues happen
  Future<Map<String, dynamic>> _corsRetryCompareAerators(
      Map<String, dynamic> inputs) async {
    // Try with /api/compare endpoint instead
    try {
      final uri = Uri.parse('$baseUrl/api/compare');
      final headers = _getHeaders();
      final body = jsonEncode(inputs);
      
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300 && response.body.isNotEmpty) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result.containsKey('error')) {
          throw Exception('API error: ${result['error']}');
        }
        return result;
      }
      
      throw Exception('All API retry attempts failed');
    } catch (e) {
      throw Exception('API retry failed: $e');
    }
  }
}
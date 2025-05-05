import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Service for making API calls to the AeraSync backend.
/// Implements best practices for error handling and resilience.
class ApiService {
  final http.Client client;
  final String baseUrl;
  final bool corsRetries;
  late final bool _isLocalDevelopment;

  ApiService({
    http.Client? client,
    String? baseUrl,
    this.corsRetries = true,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_URL',
              defaultValue: 'https://aerasync-api.vercel.app',
            ) {
    // Detect if we're in local development mode (likely using a different port) or production
    _isLocalDevelopment =
        kDebugMode && Uri.base.toString().contains('localhost');
    if (_isLocalDevelopment) {
      debugPrint(
          'Running in local development mode. Using CORS-friendly settings.');
    }
  }

  /// Checks if the API is healthy by making a GET request to /health.
  /// Returns true if healthy, false otherwise.
  Future<bool> checkHealth() async {
    try {
      // Try the primary health endpoint
      final response = await client
          .get(
            Uri.parse('$baseUrl/health'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Returns standard headers for all API requests
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add CORS headers for web requests in local development
    if (_isLocalDevelopment && kIsWeb) {
      headers['Access-Control-Allow-Origin'] = '*';
    }

    return headers;
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
      Map<String, dynamic> data) async {
    // For local development in web browser, just use the standard endpoint
    // since we've confirmed the fallback endpoint doesn't exist
    try {
      final url = Uri.parse('$baseUrl/compare');
      debugPrint('Sending request to: $url');

      final response = await client
          .post(
            url,
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Check for API errors
        if (result is Map<String, dynamic>) {
          if (result.containsKey('error')) {
            throw Exception('API error: ${result['error']}');
          }
          return result;
        } else {
          throw Exception('Invalid response format from API');
        }
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}, message: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in compareAerators: $e');
      rethrow;
    }
  }
}

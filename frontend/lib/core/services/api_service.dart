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

      // If primary fails and CORS retries are enabled, try the alternative endpoint
      if (corsRetries) {
        final altResponse = await client
            .get(
              Uri.parse('$baseUrl/api/health'),
              headers: _getHeaders(),
            )
            .timeout(const Duration(seconds: 5));

        return altResponse.statusCode == 200;
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

    // Add 'mode': 'cors' for web requests in local development
    if (_isLocalDevelopment && kIsWeb) {
      headers['mode'] = 'cors';
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
    // For local development, try the fallback endpoint first if we're in a browser
    if (_isLocalDevelopment && kIsWeb) {
      try {
        return await _corsRetryCompareAerators(data);
      } catch (e) {
        debugPrint('CORS fallback failed, trying primary endpoint: $e');
        // Continue with the standard endpoint if fallback fails
      }
    }

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

      // Try with CORS fallback if enabled and we haven't tried it yet
      if (corsRetries && (!_isLocalDevelopment || !kIsWeb)) {
        debugPrint('Attempting CORS fallback...');
        return await _corsRetryCompareAerators(data);
      }

      rethrow;
    }
  }

  /// Fallback method that tries alternative API endpoints if CORS issues happen
  Future<Map<String, dynamic>> _corsRetryCompareAerators(
      Map<String, dynamic> inputs) async {
    try {
      final uri = Uri.parse('$baseUrl/api/compare');
      debugPrint('Sending fallback request to: $uri');

      final headers = _getHeaders();
      final body = jsonEncode(inputs);

      final response = await client
          .post(
            uri,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Fallback API Response status: ${response.statusCode}');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
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

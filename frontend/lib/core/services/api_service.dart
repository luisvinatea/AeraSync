import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Added for debugPrint

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
      // Try the primary health endpoint
      final response = await client.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return true;
      }
      
      // If primary fails and CORS retries are enabled, try the alternative endpoint
      if (corsRetries) {
        final altResponse = await client.get(
          Uri.parse('$baseUrl/api/health'),
          headers: _getHeaders(),
        ).timeout(const Duration(seconds: 5));
        
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
  Future<Map<String, dynamic>> compareAerators(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/compare');
      final response = await client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Add debug logging
        debugPrint('API Response status: ${response.statusCode}');
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
        throw Exception('API request failed with status: ${response.statusCode}, message: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in compareAerators: $e');
      
      // Try with CORS fallback if enabled
      if (corsRetries) {
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
      final headers = _getHeaders();
      final body = jsonEncode(inputs);
      
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 12));
      
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
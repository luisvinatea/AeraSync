import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aerasync/core/services/api_service.dart';

// Generate mock HTTP client
@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService', () {
    late MockClient mockClient;
    late ApiService apiService;
    const baseUrl = 'https://test-api.aerasync.com';

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(
        client: mockClient,
        baseUrl: baseUrl,
      );
    });

    group('checkHealth', () {
      test('returns true when API is healthy', () async {
        // Arrange
        when(mockClient.get(Uri.parse('$baseUrl/api/health'))).thenAnswer(
            (_) async => http.Response('{"status":"healthy"}', 200));

        // Act
        final result = await apiService.checkHealth();

        // Assert
        expect(result, true);
        verify(mockClient.get(Uri.parse('$baseUrl/api/health'))).called(1);
      });

      test('returns false when API returns non-200 status code', () async {
        // Arrange
        when(mockClient.get(Uri.parse('$baseUrl/api/health')))
            .thenAnswer((_) async => http.Response('Server Error', 500));

        // Act
        final result = await apiService.checkHealth();

        // Assert
        expect(result, false);
        verify(mockClient.get(Uri.parse('$baseUrl/api/health'))).called(1);
      });

      test('returns false when API call throws an exception', () async {
        // Arrange
        when(mockClient.get(Uri.parse('$baseUrl/api/health')))
            .thenThrow(Exception('Network error'));

        // Act
        final result = await apiService.checkHealth();

        // Assert
        expect(result, false);
        verify(mockClient.get(Uri.parse('$baseUrl/api/health'))).called(1);
      });
    });

    group('compareAerators', () {
      final testInputs = {
        'tod': 5443.7675,
        'farm_area_ha': 1000,
        'financial': {
          'energy_cost': 0.05,
          'operating_hours': 2920,
          'discount_rate': 0.1,
          'inflation_rate': 0.025,
          'horizon': 9,
          'safety_margin': 0
        },
        'aerators': [
          {
            'name': 'Aerator 1',
            'sotr': 1.4,
            'power_hp': 3,
            'cost': 500,
            'durability': 2,
            'maintenance': 65
          },
          {
            'name': 'Aerator 2',
            'sotr': 2.2,
            'power_hp': 3.5,
            'cost': 800,
            'durability': 4.5,
            'maintenance': 50
          }
        ]
      };

      final testResponse = {
        'tod': 5443.7675,
        'aeratorResults': [
          {
            'name': 'Aerator 1',
            'num_aerators': 3889,
            'total_power_hp': 11667,
            'total_initial_cost': 1944500,
            'annual_energy_cost': 1270722.97,
            'annual_maintenance_cost': 252785,
            'npv_cost': -10608909.98,
            'aerators_per_ha': 3.889,
            'hp_per_ha': 11.667,
            'sae': 0.63,
            'payback_years': 2.5,
            'roi_percent': 150.25,
            'irr': 32.16,
            'profitability_k': 1.5
          },
          {
            'name': 'Aerator 2',
            'num_aerators': 2475,
            'total_power_hp': 8662.5,
            'total_initial_cost': 1980000,
            'annual_energy_cost': 943410.30,
            'annual_maintenance_cost': 123750,
            'npv_cost': -7546848.31,
            'aerators_per_ha': 2.475,
            'hp_per_ha': 8.6625,
            'sae': 0.84,
            'payback_years': 1.8,
            'roi_percent': 198.52,
            'irr': 42.38,
            'profitability_k': 1.8
          }
        ],
        'winnerLabel': 'Aerator 2',
        'equilibriumPrices': {'Aerator 1': 399.40}
      };

      test('returns comparison results when API call is successful', () async {
        // Arrange
        when(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).thenAnswer(
            (_) async => http.Response(jsonEncode(testResponse), 200));

        // Act
        final result = await apiService.compareAerators(testInputs);

        // Assert
        expect(result, equals(testResponse));
        verify(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).called(1);
      });

      test('throws exception when API returns non-200 status code', () async {
        // Arrange
        when(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).thenAnswer((_) async => http.Response('Server error', 500));

        // Act & Assert
        expect(
          () => apiService.compareAerators(testInputs),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API returned status code 500'),
          )),
        );
      });

      test('throws exception when API returns error in response body',
          () async {
        // Arrange
        final errorResponse = {'error': 'Invalid inputs'};
        when(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).thenAnswer(
            (_) async => http.Response(jsonEncode(errorResponse), 200));

        // Act & Assert
        expect(
          () => apiService.compareAerators(testInputs),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API error: Invalid inputs'),
          )),
        );
      });

      test('throws exception when API response cannot be parsed', () async {
        // Arrange
        when(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).thenAnswer((_) async => http.Response('Not valid JSON', 200));

        // Act & Assert
        expect(
          () => apiService.compareAerators(testInputs),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to parse response'),
          )),
        );
      });

      test('throws exception when API call fails', () async {
        // Arrange
        when(mockClient.post(
          Uri.parse('$baseUrl/api/compare'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(testInputs),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => apiService.compareAerators(testInputs),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to compare aerators'),
          )),
        );
      });
    });
  });
}

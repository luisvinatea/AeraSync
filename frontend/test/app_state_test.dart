import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:aerasync/core/services/api_service.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mock API service
@GenerateMocks([ApiService])
import 'app_state_test.mocks.dart';

void main() {
  group('AppState', () {
    late MockApiService mockApiService;
    late AppState appState;

    setUp(() {
      mockApiService = MockApiService();
      SharedPreferences.setMockInitialValues({});
      appState = AppState(
        locale: const Locale('en'),
        apiService: mockApiService,
      );
    });

    group('initialization', () {
      test('initializes with default values', () {
        expect(appState.locale.languageCode, equals('en'));
        expect(appState.apiResults, isNull);
        expect(appState.error, isNull);
        expect(appState.isApiHealthy, isTrue);
        expect(appState.hasAgreedToDisclosure, isFalse);
        expect(appState.cookiesAccepted, isFalse);
      });
    });

    group('locale management', () {
      test('updates locale and notifies listeners', () async {
        // Arrange
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        appState.locale = const Locale('es');

        // Assert
        expect(appState.locale.languageCode, equals('es'));
        expect(listenerCalled, isTrue);

        // Verify locale preference is saved
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('locale'), equals('es'));
      });

      test('does not notify listeners when setting same locale', () {
        // Arrange
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        appState.locale = const Locale('en'); // Same as initial

        // Assert
        expect(listenerCalled, isFalse);
      });
    });

    group('disclosure preferences', () {
      test('updates disclosure agreement and notifies listeners', () async {
        // Arrange
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        appState.setDisclosureAgreed(true);

        // Assert
        expect(appState.hasAgreedToDisclosure, isTrue);
        expect(listenerCalled, isTrue);

        // Verify preference is saved
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('hasAgreedToDisclosure'), isTrue);
      });

      test('does not notify listeners when setting same disclosure value', () {
        // Arrange
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        appState.setDisclosureAgreed(false); // Same as initial

        // Assert
        expect(listenerCalled, isFalse);
      });
    });

    group('cookies preferences', () {
      test('updates cookies acceptance and notifies listeners', () async {
        // Arrange
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        appState.setCookiesAccepted(true);

        // Assert
        expect(appState.cookiesAccepted, isTrue);
        expect(listenerCalled, isTrue);

        // Verify preference is saved
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('cookiesAccepted'), isTrue);
      });
    });

    group('error handling', () {
      test('sets and clears error with notification', () {
        // Set error
        bool setErrorCalled = false;
        appState.addListener(() {
          setErrorCalled = true;
        });

        appState.setError('Test error');
        expect(appState.error, equals('Test error'));
        expect(setErrorCalled, isTrue);

        // Clear error
        setErrorCalled = false;
        appState.clearError();
        expect(appState.error, isNull);
        expect(setErrorCalled, isTrue);
      });

      test('does not notify when clearing already null error', () {
        // Error is initially null
        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        appState.clearError();
        expect(listenerCalled, isFalse);
      });
    });

    group('API health checks', () {
      test('checkApiHealth returns true when API is healthy', () async {
        // Arrange
        when(mockApiService.checkHealth()).thenAnswer((_) async => true);

        // Act
        final result = await appState.checkApiHealth();

        // Assert
        expect(result, isTrue);
        expect(appState.isApiHealthy, isTrue);
        verify(mockApiService.checkHealth()).called(1);
      });

      test('checkApiHealth returns false when API is not healthy', () async {
        // Arrange
        when(mockApiService.checkHealth()).thenAnswer((_) async => false);

        // Act
        final result = await appState.checkApiHealth();

        // Assert
        expect(result, isFalse);
        expect(appState.isApiHealthy, isFalse);
        verify(mockApiService.checkHealth()).called(1);
      });

      test('checkApiHealth handles exceptions', () async {
        // Arrange
        when(mockApiService.checkHealth())
            .thenThrow(Exception('Network error'));

        // Act
        final result = await appState.checkApiHealth();

        // Assert
        expect(result, isFalse);
        expect(appState.isApiHealthy, isFalse);
      });
    });

    group('compareAerators', () {
      final testInputs = {
        'tod': 5443.7675,
        'farm_area_ha': 1000,
        'financial': {
          'energy_cost': 0.05,
          'operating_hours': 2920,
        },
        'aerators': [
          {'name': 'Aerator 1', 'sotr': 1.4},
          {'name': 'Aerator 2', 'sotr': 2.2},
        ]
      };

      final testResults = {
        'winnerLabel': 'Aerator 2',
        'aeratorResults': [
          {'name': 'Aerator 1'},
          {'name': 'Aerator 2'},
        ]
      };

      test('successfully updates API results', () async {
        // Arrange
        when(mockApiService.compareAerators(testInputs))
            .thenAnswer((_) async => testResults);

        bool listenerCalled = false;
        appState.addListener(() {
          listenerCalled = true;
        });

        // Act
        await appState.compareAerators(testInputs);

        // Assert
        expect(appState.apiResults, equals(testResults));
        expect(appState.error, isNull);
        expect(listenerCalled, isTrue);
        verify(mockApiService.compareAerators(testInputs)).called(1);
      });

      test('handles network errors', () async {
        // Arrange
        when(mockApiService.compareAerators(testInputs))
            .thenThrow(Exception('SocketException'));

        // Act
        await appState.compareAerators(testInputs);

        // Assert
        expect(appState.apiResults, isNull);
        expect(appState.error, contains('internet connection'));
      });

      test('handles general errors', () async {
        // Arrange
        when(mockApiService.compareAerators(testInputs))
            .thenThrow(Exception('General error'));

        // Act
        await appState.compareAerators(testInputs);

        // Assert
        expect(appState.apiResults, isNull);
        expect(appState.error, contains('unexpected error'));
      });
    });

    test('resetResults clears results and errors', () {
      // Arrange
      appState.setError('Test error');

      bool listenerCalled = false;
      appState.addListener(() {
        listenerCalled = true;
      });

      // Act
      appState.resetResults();

      // Assert
      expect(appState.apiResults, isNull);
      expect(appState.error, isNull);
      expect(listenerCalled, isTrue);
    });
  });
}

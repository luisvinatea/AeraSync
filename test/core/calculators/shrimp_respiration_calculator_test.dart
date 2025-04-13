import 'dart:convert'; // Import needed for utf8
import 'dart:typed_data'; // Import needed for ByteData

import 'package:flutter/foundation.dart'; // For visibleForTesting
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart'; // Not used
import 'package:AeraSync/core/calculators/shrimp_respiration_calculator.dart'; // Adjust import path

// Mock class not used
// class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  late ShrimpRespirationCalculator calculator;
  // MockAssetBundle not used
  // late MockAssetBundle mockAssetBundle;

  // Ensure Flutter test bindings are initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // mockAssetBundle = MockAssetBundle(); // Not used
    calculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');

    // --- Updated Mocking using TestDefaultBinaryMessengerBinding ---
    final TestDefaultBinaryMessenger messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Set the mock handler for the specific asset loading channel/method
    messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
       final String assetKey = utf8.decode(message!.buffer.asUint8List());
       // print('Mock Asset Loader: Received request for $assetKey'); // Debugging line

       if (assetKey == 'assets/data/shrimp_respiration_salinity_temperature_weight.json') {
          // Return the mock JSON data as ByteData (UTF-8 encoded)
          final String mockJson = '''
          {
            "metadata": {
              "unit": "mg O2/g/h",
              "description": "Mock shrimp oxygen consumption",
              "salinity_values": ["1%", "13%", "25%", "37%"],
              "temperature_values": ["20°C", "25°C", "30°C"],
              "shrimp_biomass": ["5g", "10g", "15g", "20g"]
            },
            "data": {
              "1%": {
                "20°C": {"5g": 0.1, "10g": 0.2, "15g": 0.3, "20g": 0.4},
                "25°C": {"5g": 0.15, "10g": 0.25, "15g": 0.35, "20g": 0.45},
                "30°C": {"5g": 0.2, "10g": 0.3, "15g": 0.4, "20g": 0.5}
              },
              "13%": {
                "20°C": {"5g": 0.11, "10g": 0.21, "15g": 0.31, "20g": 0.41},
                "25°C": {"5g": 0.16, "10g": 0.26, "15g": 0.36, "20g": 0.46},
                "30°C": {"5g": 0.21, "10g": 0.31, "15g": 0.41, "20g": 0.51}
              },
              "25%": {
                "20°C": {"5g": 0.12, "10g": 0.22, "15g": 0.32, "20g": 0.42},
                "25°C": {"5g": 0.17, "10g": 0.27, "15g": 0.37, "20g": 0.47},
                "30°C": {"5g": 0.22, "10g": 0.32, "15g": 0.42, "20g": 0.52}
              },
              "37%": {
                "20°C": {"5g": 0.13, "10g": 0.23, "15g": 0.33, "20g": 0.43},
                "25°C": {"5g": 0.18, "10g": 0.28, "15g": 0.38, "20g": 0.48},
                "30°C": {"5g": 0.23, "10g": 0.33, "15g": 0.43, "20g": 0.53}
              }
            }
          }
          ''';
          return Future.value(utf8.encoder.convert(mockJson).buffer.asByteData());
       }
       return Future.value(null);
    });
  });

  // Clear the mock handler after each test
  tearDown(() {
     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
  });

  test('ShrimpRespirationCalculator loads data correctly', () async {
    // Action
    await calculator.loadData();

    // Assert: Use the public getters added for testing
    expect(calculator.salinityValuesForTest, [1.0, 13.0, 25.0, 37.0]);
    expect(calculator.temperatureValuesForTest, [20.0, 25.0, 30.0]);
    expect(calculator.biomassValuesForTest, [5.0, 10.0, 15.0, 20.0]);
    expect(calculator.respirationDataForTest, isNotNull);
  });

  test('ShrimpRespirationCalculator looks up exact grid point correctly', () async {
    await calculator.loadData();
    // Action
    final rate = calculator.getRespirationRate(13.0, 25.0, 10.0); // Exact grid point
    // Assert
    expect(rate, 0.26); // Value from mock data
  });

  test('ShrimpRespirationCalculator interpolates correctly between grid points', () async {
     await calculator.loadData();

     // Arrange: Values between grid points
     final salinity = 19.0;    // Between 13% and 25% -> s = 0.5
     final temperature = 27.0; // Between 25°C and 30°C -> t = 0.4
     final weight = 12.5;      // Between 10g and 15g -> w = 0.5

     // Expected value calculated manually from mock data (see previous review)
     final double expectedRate = 0.335;

     // Action
     final calculatedRate = calculator.getRespirationRate(salinity, temperature, weight);

     // Assert
     expect(calculatedRate, closeTo(expectedRate, 0.0001));
  });

  test('ShrimpRespirationCalculator clamps values outside range', () async {
    await calculator.loadData();
    // Action: Values outside range
    final rate = calculator.getRespirationRate(50.0, 40.0, 30.0);
    // Assert: Should clamp to max values (S=37, T=30, W=20)
    expect(rate, 0.53); // Value from mock_data["37%"]["30°C"]["20g"]
  });

  test('ShrimpRespirationCalculator handles values at boundaries', () async {
     await calculator.loadData();

     // Test lower boundary
     final rateLower = calculator.getRespirationRate(1.0, 20.0, 5.0);
     expect(rateLower, 0.1); // Exact value from mock_data["1%"]["20°C"]["5g"]

     // Test upper boundary
     final rateUpper = calculator.getRespirationRate(37.0, 30.0, 20.0);
     expect(rateUpper, 0.53); // Exact value from mock_data["37%"]["30°C"]["20g"]
  });

}

// Removed the problematic extension accessing private members
// extension ShrimpRespirationCalculatorTestAccess on ShrimpRespirationCalculator {
//   List<double> get salinityValuesForTest => _salinityValues; // Error: Getter not defined
//   // ... other errors ...
// }

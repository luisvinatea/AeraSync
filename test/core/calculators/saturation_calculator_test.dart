import 'dart:convert'; // Import needed for utf8
import 'dart:typed_data'; // Import needed for ByteData

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Mockito not used currently
// import 'package:mockito/mockito.dart';
import 'package:AeraSync/core/calculators/saturation_calculator.dart'; // Adjust import path if necessary

void main() {
  late ShrimpPondCalculator calculator;

  // Use TestWidgetsFlutterBinding or TestDefaultBinaryMessengerBinding for mocking
  TestWidgetsFlutterBinding.ensureInitialized(); // Recommended for most tests needing services

  setUp(() {
    // Initialize the calculator before each test
    calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');

    // --- Updated Mocking using TestDefaultBinaryMessengerBinding ---
    // Get the test messenger instance
    final TestDefaultBinaryMessenger messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Set the mock handler for the specific asset loading channel/method
    messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
       // Decode the message to get the asset key
       final String assetKey = utf8.decode(message!.buffer.asUint8List());
       // print('Mock Asset Loader: Received request for $assetKey'); // Debugging line

       if (assetKey == 'assets/data/o2_temp_sal_100_sat.json') {
          // Return the mock JSON data as ByteData (UTF-8 encoded)
          final String mockJson = '''
          {
            "metadata": {
              "temperature_range": {"min": 0, "max": 40, "step": 1.0},
              "salinity_range": {"min": 0, "max": 35, "step": 5.0},
              "unit": "mg/L"
            },
            "data": [
              [14.6, 14.1, 13.6, 13.2, 12.7, 12.3, 11.9, 11.5],
              [14.2, 13.7, 13.2, 12.8, 12.4, 11.9, 11.5, 11.2],
              [13.8, 13.3, 12.9, 12.4, 12.0, 11.6, 11.2, 10.9],
              [13.4, 13.0, 12.5, 12.1, 11.7, 11.3, 11.0, 10.6],
              [13.0, 12.6, 12.2, 11.8, 11.4, 11.0, 10.7, 10.3],
              [12.7, 12.3, 11.9, 11.5, 11.1, 10.8, 10.4, 10.1],
              [12.4, 12.0, 11.6, 11.2, 10.9, 10.5, 10.2, 9.8],
              [12.1, 11.7, 11.3, 11.0, 10.6, 10.3, 9.9, 9.6],
              [11.8, 11.4, 11.0, 10.7, 10.4, 10.0, 9.7, 9.4],
              [11.5, 11.1, 10.8, 10.4, 10.1, 9.8, 9.5, 9.2],
              [11.2, 10.9, 10.5, 10.2, 9.9, 9.6, 9.3, 9.0],
              [11.0, 10.6, 10.3, 10.0, 9.7, 9.4, 9.1, 8.8],
              [10.7, 10.4, 10.1, 9.8, 9.5, 9.2, 8.9, 8.6],
              [10.5, 10.2, 9.8, 9.5, 9.2, 9.0, 8.7, 8.4],
              [10.2, 9.9, 9.6, 9.3, 9.1, 8.8, 8.5, 8.2],
              [10.0, 9.7, 9.4, 9.1, 8.9, 8.6, 8.3, 8.1],
              [9.8, 9.5, 9.2, 9.0, 8.7, 8.4, 8.1, 7.9],
              [9.6, 9.3, 9.0, 8.8, 8.5, 8.3, 8.0, 7.8],
              [9.4, 9.1, 8.9, 8.6, 8.3, 8.1, 7.9, 7.6],
              [9.2, 8.9, 8.7, 8.4, 8.2, 7.9, 7.7, 7.5],
              [9.0, 8.8, 8.5, 8.3, 8.0, 7.8, 7.6, 7.3],
              [8.9, 8.6, 8.3, 8.1, 7.9, 7.6, 7.4, 7.2],
              [8.7, 8.4, 8.2, 8.0, 7.7, 7.5, 7.3, 7.1],
              [8.5, 8.3, 8.0, 7.8, 7.6, 7.4, 7.2, 6.9],
              [8.4, 8.1, 7.9, 7.7, 7.4, 7.2, 7.0, 6.8],
              [8.2, 8.0, 7.7, 7.5, 7.3, 7.1, 6.9, 6.7],
              [8.0, 7.8, 7.6, 7.4, 7.2, 7.0, 6.8, 6.6],
              [7.9, 7.7, 7.5, 7.3, 7.1, 6.9, 6.7, 6.5],
              [7.8, 7.5, 7.3, 7.1, 6.9, 6.7, 6.6, 6.4],
              [7.6, 7.4, 7.2, 7.0, 6.8, 6.6, 6.5, 6.3],
              [7.5, 7.3, 7.1, 6.9, 6.7, 6.5, 6.3, 6.0],
              [7.4, 7.2, 7.0, 6.8, 6.6, 6.4, 6.2, 5.9],
              [7.2, 7.0, 6.9, 6.7, 6.5, 6.3, 6.1, 5.8],
              [7.1, 6.9, 6.7, 6.6, 6.4, 6.2, 6.1, 5.7],
              [7.0, 6.8, 6.6, 6.5, 6.3, 6.1, 6.0, 5.6],
              [6.9, 6.7, 6.5, 6.4, 6.2, 6.0, 5.9, 5.5],
              [6.8, 6.6, 6.4, 6.3, 6.1, 5.9, 5.8, 5.4],
              [6.7, 6.5, 6.3, 6.2, 6.0, 5.8, 5.7, 5.3],
              [6.6, 6.4, 6.2, 6.1, 5.9, 5.7, 5.6, 5.2],
              [6.5, 6.3, 6.1, 6.0, 5.8, 5.6, 5.5, 5.1],
              [6.4, 6.2, 6.0, 5.9, 5.7, 5.5, 5.4, 5.0]
            ]
          }
          ''';
          return Future.value(utf8.encoder.convert(mockJson).buffer.asByteData());
       }
       // Handle other asset requests if necessary, otherwise return null
       return Future.value(null);
    });
  });

  // Clear the mock handler after each test
  tearDown(() {
     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
  });


  test('ShrimpPondCalculator getO2Saturation returns correct values from mock data', () async {
    // Load data using the mocked loader
    await calculator.loadData();
    // Test case: Temp = 20.0, Salinity = 10.0
    // Temp index = round(20.0) = 20
    // Salinity index = floor(10.0 / 5.0) = 2
    // Expected value from mock data matrix[20][2] = 8.5
    final saturation = calculator.getO2Saturation(20.0, 10.0);

    // *** CORRECTED ASSERTION based on mock data ***
    expect(saturation, 8.5);
  });

  test('ShrimpPondCalculator calculateMetrics computes correct values based on mock data', () async {
    await calculator.loadData();
    final metrics = calculator.calculateMetrics(
      temperature: 20.0,
      salinity: 10.0, // Cs should be 8.5 based on mock data
      horsepower: 2.0,
      volume: 1000.0,
      t10: 10.0, // Not used in calculation, reference only
      t70: 20.0, // Time in minutes
      kWhPrice: 0.1,
      aeratorId: 'Pentair Paddlewheel',
    );

    // *** CORRECTED ASSERTION based on mock data ***
    expect(metrics['Cs (mg/L)'], 8.5); // Cs at T=20, Sal=10

    // Check other values (Recalculated based on Cs=8.5)
    expect(metrics['Power (kW)'], 1.49);
    expect(metrics['Cs20 (mg/L)'], 8.5);

    // Expected KLaT = -ln(0.3) / (t70_minutes / 60) = -ln(0.3) / (20/60) = 1.20397 / 0.3333... = 3.6119...
    // Expected KLa20 = KLaT * (1.024 ^ (20 - T)) = 3.6119 * (1.024 ^ (20 - 20)) = 3.6119...
    // Expected SOTR = KLa20 * Cs20_kg_m3 * Volume = 3.6119 * (8.5 * 0.001) * 1000 = 30.701... -> rounded 30.70
    // Expected SAE = SOTR / Power = 30.70 / 1.49 = 20.604... -> rounded 20.60
    // Expected Cost/kg = kWhPrice / SAE = 0.1 / 20.60 = 0.00485... -> rounded 0.00
    expect(metrics['KlaT (h⁻¹)'], closeTo(3.61, 0.01));
    expect(metrics['Kla20 (h⁻¹)'], closeTo(3.61, 0.01));
    expect(metrics['SOTR (kg O₂/h)'], closeTo(30.70, 0.01));
    expect(metrics['SAE (kg O₂/kWh)'], closeTo(20.60, 0.01));
    expect(metrics['Cost per kg O₂ (USD/kg O₂)'], closeTo(0.00, 0.01)); // Corrected expected cost
    expect(metrics['Annual Energy Cost (USD/year)'], closeTo(1305.24, 0.01));
  });

  test('ShrimpPondCalculator calculateMetrics handles zero horsepower', () async {
    await calculator.loadData();
    final metrics = calculator.calculateMetrics(
      temperature: 20.0,
      salinity: 10.0,
      horsepower: 0.0, // Zero HP
      volume: 1000.0,
      t10: 10.0,
      t70: 20.0,
      kWhPrice: 0.1,
      aeratorId: 'Pentair Paddlewheel',
    );
    expect(metrics['Power (kW)'], 0.0);
    expect(metrics['SAE (kg O₂/kWh)'], 0.0);
    expect(metrics['Cost per kg O₂ (USD/kg O₂)'], double.infinity);
    expect(metrics['Annual Energy Cost (USD/year)'], 0.0);
  });

   test('ShrimpPondCalculator calculateMetrics handles invalid T70', () async {
     await calculator.loadData();
     // Test case where t70 is <= 0
     expect(
       () => calculator.calculateMetrics(
         temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
         t10: 10.0, t70: 0.0, kWhPrice: 0.1, aeratorId: 'Test'
       ),
       // The calculator class throws ArgumentError for t70 <= 0
       throwsArgumentError
     );
     // Test case where t70 <= t10 (though t10 isn't used in KLa calc directly)
     // The calculator class should ideally check t70 > 0, not t70 > t10
     // Let's keep the check for t70 > 0 as primary
   });


  test('ShrimpPondCalculator brand normalization works', () async {
    await calculator.loadData();
    // Test various normalization cases
    var metrics = calculator.calculateMetrics(
      temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
      t10: 10.0, t70: 20.0, kWhPrice: 0.1, aeratorId: 'maof-madam Paddlewheel',
    );
    // Check the calculator's normalization logic output
    expect(metrics['Normalized Aerator ID'], 'Maof Madam Paddlewheel');

    metrics = calculator.calculateMetrics(
      temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
      t10: 10.0, t70: 20.0, kWhPrice: 0.1, aeratorId: ' PENTAIR  Splash ', // Test trimming and case
    );
    expect(metrics['Normalized Aerator ID'], 'Pentair Splash');

     metrics = calculator.calculateMetrics(
      temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
      t10: 10.0, t70: 20.0, kWhPrice: 0.1, aeratorId: 'UnknownBrand TypeX', // Test unknown brand
    );
     // The calculator should title-case unknown brands
    expect(metrics['Normalized Aerator ID'], 'Unknownbrand TypeX');

     metrics = calculator.calculateMetrics(
      temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
      t10: 10.0, t70: 20.0, kWhPrice: 0.1, aeratorId: 'generic', // Test generic keyword
    );
    // Check calculator logic: generic brand + unknown type
    expect(metrics['Normalized Aerator ID'], 'Generic Unknown');

     metrics = calculator.calculateMetrics(
      temperature: 20.0, salinity: 10.0, horsepower: 2.0, volume: 1000.0,
      t10: 10.0, t70: 20.0, kWhPrice: 0.1, aeratorId: '', // Test empty ID
    );
     // Check calculator logic: empty brand + unknown type
    expect(metrics['Normalized Aerator ID'], 'Generic Unknown');
  });
}


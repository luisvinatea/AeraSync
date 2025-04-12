import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:AeraSync/core/calculators/shrimp_respiration_calculator.dart';

// Create a mock class for the rootBundle
class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  late ShrimpRespirationCalculator calculator;
  late MockAssetBundle mockAssetBundle;

  setUp(() {
    mockAssetBundle = MockAssetBundle();
    calculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');

    // Mock the rootBundle globally for the test
    const MethodChannel('flutter/platform', JSONMethodCodec())
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'loadString') {
        return '''
        {
          "metadata": {
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
      }
      return null;
    });
  });

  test('ShrimpRespirationCalculator loads data correctly', () async {
    await calculator.loadData();
    expect(calculator._salinityValues, [1.0, 13.0, 25.0, 37.0]);
    expect(calculator._temperatureValues, [20.0, 25.0, 30.0]);
    expect(calculator._biomassValues, [5.0, 10.0, 15.0, 20.0]);
  });

  test('ShrimpRespirationCalculator interpolates respiration rate correctly', () async {
    await calculator.loadData();
    final rate = calculator.getRespirationRate(13.0, 25.0, 10.0);
    expect(rate, 0.26); // Expected value based on the mock data
  });

  test('ShrimpRespirationCalculator clamps values outside range', () async {
    await calculator.loadData();
    final rate = calculator.getRespirationRate(50.0, 40.0, 30.0);
    // Should clamp to max values: salinity 37%, temp 30°C, weight 20g
    expect(rate, 0.53);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:aerasync/core/calculators/shrimp_respiration_calculator.dart';

void main() {
  group('ShrimpRespirationCalculator', () {
    late ShrimpRespirationCalculator calculator;

    setUp(() async {
      calculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');
      await calculator.loadData();
    });

    test('loads data correctly', () async {
      expect(calculator, isNotNull);
      // Verify some data points
      final rate = calculator.getRespirationRate(25, 30, 15);
      expect(rate, 0.320); // Exact match from JSON
    });

    test('interpolates respiration rate correctly', () async {
      // Test interpolation at salinity 19%, temperature 27.5°C, weight 12.5g
      final rate = calculator.getRespirationRate(19, 27.5, 12.5);
      expect(rate, closeTo(0.288875, 0.0001)); // From manual calculation
    });

    test('clamps values outside range', () async {
      // Test with values outside the range
      final rate = calculator.getRespirationRate(50, 40, 30);
      // Should clamp to 37%, 30°C, 20g
      expect(rate, 0.293); // From JSON at 37%, 30°C, 20g
    });
  });
}
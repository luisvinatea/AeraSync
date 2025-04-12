import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:AeraSync/core/calculators/saturation_calculator.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  late ShrimpPondCalculator calculator;
  late MockAssetBundle mockAssetBundle;

  setUp(() {
    mockAssetBundle = MockAssetBundle();
    calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');

    const MethodChannel('flutter/platform', JSONMethodCodec())
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'loadString') {
        return '''
        {
          "metadata": {
            "temperature_range": {"step": 1.0},
            "salinity_range": {"step": 5.0}
          },
          "data": [
            [8.0, 7.8, 7.6, 7.4, 7.2, 7.0, 6.8, 6.6],
            [7.9, 7.7, 7.5, 7.3, 7.1, 6.9, 6.7, 6.5],
            [7.8, 7.6, 7.4, 7.2, 7.0, 6.8, 6.6, 6.4],
            [7.7, 7.5, 7.3, 7.1, 6.9, 6.7, 6.5, 6.3],
            [7.6, 7.4, 7.2, 7.0, 6.8, 6.6, 6.4, 6.2],
            [7.5, 7.3, 7.1, 6.9, 6.7, 6.5, 6.3, 6.1],
            [7.4, 7.2, 7.0, 6.8, 6.6, 6.4, 6.2, 6.0],
            [7.3, 7.1, 6.9, 6.7, 6.5, 6.3, 6.1, 5.9],
            [7.2, 7.0, 6.8, 6.6, 6.4, 6.2, 6.0, 5.8],
            [7.1, 6.9, 6.7, 6.5, 6.3, 6.1, 5.9, 5.7],
            [7.0, 6.8, 6.6, 6.4, 6.2, 6.0, 5.8, 5.6],
            [6.9, 6.7, 6.5, 6.3, 6.1, 5.9, 5.7, 5.5],
            [6.8, 6.6, 6.4, 6.2, 6.0, 5.8, 5.6, 5.4],
            [6.7, 6.5, 6.3, 6.1, 5.9, 5.7, 5.5, 5.3],
            [6.6, 6.4, 6.2, 6.0, 5.8, 5.6, 5.4, 5.2],
            [6.5, 6.3, 6.1, 5.9, 5.7, 5.5, 5.3, 5.1],
            [6.4, 6.2, 6.0, 5.8, 5.6, 5.4, 5.2, 5.0],
            [6.3, 6.1, 5.9, 5.7, 5.5, 5.3, 5.1, 4.9],
            [6.2, 6.0, 5.8, 5.6, 5.4, 5.2, 5.0, 4.8],
            [6.1, 5.9, 5.7, 5.5, 5.3, 5.1, 4.9, 4.7],
            [6.0, 5.8, 5.6, 5.4, 5.2, 5.0, 4.8, 4.6],
            [5.9, 5.7, 5.5, 5.3, 5.1, 4.9, 4.7, 4.5],
            [5.8, 5.6, 5.4, 5.2, 5.0, 4.8, 4.6, 4.4],
            [5.7, 5.5, 5.3, 5.1, 4.9, 4.7, 4.5, 4.3],
            [5.6, 5.4, 5.2, 5.0, 4.8, 4.6, 4.4, 4.2],
            [5.5, 5.3, 5.1, 4.9, 4.7, 4.5, 4.3, 4.1],
            [5.4, 5.2, 5.0, 4.8, 4.6, 4.4, 4.2, 4.0],
            [5.3, 5.1, 4.9, 4.7, 4.5, 4.3, 4.1, 3.9],
            [5.2, 5.0, 4.8, 4.6, 4.4, 4.2, 4.0, 3.8],
            [5.1, 4.9, 4.7, 4.5, 4.3, 4.1, 3.9, 3.7],
            [5.0, 4.8, 4.6, 4.4, 4.2, 4.0, 3.8, 3.6],
            [4.9, 4.7, 4.5, 4.3, 4.1, 3.9, 3.7, 3.5],
            [4.8, 4.6, 4.4, 4.2, 4.0, 3.8, 3.6, 3.4],
            [4.7, 4.5, 4.3, 4.1, 3.9, 3.7, 3.5, 3.3],
            [4.6, 4.4, 4.2, 4.0, 3.8, 3.6, 3.4, 3.2],
            [4.5, 4.3, 4.1, 3.9, 3.7, 3.5, 3.3, 3.1],
            [4.4, 4.2, 4.0, 3.8, 3.6, 3.4, 3.2, 3.0],
            [4.3, 4.1, 3.9, 3.7, 3.5, 3.3, 3.1, 2.9],
            [4.2, 4.0, 3.8, 3.6, 3.4, 3.2, 3.0, 2.8],
            [4.1, 3.9, 3.7, 3.5, 3.3, 3.1, 2.9, 2.7],
            [4.0, 3.8, 3.6, 3.4, 3.2, 3.0, 2.8, 2.6]
          ]
        }
        ''';
      }
      return null;
    });
  });

  test('ShrimpPondCalculator getO2Saturation returns correct values from mock data', () async {
    await calculator.loadData();
    final saturation = calculator.getO2Saturation(20.0, 10.0);
    expect(saturation, 6.0); // Based on mock data: temp=20, salinity=10 (index 2)
  });

  test('ShrimpPondCalculator calculateMetrics computes correct values based on mock data', () async {
    await calculator.loadData();
    final metrics = calculator.calculateMetrics(
      temperature: 20.0,
      salinity: 10.0,
      horsepower: 2.0,
      volume: 1000.0,
      t10: 10.0,
      t70: 20.0,
      kWhPrice: 0.1,
      aeratorId: 'Pentair Paddlewheel',
    );
    expect(metrics['Cs (mg/L)'], 6.0); // Based on mock data
    expect(metrics['Power (kW)'], 1.49); // 2.0 * 0.746 rounded
  });

  test('ShrimpPondCalculator calculateMetrics handles zero horsepower', () async {
    await calculator.loadData();
    final metrics = calculator.calculateMetrics(
      temperature: 20.0,
      salinity: 10.0,
      horsepower: 0.0,
      volume: 1000.0,
      t10: 10.0,
      t70: 20.0,
      kWhPrice: 0.1,
      aeratorId: 'Pentair Paddlewheel',
    );
    expect(metrics['SAE (kg O₂/kWh)'], 0.0); // Should handle zero horsepower
  });

  test('ShrimpPondCalculator brand normalization works', () async {
    await calculator.loadData();
    final metrics = calculator.calculateMetrics(
      temperature: 20.0,
      salinity: 10.0,
      horsepower: 2.0,
      volume: 1000.0,
      t10: 10.0,
      t70: 20.0,
      kWhPrice: 0.1,
      aeratorId: 'maof-madam Paddlewheel',
    );
    expect(metrics['Normalized Aerator ID'], 'Maof Madam Paddlewheel');
  });
}
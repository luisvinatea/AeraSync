import 'package:AeraSync/core/calculators/saturation_calculator.dart';
import 'calculator_service_platform.dart';

class CalculatorServiceWeb implements CalculatorServicePlatform {
  late SaturationCalculator calculator;

  @override
  Future<void> initialize() async {
    calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
    await calculator.loadData();
  }

  @override
  double getO2Saturation(double temperature, double salinity) {
    return calculator.getO2Saturation(temperature, salinity);
  }

  @override
  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10,
    required double t70,
    required double kWhPrice,
    required String aeratorId,
  }) {
    return calculator.calculateMetrics(
      temperature: temperature,
      salinity: salinity,
      horsepower: horsepower,
      volume: volume,
      t10: t10,
      t70: t70,
      kWhPrice: kWhPrice,
      aeratorId: aeratorId,
    );
  }
}
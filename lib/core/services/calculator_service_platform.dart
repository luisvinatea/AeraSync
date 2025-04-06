import 'package:AeraSync/core/calculators/saturation_calculator.dart';

abstract class CalculatorServicePlatform {
  Future<void> initialize();

  double getO2Saturation(double temperature, double salinity);

  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10,
    required double t70,
    required double kWhPrice,
    required String aeratorId,
  });
}
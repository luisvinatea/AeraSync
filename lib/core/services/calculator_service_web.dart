import 'package:aerasync/core/services/aerator_calculator.dart';
import 'calculator_service_platform.dart';

class CalculatorServiceWeb implements CalculatorServicePlatform {
  late AeratorCalculator _calculator;
  final Map<String, double> _o2SaturationCache = {};

  CalculatorServiceWeb() {
    _calculator = AeratorCalculator();
  }

  @override
  Future<void> initialize() async {
    // No initialization required for AeratorCalculator
  }

  @override
  double getO2Saturation(double temperature, double salinity) {
    // Create a cache key based on temperature and salinity
    final cacheKey = '${temperature.toStringAsFixed(1)}-${salinity.toStringAsFixed(1)}';
    
    // Return cached result if available
    if (_o2SaturationCache.containsKey(cacheKey)) {
      return _o2SaturationCache[cacheKey]!;
    }

    // Calculate and cache the result
    final result = _calculator.getO2Saturation(temperature, salinity);
    _o2SaturationCache[cacheKey] = result;
    return result;
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
    return _calculator.calculateMetrics(
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
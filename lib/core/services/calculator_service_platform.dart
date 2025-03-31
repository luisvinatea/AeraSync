import '../calculators/saturation_calculator.dart';
import 'calculator_service.dart';

abstract class CalculatorServicePlatform {
  Future<ShrimpPondCalculator> initialize();

  static CalculatorServicePlatform get instance => _instance;
  static final CalculatorServicePlatform _instance = CalculatorServicePlatformImpl();
}

class CalculatorServicePlatformImpl implements CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    return CalculatorService().initialize();
  }
}
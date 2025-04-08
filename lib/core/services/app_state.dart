import 'package:flutter/foundation.dart';
import '../calculators/saturation_calculator.dart';
import '../calculators/shrimp_respiration_calculator.dart';

class AppState with ChangeNotifier {
  SaturationCalculator? _calculator;
  ShrimpRespirationCalculator? _respirationCalculator;
  String? _error;
  bool _isLoading = false; // Add loading state
  Map<String, Map<String, dynamic>> _results = {};
  Map<String, Map<String, dynamic>> _inputs = {};

  AppState() {
    _calculator = SaturationCalculator('assets/data/o2_temp_sal_100_sat.json');
    _respirationCalculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');
    Future.wait([
      _calculator!.loadData(),
      _respirationCalculator!.loadData(),
    ]);
  }

  SaturationCalculator? get calculator => _calculator;
  ShrimpRespirationCalculator? get respirationCalculator => _respirationCalculator;
  String? get error => _error;
  bool get isLoading => _isLoading; // Add getter for isLoading
  Map<String, Map<String, dynamic>> get results => _results;
  Map<String, Map<String, dynamic>> get inputs => _inputs;

  void setError(String error) {
    _error = error;
    _isLoading = false; // Reset loading state on error
    notifyListeners();
  }

  void setLoading(bool loading) { // Add setLoading method
    _isLoading = loading;
    notifyListeners();
  }

  void setResults(String calculatorType, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    _results[calculatorType] = results;
    _inputs[calculatorType] = inputs;
    _error = null;
    _isLoading = false; // Reset loading state on success
    notifyListeners();
  }
}
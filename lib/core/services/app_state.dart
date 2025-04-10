import 'package:flutter/foundation.dart';
import '../calculators/saturation_calculator.dart';
import '../calculators/shrimp_respiration_calculator.dart';

class AppState with ChangeNotifier {
  SaturationCalculator? _calculator;
  ShrimpRespirationCalculator? _respirationCalculator;
  String? _error;
  bool _isLoading = false;
  final Map<String, Map<String, dynamic>> _results = {};
  final Map<String, Map<String, dynamic>> _inputs = {};

  AppState() {
    // Initialize calculators
    _calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
    _respirationCalculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');
  }

  // Initialize calculators asynchronously
  Future<void> initialize() async {
    setLoading(true);
    try {
      await Future.wait([
        _calculator!.loadData(),
        _respirationCalculator!.loadData(),
      ]);
    } catch (e) {
      setError('Failed to load calculator data: $e');
    } finally {
      setLoading(false);
    }
  }

  SaturationCalculator? get calculator => _calculator;
  ShrimpRespirationCalculator? get respirationCalculator => _respirationCalculator;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? getResults(String tab) => _results[tab];
  Map<String, dynamic>? getInputs(String tab) => _inputs[tab];

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setResults(String calculatorType, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    _results[calculatorType] = results;
    _inputs[calculatorType] = inputs;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _calculator = null;
    _respirationCalculator = null;
    _results.clear();
    _inputs.clear();
    super.dispose();
  }
}
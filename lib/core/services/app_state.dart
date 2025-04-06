import 'package:flutter/foundation.dart';
import '../calculators/saturation_calculator.dart';

class AppState extends ChangeNotifier {
  ShrimpPondCalculator? _calculator;
  bool _isLoading = true;
  String? _error;
  Map<String, Map<String, dynamic>> _results = {};
  Map<String, Map<String, dynamic>> _inputs = {};

  ShrimpPondCalculator? get calculator => _calculator;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? getResults(String tab) => _results[tab];
  Map<String, dynamic>? getInputs(String tab) => _inputs[tab];

  AppState() {
    _init();
  }

  Future<void> _init() async {
    try {
      _isLoading = true;
      _calculator = ShrimpPondCalculator('assets/data/o2_saturation.json');
      await _calculator!.loadData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setResults(String tab, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    _results[tab] = results;
    _inputs[tab] = inputs;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }
}
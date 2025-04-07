import 'package:flutter/material.dart';
import '../calculators/saturation_calculator.dart';

class AppState with ChangeNotifier {
  Map<String, dynamic> _saturationResults = {};
  Map<String, dynamic> _saturationInputs = {};
  Map<String, dynamic> _estimationResults = {};
  Map<String, dynamic> _estimationInputs = {};
  Map<String, dynamic> _comparisonResults = {};
  Map<String, dynamic> _comparisonInputs = {};

  bool _isLoading = false;
  String? _error;
  SaturationCalculator? _calculator;

  Map<String, dynamic> get saturationResults => _saturationResults;
  Map<String, dynamic> get estimationResults => _estimationResults;
  Map<String, dynamic> get comparisonResults => _comparisonResults;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SaturationCalculator? get calculator => _calculator;

  AppState() {
    _initializeCalculator();
  }

  Future<void> _initializeCalculator() async {
    _calculator = ShrimpPondCalculator('assets/data/saturation_data.json');
    try {
      await _calculator!.loadData();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize calculator: $e';
      notifyListeners();
    }
  }

  Map<String, dynamic>? getResults(String tab) {
    switch (tab) {
      case 'Aerator Performance':
        return _saturationResults;
      case 'Aerator Estimation':
        return _estimationResults;
      case 'Aerator Comparison':
        return _comparisonResults;
      default:
        return null;
    }
  }

  Map<String, dynamic>? getInputs(String tab) {
    switch (tab) {
      case 'Aerator Performance':
        return _saturationInputs;
      case 'Aerator Estimation':
        return _estimationInputs;
      case 'Aerator Comparison':
        return _comparisonInputs;
      default:
        return null;
    }
  }

  void setResults(String tab, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    switch (tab) {
      case 'Aerator Performance':
        _saturationResults = results;
        _saturationInputs = inputs;
        break;
      case 'Aerator Estimation':
        _estimationResults = results;
        _estimationInputs = inputs;
        break;
      case 'Aerator Comparison':
        _comparisonResults = results;
        _comparisonInputs = inputs;
        break;
    }
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void resetState() {
    _saturationResults = {};
    _saturationInputs = {};
    _estimationResults = {};
    _estimationInputs = {};
    _comparisonResults = {};
    _comparisonInputs = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import 'calculator_service.dart';

class AppState extends ChangeNotifier {
  final CalculatorService calculator;
  bool _isLoading = false;
  String? _error;
  Map<String, Map<String, dynamic>> _results = {};
  Map<String, Map<String, dynamic>> _inputs = {};

  AppState({required this.calculator});

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? getResults(String tab) => _results[tab];
  Map<String, dynamic>? getInputs(String tab) => _inputs[tab];

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void setResults(String tab, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    _results[tab] = results;
    _inputs[tab] = inputs;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Add a method to reset the state when switching tabs
  void resetState() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
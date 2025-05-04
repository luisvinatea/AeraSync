import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:math';

class AppState extends ChangeNotifier {
  // Static GlobalKey for navigation
  static final navigatorKey = GlobalKey<NavigatorState>();

  // API service
  final ApiService _apiService;

  // State variables
  Map<String, dynamic>? _apiResults;
  bool _resultsAvailable = false;
  Locale _locale;
  String? _error;
  bool _isApiHealthy = true;
  bool _hasAgreedToDisclosure = false;
  bool _cookiesAccepted = false;

  // Constructor
  AppState({required Locale locale, ApiService? apiService})
      : _locale = locale,
        _apiService = apiService ?? ApiService() {
    _loadPreferences();
  }

  // Getters
  Map<String, dynamic>? get apiResults => _apiResults;
  bool get resultsAvailable => _resultsAvailable;
  Locale get locale => _locale;
  String? get error => _error;
  bool get isApiHealthy => _isApiHealthy;
  bool get hasAgreedToDisclosure => _hasAgreedToDisclosure;
  bool get cookiesAccepted => _cookiesAccepted;

  // Locale management
  set locale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      _saveLocalePreference(newLocale.languageCode);
      notifyListeners();
    }
  }

  Future<void> _saveLocalePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', languageCode);
    } catch (e) {
      // Handle silently
    }
  }

  // Preferences management
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasAgreedToDisclosure = prefs.getBool('hasAgreedToDisclosure') ?? false;
      _cookiesAccepted = prefs.getBool('cookiesAccepted') ?? false;
      notifyListeners();
    } catch (e) {
      _hasAgreedToDisclosure = false;
      _cookiesAccepted = false;
      notifyListeners();
    }
  }

  void setDisclosureAgreed(bool value) {
    if (_hasAgreedToDisclosure != value) {
      _hasAgreedToDisclosure = value;
      _saveDisclosurePreference(value);
      notifyListeners();
    }
  }

  void setCookiesAccepted(bool value) {
    if (_cookiesAccepted != value) {
      _cookiesAccepted = value;
      _saveCookiesPreference(value);
      notifyListeners();
    }
  }

  Future<void> _saveDisclosurePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasAgreedToDisclosure', value);
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _saveCookiesPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cookiesAccepted', value);
    } catch (e) {
      // Handle silently
    }
  }

  // Error handling
  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // API health
  void setApiHealth(bool value) {
    if (_isApiHealthy != value) {
      _isApiHealthy = value;
      notifyListeners();
    }
  }

  Future<bool> checkApiHealth() async {
    try {
      _isApiHealthy = await _apiService.checkHealth();
      notifyListeners();
      return _isApiHealthy;
    } catch (e) {
      _isApiHealthy = false;
      notifyListeners();
      return false;
    }
  }

  // Reset results
  void resetResults() {
    _apiResults = null;
    clearError();
    notifyListeners();
  }

  void setApiResults(Map<String, dynamic> results) {
    _apiResults = results;
    _resultsAvailable = true;
    notifyListeners();

    // Navigate to results page automatically
    _navigateToResults();
  }

  void clearResults() {
    _apiResults = null;
    _resultsAvailable = false;
    notifyListeners();
  }

  // Navigate to results page
  void _navigateToResults() {
    if (_resultsAvailable && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushReplacementNamed('/results');
    }
  }

  // Navigate to survey page
  void navigateToSurvey() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushReplacementNamed('/survey');
    }
  }

  // Compare aerators
  Future<void> compareAerators(Map<String, dynamic> surveyData) async {
    clearError();
    try {
      final normalizedData = _normalizeData(surveyData);
      _apiResults = await _apiService.compareAerators(normalizedData);
      _resultsAvailable = true;
      notifyListeners();

      // Navigate to results page automatically
      _navigateToResults();
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        setError(
            'Failed to connect to the server. Please check your internet connection and try again.');
      } else {
        setError('An unexpected error occurred: $e');
      }
    }
  }

  // Normalize data to match expected API format
  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    // Ensure all values are properly converted to the expected types
    final Map<String, dynamic> normalizedData = {
      'farm': {
        'tod': _ensurePositiveDouble(data['farm']['tod']),
        'farm_area_ha': _ensurePositiveDouble(data['farm']['farm_area_ha']),
        'shrimp_price': _ensurePositiveDouble(data['farm']['shrimp_price']),
        'culture_days': _ensurePositiveDouble(data['farm']['culture_days']),
        'shrimp_density_kg_m3':
            _ensurePositiveDouble(data['farm']['shrimp_density_kg_m3']),
        'pond_depth_m': _ensurePositiveDouble(data['farm']['pond_depth_m']),
      },
      'financial': {
        'energy_cost': _ensurePositiveDouble(data['financial']['energy_cost']),
        'hours_per_night':
            _ensurePositiveDouble(data['financial']['hours_per_night']),
        'discount_rate':
            _ensurePositiveDouble(data['financial']['discount_rate']),
        'inflation_rate':
            _ensurePositiveDouble(data['financial']['inflation_rate']),
        'horizon': _ensurePositiveInt(data['financial']['horizon']),
        'safety_margin':
            _ensureNonNegativeDouble(data['financial']['safety_margin']),
        'temperature': _ensurePositiveDouble(data['financial']['temperature']),
      },
      'aerators': [],
    };

    // Process aerators array
    final aerators = data['aerators'] as List;
    for (var aerator in aerators) {
      normalizedData['aerators'].add({
        'name': _ensureNonEmptyString(aerator['name'], 'Unknown Aerator'),
        'sotr': _ensurePositiveDouble(aerator['sotr']),
        'power_hp': _ensurePositiveDouble(aerator['power_hp']),
        'cost': _ensureNonNegativeDouble(aerator['cost']),
        'durability': _ensurePositiveDouble(aerator['durability']),
        'maintenance': _ensureNonNegativeDouble(aerator['maintenance']),
      });
    }

    return normalizedData;
  }

  // Helper methods for data normalization
  double _ensurePositiveDouble(dynamic value) {
    if (value is num) return max(0.001, value.toDouble());
    try {
      final parsed = double.parse(value.toString());
      return max(0.001, parsed);
    } catch (_) {
      return 0.001;
    }
  }

  double _ensureNonNegativeDouble(dynamic value) {
    if (value is num) return max(0, value.toDouble());
    try {
      final parsed = double.parse(value.toString());
      return max(0, parsed);
    } catch (_) {
      return 0;
    }
  }

  int _ensurePositiveInt(dynamic value) {
    if (value is int) return max(1, value);
    try {
      final parsed = int.parse(value.toString());
      return max(1, parsed);
    } catch (_) {
      return 1;
    }
  }

  String _ensureNonEmptyString(dynamic value, String defaultValue) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return defaultValue;
    }
    return value.toString();
  }
}

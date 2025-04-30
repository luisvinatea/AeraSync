import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  // API service
  final ApiService _apiService;

  // State variables
  Map<String, dynamic>? _apiResults;
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

  // Compare aerators
  Future<void> compareAerators(Map<String, dynamic> surveyData) async {
    clearError();
    try {
      _apiResults = await _apiService.compareAerators(surveyData);
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        setError('Failed to connect to the server. Please check your internet connection and try again.');
      } else {
        setError('An unexpected error occurred: $e');
      }
    }
  }
}
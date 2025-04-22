import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  // Initialize logger
  static final Logger _logger = Logger('AppState');

  // API service
  final ApiService _apiService;

  // --- State Variables ---
  double? tod;
  double? shrimpRespiration;
  double? pondRespiration;
  double? pondWaterRespiration;
  double? pondBottomRespiration;
  double? annualRevenue;
  String? winnerLabel;
  List<AeratorResult> aeratorResults = [];
  Map<String, dynamic>? apiResults;

  // Locale state
  Locale _locale;

  // Error state
  String? _error;

  // API health state
  bool _isApiHealthy = true;

  // Data disclosure and cookies state
  bool _hasAgreedToDisclosure = false;
  bool _cookiesAccepted = false;

  // --- Constructor ---
  AppState({required Locale locale, ApiService? apiService})
      : _locale = locale,
        _apiService = apiService ?? ApiService() {
    // Set up logging level
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      }
    });
    // Load disclosure and cookies state
    _loadPreferences();
  }

  // --- Getters ---
  Locale get locale => _locale;
  String? get error => _error;
  bool get hasAgreedToDisclosure => _hasAgreedToDisclosure;
  bool get cookiesAccepted => _cookiesAccepted;
  bool get isApiHealthy => _isApiHealthy;

  // --- Setters and Methods ---

  /// Updates the application locale and saves it to preferences.
  set locale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      _saveLocalePreference(newLocale.languageCode);
      _logger.info('Locale updated to: ${newLocale.languageCode}');
      notifyListeners();
    }
  }

  /// Saves the selected language code to SharedPreferences.
  Future<void> _saveLocalePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', languageCode);
    } catch (e) {
      _logger.severe('Error saving locale preference: $e');
    }
  }

  /// Loads the disclosure agreement and cookies acceptance state from SharedPreferences.
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasAgreedToDisclosure = prefs.getBool('hasAgreedToDisclosure') ?? false;
      _cookiesAccepted = prefs.getBool('cookiesAccepted') ?? false;
      _logger.info('Loaded disclosure preference: $_hasAgreedToDisclosure');
      _logger.info('Loaded cookies preference: $_cookiesAccepted');
      notifyListeners();
    } catch (e) {
      _logger.severe('Error loading preferences: $e');
      _hasAgreedToDisclosure = false;
      _cookiesAccepted = false;
      notifyListeners();
    }
  }

  /// Sets the disclosure agreement state and saves it to preferences.
  void setDisclosureAgreed(bool value) {
    if (_hasAgreedToDisclosure != value) {
      _hasAgreedToDisclosure = value;
      _saveDisclosurePreference(value);
      _logger.info('Disclosure agreement set to: $value');
      notifyListeners();
    }
  }

  /// Sets the cookies acceptance state and saves it to preferences.
  void setCookiesAccepted(bool value) {
    if (_cookiesAccepted != value) {
      _cookiesAccepted = value;
      _saveCookiesPreference(value);
      _logger.info('Cookies acceptance set to: $value');
      notifyListeners();
    }
  }

  /// Saves the disclosure agreement state to SharedPreferences.
  Future<void> _saveDisclosurePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasAgreedToDisclosure', value);
    } catch (e) {
      _logger.severe('Error saving disclosure preference: $e');
    }
  }

  /// Saves the cookies acceptance state to SharedPreferences.
  Future<void> _saveCookiesPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cookiesAccepted', value);
    } catch (e) {
      _logger.severe('Error saving cookies preference: $e');
    }
  }

  /// Sets the API health state for testing purposes or after a health check.
  void setApiHealth(bool value) {
    if (_isApiHealthy != value) {
      _isApiHealthy = value;
      _logger.info('API health set to: $value');
      notifyListeners();
    }
  }

  /// Sets the current error message.
  void setError(String message) {
    _error = message;
    _logger.warning('Error set: $message');
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    if (_error != null) {
      _error = null;
      _logger.info('Error cleared');
      notifyListeners();
    }
  }

  /// Resets the results state, useful for testing or restarting the survey.
  void resetResults() {
    tod = null;
    shrimpRespiration = null;
    pondRespiration = null;
    pondWaterRespiration = null;
    pondBottomRespiration = null;
    annualRevenue = null;
    winnerLabel = null;
    aeratorResults = [];
    apiResults = null;
    clearError();
    _logger.info('Results state reset');
    notifyListeners();
  }

  /// Sets the results data received from the API.
  void setResults({
    required double tod,
    required double shrimpRespiration,
    required double pondRespiration,
    required double pondWaterRespiration,
    required double pondBottomRespiration,
    required double annualRevenue,
    required String winnerLabel,
    required List<AeratorResult> aeratorResults,
    required Map<String, dynamic> apiResults,
  }) {
    this.tod = tod;
    this.shrimpRespiration = shrimpRespiration;
    this.pondRespiration = pondRespiration;
    this.pondWaterRespiration = pondWaterRespiration;
    this.pondBottomRespiration = pondBottomRespiration;
    this.annualRevenue = annualRevenue;
    this.winnerLabel = winnerLabel;
    this.aeratorResults = aeratorResults;
    this.apiResults = apiResults;
    clearError();
    _logger.info('Results set: TOD=$tod, Winner=$winnerLabel, Aerators=${aeratorResults.length}');
    notifyListeners();
  }

  /// Checks if the backend API is reachable and healthy.
  Future<bool> checkApiHealth() async {
    try {
      _isApiHealthy = await _apiService.checkHealth();
      _logger.info('API health check result: $_isApiHealthy');
      notifyListeners();
      return _isApiHealthy;
    } catch (e, stackTrace) {
      _logger.severe('API Health Check Failed: $e\n$stackTrace');
      _isApiHealthy = false;
      notifyListeners();
      return false;
    }
  }

  /// Sends survey data to the backend API to compare aerators.
  Future<void> compareAerators(Map<String, dynamic> surveyData) async {
    clearError();
    try {
      final results = await _apiService.compareAerators(surveyData);
      _logger.info('Received compare-aerators response: $results');

      // Validate required fields
      if (results['tod'] == null ||
          results['shrimpRespiration'] == null ||
          results['pondRespiration'] == null ||
          results['winnerLabel'] == null ||
          results['aeratorResults'] == null) {
        setError('Incomplete data received from server: missing required fields.');
        return;
      }

      final aeratorResultsList = (results['aeratorResults'] as List<dynamic>? ?? [])
          .map((r) {
            if (r is Map<String, dynamic>) {
              return AeratorResult.fromJson(r);
            } else {
              _logger.warning('Skipping invalid item in aeratorResults list: $r');
              return null;
            }
          })
          .whereType<AeratorResult>()
          .toList();

      if (aeratorResultsList.isEmpty) {
        setError('No valid aerator results received from server.');
        return;
      }

      setResults(
        tod: (results['tod'] as num).toDouble(),
        shrimpRespiration: (results['shrimpRespiration'] as num).toDouble(),
        pondRespiration: (results['pondRespiration'] as num).toDouble(),
        pondWaterRespiration: (results['pondWaterRespiration'] as num?)?.toDouble() ?? 0.0,
        pondBottomRespiration: (results['pondBottomRespiration'] as num?)?.toDouble() ?? 0.0,
        annualRevenue: (results['annualRevenue'] as num?)?.toDouble() ?? 0.0,
        winnerLabel: results['winnerLabel'] as String,
        aeratorResults: aeratorResultsList,
        apiResults: Map<String, dynamic>.from(results['apiResults'] ?? {}),
      );
    } catch (e, stackTrace) {
      _logger.severe('CompareAerators Failed: $e\n$stackTrace');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        setError('Failed to connect to the server. Please check your internet connection and try again.');
      } else {
        setError('An unexpected error occurred: $e');
      }
    }
  }
}

// --- AeratorResult Data Class ---
class AeratorResult {
  final String name;
  final double sae;
  final int numAerators;
  final double totalAnnualCost;
  final double costPercentage;
  final double npv;
  final double irr;
  final double paybackPeriod;
  final double roi;
  final double profitabilityCoefficient;

  AeratorResult({
    required this.name,
    required this.sae,
    required this.numAerators,
    required this.totalAnnualCost,
    required this.costPercentage,
    required this.npv,
    required this.irr,
    required this.paybackPeriod,
    required this.roi,
    required this.profitabilityCoefficient,
  });

  factory AeratorResult.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return AeratorResult(
      name: json['name'] as String? ?? 'Unknown Aerator',
      sae: parseDouble(json['sae']),
      numAerators: parseInt(json['numAerators']),
      totalAnnualCost: parseDouble(json['totalAnnualCost']),
      costPercentage: parseDouble(json['costPercentage']),
      npv: parseDouble(json['npv']),
      irr: parseDouble(json['irr'], double.nan),
      paybackPeriod: parseDouble(json['paybackPeriod'], double.infinity),
      roi: parseDouble(json['roi']),
      profitabilityCoefficient: parseDouble(json['profitabilityCoefficient']),
    );
  }
}
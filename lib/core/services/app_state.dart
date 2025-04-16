import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class AppState extends ChangeNotifier {
  // Initialize logger
  static final Logger _logger = Logger('AppState');

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

  // Data disclosure state
  bool _hasAgreedToDisclosure = false;

  // Backend URL
  final String _baseUrl = 'http://localhost:8000';

  // --- Constructor ---
  AppState({required Locale locale}) : _locale = locale {
    // Set up logging level
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
    // Load disclosure agreement state
    _loadDisclosurePreference();
  }

  // --- Getters ---
  Locale get locale => _locale;
  String? get error => _error;
  bool get hasAgreedToDisclosure => _hasAgreedToDisclosure;

  // --- Setters and Methods ---

  /// Updates the application locale and saves it to preferences.
  set locale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      _saveLocalePreference(newLocale.languageCode);
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

  /// Loads the disclosure agreement state from SharedPreferences.
  Future<void> _loadDisclosurePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasAgreedToDisclosure = prefs.getBool('hasAgreedToDisclosure') ?? false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error loading disclosure preference: $e');
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

  /// Saves the disclosure agreement state to SharedPreferences.
  Future<void> _saveDisclosurePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasAgreedToDisclosure', value);
    } catch (e) {
      _logger.severe('Error saving disclosure preference: $e');
    }
  }

  /// Sets the API health state for testing purposes.
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
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
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
    notifyListeners();
  }

  /// Checks if the backend API is reachable and healthy.
  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      _isApiHealthy = (response.statusCode >= 200 && response.statusCode < 300);
      _logger.info('API health check: $_isApiHealthy');
      notifyListeners();
      return _isApiHealthy;
    } catch (e) {
      _logger.severe('API Health Check Failed: $e');
      _isApiHealthy = false;
      notifyListeners();
      return false;
    }
  }

  /// Sends survey data to the backend API to compare aerators.
  Future<void> compareAerators(Map<String, dynamic> surveyData) async {
    clearError();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compare-aerators'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(surveyData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        late final Map<String, dynamic> results;
        try {
          results = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        } catch (e) {
          setError('Failed to parse server response: $e');
          return;
        }

        if (results['tod'] != null && results['winnerLabel'] != null && results['aeratorResults'] != null) {
          setResults(
            tod: (results['tod'] as num?)?.toDouble() ?? 0.0,
            shrimpRespiration: (results['shrimpRespiration'] as num?)?.toDouble() ?? 0.0,
            pondRespiration: (results['pondRespiration'] as num?)?.toDouble() ?? 0.0,
            pondWaterRespiration: (results['pondWaterRespiration'] as num?)?.toDouble() ?? 0.0,
            pondBottomRespiration: (results['pondBottomRespiration'] as num?)?.toDouble() ?? 0.0,
            annualRevenue: (results['annualRevenue'] as num?)?.toDouble() ?? 0.0,
            winnerLabel: results['winnerLabel'] as String? ?? 'N/A',
            aeratorResults: (results['aeratorResults'] as List<dynamic>? ?? [])
                .map((r) {
                  if (r is Map<String, dynamic>) {
                    return AeratorResult.fromJson(r);
                  } else {
                    _logger.warning('Skipping invalid item in aeratorResults list: $r');
                    return null;
                  }
                })
                .whereType<AeratorResult>()
                .toList(),
            apiResults: Map<String, dynamic>.from(results['apiResults'] ?? {}),
          );
        } else {
          setError('Incomplete data received from server.');
        }
      } else {
        String responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        setError('API Error (${response.statusCode}): ${responseBody.isNotEmpty ? responseBody : response.reasonPhrase ?? "Unknown error"}');
      }
    } on TimeoutException catch (_) {
      setError('The request timed out. Please check your connection or try again later.');
    } on http.ClientException catch (e) {
      setError('Network error: ${e.message}');
    } catch (e) {
      setError('An unexpected error occurred: $e');
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
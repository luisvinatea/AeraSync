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
    _logger.info(
        'Results set: TOD=$tod, Winner=$winnerLabel, Aerators=${aeratorResults.length}');
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

      // Extract TOD values from the nested structure
      final todData = results['tod'] as Map<String, dynamic>?;
      final todValue = todData != null
          ? (todData['kg_o2_hour'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      // We'll log the daily TOD value but not store it in state for now
      if (todData != null && todData.containsKey('kg_o2_day')) {
        final dailyTodValue = (todData['kg_o2_day'] as num?)?.toDouble() ?? 0.0;
        _logger.info('Daily TOD value: $dailyTodValue kg O₂/day');
      }

      // Get the aerator results from the API response
      final aeratorResultsList =
          (results['aeratorResults'] as List<dynamic>? ?? [])
              .map((r) {
                if (r is Map<String, dynamic>) {
                  return AeratorResult.fromJson(r);
                } else {
                  _logger.warning(
                      'Skipping invalid item in aeratorResults list: $r');
                  return null;
                }
              })
              .whereType<AeratorResult>()
              .toList();

      if (aeratorResultsList.isEmpty) {
        setError('No valid aerator results received from server.');
        return;
      }

      // Get the winner label
      final String winner = results['winnerLabel'] as String? ?? 'Unknown';

      // Calculate respiration values (not directly provided by API)
      // Using placeholder values since API doesn't provide these directly
      double shrimpResp =
          todValue * 0.6; // Assuming 60% of total is from shrimp
      double pondResp = todValue * 0.4; // Assuming 40% of total is from pond
      double waterResp =
          pondResp * 0.6; // Assuming 60% of pond resp is from water
      double bottomResp =
          pondResp * 0.4; // Assuming 40% of pond resp is from bottom

      // Calculate annual revenue from financial data
      double annualRev = 0.0;

      // Try to extract financial values from survey data
      try {
        final farm = surveyData['farm'] as Map<String, dynamic>?;
        final financial = surveyData['financial'] as Map<String, dynamic>?;

        if (farm != null && financial != null) {
          final farmArea = (farm['area_ha'] as num?)?.toDouble() ?? 0.0;
          final shrimpPrice =
              (financial['shrimp_price_usd_kg'] as num?)?.toDouble() ?? 0.0;

          // Extract or calculate production values
          double productionPerHa = 5000.0; // Default production per ha
          if (surveyData['oxygen'] != null) {
            final oxygen = surveyData['oxygen'] as Map<String, dynamic>;
            if (oxygen['biomass_kg_ha'] != null) {
              productionPerHa = (oxygen['biomass_kg_ha'] as num).toDouble();
            }
          }

          annualRev = farmArea * productionPerHa * shrimpPrice;
        }
      } catch (e) {
        _logger.warning('Error calculating annual revenue: $e');
        annualRev = 0.0;
      }

      setResults(
        tod: todValue,
        shrimpRespiration: shrimpResp,
        pondRespiration: pondResp,
        pondWaterRespiration: waterResp,
        pondBottomRespiration: bottomResp,
        annualRevenue: annualRev,
        winnerLabel: winner,
        aeratorResults: aeratorResultsList,
        apiResults: results,
      );
    } catch (e, stackTrace) {
      _logger.severe('CompareAerators Failed: $e\n$stackTrace');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        setError(
            'Failed to connect to the server. Please check your internet connection and try again.');
      } else {
        setError('An unexpected error occurred: $e');
      }
    }
  }
}

// --- AeratorResult Data Class ---
class AeratorResult {
  final String name;
  final String brand;
  final String type;
  final int numAerators;
  final double totalPowerHp;
  final double totalInitialCost;
  final double annualEnergyCost;
  final double annualMaintenanceCost;
  final double npvCost;
  final double aeratorsPerHa;
  final double hpPerHa;

  // Calculated or extended properties
  final double sae;
  final double totalAnnualCost;
  final double costPercentage;
  final double npv;
  final double irr;
  final double paybackPeriod;
  final double roi;
  final double profitabilityCoefficient;

  AeratorResult({
    required this.name,
    required this.brand,
    required this.type,
    required this.numAerators,
    required this.totalPowerHp,
    required this.totalInitialCost,
    required this.annualEnergyCost,
    required this.annualMaintenanceCost,
    required this.npvCost,
    required this.aeratorsPerHa,
    required this.hpPerHa,
    this.sae = 0.0,
    this.totalAnnualCost = 0.0,
    this.costPercentage = 0.0,
    this.npv = 0.0,
    this.irr = 0.0,
    this.paybackPeriod = 0.0,
    this.roi = 0.0,
    this.profitabilityCoefficient = 0.0,
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

    // Calculate totalAnnualCost from energy and maintenance costs
    final annualEnergyCost = parseDouble(json['annual_energy_cost']);
    final annualMaintCost = parseDouble(json['annual_maintenance_cost']);
    final totalAnnualCost = annualEnergyCost + annualMaintCost;

    // Calculate derived values if not provided
    final totalInitialCost = parseDouble(json['total_initial_cost']);
    double saeValue = 0.0;
    if (totalInitialCost > 0) {
      // SAE is kg O2/kWh, estimated from power and costs
      final powerHp = parseDouble(json['total_power_hp']);
      if (powerHp > 0) {
        final powerKw = powerHp * 0.746; // Convert hp to kW
        saeValue = parseDouble(json['total_initial_cost']) / powerKw;
      }
    }

    // Calculate financial metrics
    final npvValue = -parseDouble(
        json['npv_cost']); // Converting negative cost to positive NPV
    double irrValue = 0.0;
    double roiValue = 0.0;
    double paybackPeriodValue = 0.0;
    double profitCoeffValue = 1.0;

    // Initialize estimated payback period (in months) if initial cost is positive
    if (totalInitialCost > 0 && totalAnnualCost > 0) {
      paybackPeriodValue =
          (totalInitialCost / totalAnnualCost) * 12; // Convert years to months
      roiValue =
          (totalAnnualCost / totalInitialCost) * 100; // ROI as percentage
    }

    // Default to empty strings for optional text fields
    final nameStr = json['name'] as String? ?? 'Unknown';
    final brandStr = json['brand'] as String? ?? '';
    final typeStr = json['type'] as String? ?? '';

    // Calculate cost percentage compared to most expensive option (placeholder implementation)
    double costPerc = 100.0; // Default to 100%

    return AeratorResult(
      name: nameStr,
      brand: brandStr,
      type: typeStr,
      numAerators: parseInt(json['num_aerators']),
      totalPowerHp: parseDouble(json['total_power_hp']),
      totalInitialCost: parseDouble(json['total_initial_cost']),
      annualEnergyCost: annualEnergyCost,
      annualMaintenanceCost: annualMaintCost,
      npvCost: parseDouble(json['npv_cost']),
      aeratorsPerHa: parseDouble(json['aerators_per_ha']),
      hpPerHa: parseDouble(json['hp_per_ha']),

      // Derived values
      sae: saeValue,
      totalAnnualCost: totalAnnualCost,
      costPercentage: costPerc,
      npv: npvValue,
      irr: irrValue,
      paybackPeriod: paybackPeriodValue,
      roi: roiValue,
      profitabilityCoefficient: profitCoeffValue,
    );
  }
}

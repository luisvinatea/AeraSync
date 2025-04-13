import 'dart:convert';
import 'dart:math' show log, pow; // Using specific imports
import 'package:flutter/services.dart' show rootBundle;

// Interface defining the calculator's capabilities
abstract class SaturationCalculator {
  /// Loads the necessary saturation data asynchronously.
  Future<void> loadData();

  /// Retrieves the oxygen saturation value (mg/L) for given temperature (°C) and salinity (ppt).
  /// Throws ArgumentError if inputs are out of range (0-40).
  /// Throws Exception if data is not loaded.
  double getO2Saturation(double temperature, double salinity);

  /// Calculates various aerator performance metrics.
  /// Requires operational parameters and aerator identification.
  /// Returns a map of calculated metrics with string keys.
  Map<String, dynamic> calculateMetrics({
    required double temperature, // Water temperature (°C)
    required double salinity,    // Water salinity (ppt)
    required double horsepower,  // Aerator horsepower (HP)
    required double volume,      // Pond/tank volume (m³)
    required double t10,         // Time to reach 10% saturation deficit (minutes) - Often for plotting/reference
    required double t70,         // Time to reach 70% saturation deficit (minutes) - Used for KLa calculation
    required double kWhPrice,    // Electricity cost (e.g., USD/kWh)
    required String aeratorId,   // Identifier string (e.g., "Brand Type")
  });
}

// Implementation using data loaded from a JSON file
class ShrimpPondCalculator implements SaturationCalculator {
  final String dataPath; // Path to the JSON data file in assets
  List<List<double>>? _matrix; // Loaded saturation data matrix
  double _tempStep = 1.0; // Default temperature step in data
  double _salStep = 5.0;  // Default salinity step in data
  // Cache for O2 saturation lookups to improve performance
  final Map<String, double> _o2SaturationCache = {};

  ShrimpPondCalculator(this.dataPath);

  @override
  Future<void> loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(dataPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = data['metadata'] as Map<String, dynamic>;
      // Parse the data matrix, ensuring values are doubles
      _matrix = (data['data'] as List)
          .map((row) => (row as List).map((e) => (e as num).toDouble()).toList()) // Ensure doubles
          .toList();
      // Load steps from metadata
      _tempStep = (metadata['temperature_range']['step'] as num).toDouble();
      _salStep = (metadata['salinity_range']['step'] as num).toDouble();
      _o2SaturationCache.clear(); // Clear cache when new data is loaded
      print("Saturation data loaded successfully."); // Log success
    } catch (e) {
      print("Error loading saturation data from $dataPath: $e"); // Log error
      // Rethrow as a more specific exception or handle as needed
      throw Exception('Failed to load saturation data: $e');
    }
  }

  @override
  double getO2Saturation(double temperature, double salinity) {
    // Create a cache key (using fixed precision for consistency)
    final cacheKey = '${temperature.toStringAsFixed(1)}-${salinity.toStringAsFixed(1)}';

    // Return cached result if available
    if (_o2SaturationCache.containsKey(cacheKey)) {
      return _o2SaturationCache[cacheKey]!;
    }

    if (_matrix == null) {
      throw Exception('Saturation data not loaded. Call loadData() first.');
    }
    // Validate input ranges
    if (!(0 <= temperature && temperature <= 40 && 0 <= salinity && salinity <= 40)) {
      throw ArgumentError('Temperature ($temperature) and salinity ($salinity) must be between 0 and 40');
    }

    // Calculate indices based on data structure (rounding temp, flooring salinity index)
    // Note: This assumes integer steps for temperature in the JSON data.
    final tempIdx = temperature.round();
    final salIdx = (salinity / _salStep).floor();

    // Bounds checking for indices
    if (tempIdx < 0 || tempIdx >= _matrix!.length || salIdx < 0 || salIdx >= _matrix![0].length) {
       // Provide more context in the error message
      throw RangeError('Calculated index out of bounds: tempIdx=$tempIdx (max=${_matrix!.length-1}), salIdx=$salIdx (max=${_matrix![0].length-1}) for temp=$temperature, sal=$salinity');
    }

    // Retrieve, cache, and return the result
    final result = _matrix![tempIdx][salIdx];
    _o2SaturationCache[cacheKey] = result;
    return result;
  }

  String _normalizeBrand(String brand) {
    const brandNormalization = {
      // ... (your existing map) ...
      'pentair': 'Pentair', 'beraqua': 'Beraqua', 'maof madam': 'Maof Madam',
      'maofmadam': 'Maof Madam', 'cosumisa': 'Cosumisa', 'pioneer': 'Pioneer',
      'ecuasino': 'Ecuasino', 'diva': 'Diva', 'gps': 'GPS', 'wangfa': 'WangFa',
      'akva': 'AKVA', 'xylem': 'Xylem', 'newterra': 'Newterra', 'tsurumi': 'TSURUMI',
      'oxyguard': 'OxyGuard', 'linn': 'LINN', 'hunan': 'Hunan', 'sagar': 'Sagar',
      'hcp': 'HCP', 'yiyuan': 'Yiyuan', 'generic': 'Generic',
      'pentairr': 'Pentair', 'beraqua1': 'Beraqua', 'maof-madam': 'Maof Madam',
      'cosumissa': 'Cosumisa', 'pionner': 'Pioneer', 'ecuacino': 'Ecuasino',
      'divva': 'Diva', 'wang fa': 'WangFa', 'oxy guard': 'OxyGuard', 'lin': 'LINN',
      'sagr': 'Sagar', 'hcpp': 'HCP', 'yiyuan1': 'Yiyuan',
    };

    if (brand.isEmpty) return 'Generic'; // Default to Generic if empty

    final brandLower = brand.toLowerCase().trim(); // Still trim and lowercase for lookup

    // Return normalized name if found in map
    if (brandNormalization.containsKey(brandLower)) {
        return brandNormalization[brandLower]!;
    }

    // FIX: Refined fallback for unknown brands
    // Replace multiple spaces with single, trim again, then title case
    final cleanedUnknownBrand = brand.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanedUnknownBrand.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
  }

  @override
  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10, // Often used for plotting or reference
    required double t70, // Time (minutes) to reach 70% saturation deficit
    required double kWhPrice,
    required String aeratorId, // Expected format "Brand Type" or just "Brand"
  }) {
    // --- Input Processing & Normalization ---
    // FIX: Trim input and filter empty parts after splitting
    final cleanedId = aeratorId.trim(); // Trim leading/trailing spaces
    final parts = cleanedId.split(' ').where((part) => part.isNotEmpty).toList(); // Split and remove empty strings

    final brand = parts.isNotEmpty ? parts[0] : ''; // Use empty string if no parts
    final aeratorType = parts.length > 1 ? parts.sublist(1).join(' ') : 'Unknown'; // Type is the rest
    final normalizedBrand = _normalizeBrand(brand); // Normalize the extracted brand

    // Reconstruct normalized ID
    // If brand was empty, normalizedBrand will be 'Generic'
    final normalizedAeratorId = (normalizedBrand == 'Generic' && aeratorType == 'Unknown')
        ? 'Generic Unknown' // Handle case of empty/generic input resulting in unknown type
        : '$normalizedBrand $aeratorType'.trim(); // Combine and trim potential extra space if type was Unknown initially

    // --- Intermediate Calculations ---
    // Power in kW, rounded to 2 decimal places
    final powerKw = (horsepower * 0.746 * 100).round() / 100;

    // Oxygen saturation at operating temp (Cs) and standard temp (Cs20)
    final cs = getO2Saturation(temperature, salinity); // mg/L
    final cs20 = getO2Saturation(20, salinity);       // mg/L
    // Convert Cs20 to kg/m³ for SOTR calculation (1 mg/L = 0.001 kg/m³)
    final cs20KgM3 = cs20 * 0.001;

    // KLa calculation (Oxygen transfer coefficient)
    // KLaT at operating temperature (h⁻¹)
    if (t70 <= 0) throw ArgumentError("T70 must be positive for KLa calculation.");
    // Assumes test starts at C0 and measures time to reach C(t) = C0 + 0.7*(Cs - C0)
    // Formula: KLa = -ln( (Cs-C(t))/(Cs-C0) ) / t = -ln( (Cs - (C0 + 0.7*(Cs-C0))) / (Cs-C0) ) / t
    // Simplifies to: KLa = -ln( (0.3 * (Cs-C0)) / (Cs-C0) ) / t = -ln(0.3) / t
    // Using ln(1 - 0.7) = ln(0.3) which is standard practice. Ensure t70 is in hours.
    final klaT = -log(1 - 0.7) / (t70 / 60.0); // t70 in minutes converted to hours

    // KLa at standard temperature 20°C (h⁻¹) using theta correction
    const double theta = 1.024;
    final kla20 = klaT * pow(theta, 20.0 - temperature).toDouble();

    // --- Core Metrics Calculation ---
    // SOTR (Standard Oxygen Transfer Rate) in kg O₂/h
    // Formula: SOTR = KLa20 * Cs20(kg/m³) * Volume(m³)
    final sotr = (kla20 * cs20KgM3 * volume * 100).round() / 100.0;

    // SAE (Standard Aeration Efficiency) in kg O₂/kWh
    // Handle division by zero if power is zero
    final sae = powerKw > 0 ? (sotr / powerKw * 100).round() / 100.0 : 0.0;

    // Cost per kg of O₂ transferred (e.g., USD/kg O₂)
    // Handle division by zero if SAE is zero
    final costPerKg = sae > 0 ? (kWhPrice / sae * 100).round() / 100.0 : double.infinity;

    // Annual Energy Cost (assuming continuous operation 24/7)
    final annualEnergyCost = (powerKw * kWhPrice * 24 * 365 * 100).round() / 100.0;

    // --- Return Results Map ---
    // Use clear, descriptive keys
    return {
      'Pond Volume (m³)': volume,
      'Cs (mg/L)': (cs * 100).round() / 100.0, // Saturation at T, Sal
      'KlaT (h⁻¹)': (klaT * 100).round() / 100.0, // KLa at T
      'Kla20 (h⁻¹)': (kla20 * 100).round() / 100.0, // KLa at 20°C
      'SOTR (kg O₂/h)': sotr, // Standard Oxygen Transfer Rate
      'SAE (kg O₂/kWh)': sae, // Standard Aeration Efficiency
      'Cost per kg O₂ (USD/kg O₂)': costPerKg, // Cost indicator
      'Power (kW)': powerKw, // Calculated power consumption
      'Annual Energy Cost (USD/year)': annualEnergyCost, // Estimated annual cost
      'Normalized Aerator ID': normalizedAeratorId, // Consistent ID
      // Include Cs20 for reference if needed
      'Cs20 (mg/L)': (cs20 * 100).round() / 100.0,
    };
  }
}

import 'dart:convert';
import 'dart:math'; // Import needed for clamp
import 'package:flutter/foundation.dart'; // For kIsWeb and potentially debugPrint
import 'package:flutter/services.dart' show rootBundle;

/// Calculates shrimp respiration rate based on loaded data using trilinear interpolation.
class ShrimpRespirationCalculator {
  final String dataPath; // Path to the JSON data file
  Map<String, dynamic>? _respirationData; // Parsed JSON data (nested map)
  // Lists to store the discrete values from the data grid for interpolation bounds
  List<double> _salinityValues = [];
  List<double> _temperatureValues = [];
  List<double> _biomassValues = [];

  ShrimpRespirationCalculator(this.dataPath);

  // --- Getters for Testing ---
  // These expose internal state for verification in unit tests.
  @visibleForTesting
  List<double> get salinityValuesForTest => List.unmodifiable(_salinityValues);
  @visibleForTesting
  List<double> get temperatureValuesForTest => List.unmodifiable(_temperatureValues);
  @visibleForTesting
  List<double> get biomassValuesForTest => List.unmodifiable(_biomassValues);
  @visibleForTesting
  Map<String, dynamic>? get respirationDataForTest => _respirationData == null ? null : Map.unmodifiable(_respirationData!);
  // --- End Getters for Testing ---


  /// Loads and parses the respiration data from the JSON file specified by [dataPath].
  Future<void> loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(dataPath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Extract metadata to define the grid dimensions and values
      final metadata = jsonData['metadata'];
      if (metadata == null) throw Exception("Metadata missing in JSON");

      // Parse and store the discrete values for each dimension, ensuring they are sorted
      _salinityValues = (metadata['salinity_values'] as List)
          .map((s) => double.parse(s.toString().replaceAll('%', ''))) // Ensure parsing from string
          .toList()..sort(); // Sort for reliable boundary finding
      _temperatureValues = (metadata['temperature_values'] as List)
          .map((t) => double.parse(t.toString().replaceAll('°C', ''))) // Ensure parsing from string
          .toList()..sort();
      _biomassValues = (metadata['shrimp_biomass'] as List)
          .map((b) => double.parse(b.toString().replaceAll('g', ''))) // Ensure parsing from string
          .toList()..sort();

      // Store the main data grid
      _respirationData = jsonData['data'];
      if (_respirationData == null) throw Exception("Data grid missing in JSON");

      debugPrint("Shrimp respiration data loaded successfully."); // Use debugPrint

    } catch (e) {
      debugPrint("Error loading shrimp respiration data from $dataPath: $e"); // Use debugPrint
      throw Exception('Failed to load shrimp respiration data: $e');
    }
  }

  /// Calculates the respiration rate (mg O₂/g/h) for the given conditions.
  /// Uses trilinear interpolation based on the loaded data.
  double getRespirationRate(double salinity, double temperature, double shrimpWeight) {
    if (_respirationData == null || _salinityValues.isEmpty || _temperatureValues.isEmpty || _biomassValues.isEmpty) {
      throw Exception('Respiration data not loaded or invalid. Call loadData() first.');
    }

    // 1. Clamp input values to the range covered by the data
    final clampedSalinity = salinity.clamp(_salinityValues.first, _salinityValues.last);
    final clampedTemperature = temperature.clamp(_temperatureValues.first, _temperatureValues.last);
    final clampedWeight = shrimpWeight.clamp(_biomassValues.first, _biomassValues.last);

    // 2. Find the surrounding grid points (lower and upper bounds for each dimension)
    //    `lastWhere` finds the largest value <= input, `firstWhere` finds the smallest value >= input.
    final salinityLow = _salinityValues.lastWhere((s) => s <= clampedSalinity, orElse: () => _salinityValues.first);
    final salinityHigh = _salinityValues.firstWhere((s) => s >= clampedSalinity, orElse: () => _salinityValues.last);
    final tempLow = _temperatureValues.lastWhere((t) => t <= clampedTemperature, orElse: () => _temperatureValues.first);
    final tempHigh = _temperatureValues.firstWhere((t) => t >= clampedTemperature, orElse: () => _temperatureValues.last);
    final weightLow = _biomassValues.lastWhere((w) => w <= clampedWeight, orElse: () => _biomassValues.first);
    final weightHigh = _biomassValues.firstWhere((w) => w >= clampedWeight, orElse: () => _biomassValues.last);

    // 3. Convert boundary values to the string keys used in the JSON data
    final salinityLowKey = '${salinityLow.toInt()}%';
    final salinityHighKey = '${salinityHigh.toInt()}%';
    final tempLowKey = '${tempLow.toInt()}°C';
    final tempHighKey = '${tempHigh.toInt()}°C';
    final weightLowKey = '${weightLow.toInt()}g';
    final weightHighKey = '${weightHigh.toInt()}g';

    // 4. Retrieve the respiration rate values at the 8 corners of the interpolation cube.
    //    Assumes the JSON structure: data[salinity][temperature][weight]
    //    Includes null checks for safer access.
    try {
      // Use helper for safer access
      final r000 = _getValueFromData(salinityLowKey, tempLowKey, weightLowKey);
      final r001 = _getValueFromData(salinityLowKey, tempLowKey, weightHighKey);
      final r010 = _getValueFromData(salinityLowKey, tempHighKey, weightLowKey);
      final r011 = _getValueFromData(salinityLowKey, tempHighKey, weightHighKey);
      final r100 = _getValueFromData(salinityHighKey, tempLowKey, weightLowKey);
      final r101 = _getValueFromData(salinityHighKey, tempLowKey, weightHighKey);
      final r110 = _getValueFromData(salinityHighKey, tempHighKey, weightLowKey);
      final r111 = _getValueFromData(salinityHighKey, tempHighKey, weightHighKey);


      // Check if any corner value is null (indicates missing data in JSON)
      final cornerValues = [r000, r001, r010, r011, r100, r101, r110, r111];
      if (cornerValues.any((r) => r == null)) {
         throw Exception("Missing respiration data for interpolation corner points near S=$salinity, T=$temperature, W=$shrimpWeight. Check JSON structure and keys (e.g., $salinityLowKey, $tempLowKey, $weightLowKey).");
      }

      // Cast non-null values
      final double r000d = r000!;
      final double r001d = r001!;
      final double r010d = r010!;
      final double r011d = r011!;
      final double r100d = r100!;
      final double r101d = r101!;
      final double r110d = r110!;
      final double r111d = r111!;


      // 5. Calculate interpolation factors (relative position within the cube, 0 to 1)
      //    Denominator is clamped to avoid division by zero if bounds are the same.
      final double salDiff = (salinityHigh - salinityLow);
      final double tempDiff = (tempHigh - tempLow);
      final double weightDiff = (weightHigh - weightLow);

      // Avoid division by zero if bounds are identical
      final s = salDiff == 0 ? 0.0 : (clampedSalinity - salinityLow) / salDiff;
      final t = tempDiff == 0 ? 0.0 : (clampedTemperature - tempLow) / tempDiff;
      final w = weightDiff == 0 ? 0.0 : (clampedWeight - weightLow) / weightDiff;


      // 6. Perform trilinear interpolation:
      //    Interpolate along the weight axis (w) at each of the 4 temperature/salinity corners
      final r00 = r000d + (r001d - r000d) * w;
      final r01 = r010d + (r011d - r010d) * w;
      final r10 = r100d + (r101d - r100d) * w;
      final r11 = r110d + (r111d - r110d) * w;

      //    Interpolate along the temperature axis (t) using the results from the weight interpolation
      final r0 = r00 + (r01 - r00) * t;
      final r1 = r10 + (r11 - r10) * t;

      //    Interpolate along the salinity axis (s) using the results from the temperature interpolation
      final respirationRate = r0 + (r1 - r0) * s;

      return respirationRate;

    } catch (e) {
       // Catch potential errors during map lookup (e.g., key not found) or casting
       debugPrint("Error during respiration data lookup/interpolation: $e");
       throw Exception("Failed to calculate respiration rate. Check JSON data structure and keys near S=$salinity, T=$temperature, W=$shrimpWeight.");
    }
  }

  /// Safely retrieves and converts a value from the nested respiration data map.
  double? _getValueFromData(String salKey, String tempKey, String weightKey) {
      final level1 = _respirationData?[salKey];
      if (level1 is! Map) return null;
      final level2 = level1[tempKey];
      if (level2 is! Map) return null;
      final value = level2[weightKey];
      if (value is num) {
        return value.toDouble();
      }
      return null; // Return null if key path doesn't exist or value is not a number
  }
}

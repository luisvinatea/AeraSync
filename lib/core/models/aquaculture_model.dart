// FIX: Add missing import for debugPrint
import 'package:flutter/foundation.dart';

/// Represents an aerator used in shrimp ponds.
/// Simple immutable data class.
class Aerator {
  /// Unique identifier for the aerator.
  final String id;

  /// Name of the aerator (e.g., "Pentair Paddlewheel").
  final String name;

  /// Standard Oxygen Transfer Rate per horsepower (kg O₂/h/HP).
  /// Note: This might not be directly used if calculations rely on total SOTR.
  final double sotrPerHp;

  Aerator({
    required this.id,
    required this.name,
    required this.sotrPerHp,
  });
}

/// Represents calculated performance metrics for an aerator in a pond.
class PondMetrics {
  /// Pond volume in cubic meters (m³).
  final double volume;

  /// Oxygen saturation concentration at given temperature and salinity (mg/L).
  final double cs;

  /// Oxygen transfer coefficient at given temperature (h⁻¹).
  final double klaT;

  /// Oxygen transfer coefficient at 20°C (h⁻¹).
  final double kla20;

  /// Standard Oxygen Transfer Rate (kg O₂/h).
  final double sotr;

  /// Standard Aeration Efficiency (kg O₂/kWh).
  final double sae;

  /// Annual energy cost (USD/year), assuming continuous operation.
  final double annualEnergyCost;

  /// Power consumption in kilowatts (kW).
  final double powerKw;

  PondMetrics({
    required this.volume,
    required this.cs,
    required this.klaT,
    required this.kla20,
    required this.sotr,
    required this.sae,
    required this.annualEnergyCost,
    required this.powerKw,
  });

  /// Creates a [PondMetrics] instance from a map of calculator results.
  ///
  /// Relies on specific string keys being present in the [results] map.
  factory PondMetrics.fromCalculatorResults(Map<String, dynamic> results) {
    // Define the exact keys expected from SaturationCalculator.calculateMetrics
    // Consider using constants shared between the calculator and model.
    const requiredKeys = [
      'Pond Volume (m³)',
      'Cs (mg/L)',
      'KlaT (h⁻¹)',
      'Kla20 (h⁻¹)',
      'SOTR (kg O₂/h)',
      'SAE (kg O₂/kWh)',
      'Annual Energy Cost (USD/year)',
      'Power (kW)',
      // Add 'Cs20 (mg/L)' if you intend to use it from the results map
    ];

    // Validate that all required keys exist and have numeric values
    for (final key in requiredKeys) {
      if (!results.containsKey(key) || results[key] == null || results[key] is! num) {
        // Error Handling Strategy: Currently returns default values.
        // This prevents crashes but might hide calculation issues.
        // Alternatives:
        // 1. Throw an Exception: throw FormatException('Invalid or missing key in calculator results: $key');
        // 2. Return Null: Change factory signature to `PondMetrics?` and return `null`.
        debugPrint('Warning: Invalid calculator results for key: "$key", value: ${results[key]}');
        // Return default instance on error
        return PondMetrics(
          volume: 0.0, cs: 0.0, klaT: 0.0, kla20: 0.0, sotr: 0.0,
          sae: 0.0, annualEnergyCost: 0.0, powerKw: 0.0,
        );
      }
    }

    // If all checks pass, create the instance by casting the numeric values
    try {
      return PondMetrics(
        volume: (results['Pond Volume (m³)'] as num).toDouble(),
        cs: (results['Cs (mg/L)'] as num).toDouble(),
        klaT: (results['KlaT (h⁻¹)'] as num).toDouble(),
        kla20: (results['Kla20 (h⁻¹)'] as num).toDouble(),
        sotr: (results['SOTR (kg O₂/h)'] as num).toDouble(),
        sae: (results['SAE (kg O₂/kWh)'] as num).toDouble(),
        annualEnergyCost: (results['Annual Energy Cost (USD/year)'] as num).toDouble(),
        powerKw: (results['Power (kW)'] as num).toDouble(),
      );
    } catch (e) {
       // Catch potential casting errors, although the loop should prevent them.
       debugPrint('Error casting calculator results: $e');
       // Return default instance on casting error
       return PondMetrics(
          volume: 0.0, cs: 0.0, klaT: 0.0, kla20: 0.0, sotr: 0.0,
          sae: 0.0, annualEnergyCost: 0.0, powerKw: 0.0,
       );
    }
  }
}

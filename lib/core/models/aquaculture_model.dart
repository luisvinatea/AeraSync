/// Represents an aerator used in shrimp ponds.
class Aerator {
  final String id;
  final String name;
  final double sotrPerHp;

  Aerator({
    required this.id,
    required this.name,
    required this.sotrPerHp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sotrPerHp': sotrPerHp,
      };

  factory Aerator.fromJson(Map<String, dynamic> json) => Aerator(
        id: json['id'] as String,
        name: json['name'] as String,
        sotrPerHp: (json['sotrPerHp'] as num).toDouble(),
      );
}

/// Represents calculated metrics for a shrimp pond.
class PondMetrics {
  /// Pond volume in cubic meters (m³).
  final double volume;

  /// Oxygen saturation concentration at given temperature and salinity (mg/L).
  final double cs;

  /// Oxygen transfer coefficient at given temperature (h⁻¹).
  final double klaT;

  /// Oxygen transfer coefficient at 20°C (h⁻¹).
  final double kla20;

  /// Standard Oxygen Transfer Rate (kg O₂/h), truncated to 2 decimals.
  final double sotr;

  /// Standard Aeration Efficiency (kg O₂/kWh), truncated to 2 decimals.
  final double sae;

  /// Annual energy cost (USD/year), truncated to 2 decimals.
  final double annualEnergyCost;

  /// Power consumption in kilowatts (kW), truncated to 2 decimals.
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

  /// Creates a [PondMetrics] instance from calculator results.
  factory PondMetrics.fromCalculatorResults(Map<String, dynamic> results) {
    // Validate required keys
    const requiredKeys = [
      'Pond Volume (m³)',
      'Cs (mg/L)',
      'KlaT (h⁻¹)',
      'Kla20 (h⁻¹)',
      'SOTR (kg O₂/h)',
      'SAE (kg O₂/kWh)',
      'Annual Energy Cost (USD/year)',
      'Power (kW)',
    ];

    for (final key in requiredKeys) {
      if (!results.containsKey(key) || results[key] == null) {
        throw ArgumentError('Missing or null value for key: $key');
      }
      if (results[key] is! num) {
        throw ArgumentError('Value for key $key must be a number, got ${results[key].runtimeType}');
      }
    }

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
  }

  Map<String, dynamic> toJson() => {
        'volume': volume,
        'cs': cs,
        'klaT': klaT,
        'kla20': kla20,
        'sotr': sotr,
        'sae': sae,
        'annualEnergyCost': annualEnergyCost,
        'powerKw': powerKw,
      };

  factory PondMetrics.fromJson(Map<String, dynamic> json) => PondMetrics(
        volume: (json['volume'] as num).toDouble(),
        cs: (json['cs'] as num).toDouble(),
        klaT: (json['klaT'] as num).toDouble(),
        kla20: (json['kla20'] as num).toDouble(),
        sotr: (json['sotr'] as num).toDouble(),
        sae: (json['sae'] as num).toDouble(),
        annualEnergyCost: (json['annualEnergyCost'] as num).toDouble(),
        powerKw: (json['powerKw'] as num).toDouble(),
      );
}
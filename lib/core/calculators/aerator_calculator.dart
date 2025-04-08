import 'dart:math';

class AeratorCalculator {
  // Precompute constants for the oxygen saturation formula
  static const double _a1 = -139.34411;
  static const double _a2 = 1.575701e5;
  static const double _a3 = -6.642308e7;
  static const double _a4 = 1.243800e10;
  static const double _a5 = -8.621949e11;

  /// Calculates oxygen saturation (mg/L) at 100% based on temperature (°C) and salinity (‰).
  double getO2Saturation(double temperature, double salinity) {
    final t = temperature + 273.15; // Convert to Kelvin
    final t2 = t * t;
    final t3 = t2 * t;
    final t4 = t3 * t;

    // Calculate ln(Cs) for fresh water
    final lnCs = _a1 +
        (_a2 / t) +
        (_a3 / t2) +
        (_a4 / t3) +
        (_a5 / t4);
    final csFresh = exp(lnCs);

    // Adjust for salinity
    final s = salinity;
    final salinityCorrection = exp(-s * (0.017674 - 10.754 / t + 2140.7 / t2));
    return csFresh * salinityCorrection;
  }

  /// Calculates performance metrics for an aerator.
  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10,
    required double t70,
    required double kWhPrice,
    required String aeratorId,
  }) {
    // Calculate oxygen transfer rate (OTR) based on T10 and T70
    final kLa = log(0.9) / (t70 - t10); // Oxygen transfer coefficient (1/min)
    final cs = getO2Saturation(temperature, salinity);
    final otr = kLa * cs * volume * 60 * 1e-6; // kg O₂/h

    // Calculate Standard Oxygen Transfer Rate (SOTR) at 20°C, 0‰ salinity
    final cs20 = getO2Saturation(20, 0);
    final sotr = otr * (cs20 / cs) * pow(1.024, 20 - temperature);

    // Calculate Standard Aeration Efficiency (SAE)
    final power = horsepower * 0.7457; // Convert HP to kW
    final sae = sotr / power; // kg O₂/kWh

    // Calculate energy cost
    final energyCost = power * kWhPrice * 24 * 365; // Annual cost in USD

    return {
      'OTR (kg O₂/h)': otr,
      'SOTR (kg O₂/h)': sotr,
      'SAE (kg O₂/kWh)': sae,
      'Annual Energy Cost (USD/year)': energyCost,
      'Aerator ID': aeratorId,
    };
  }
}
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ShrimpRespirationCalculator {
  final String dataPath;
  Map<String, dynamic>? _respirationData;
  List<double> _salinityValues = [];
  List<double> _temperatureValues = [];
  List<double> _biomassValues = [];

  ShrimpRespirationCalculator(this.dataPath);

  Future<void> loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(dataPath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Extract metadata
      final metadata = jsonData['metadata'];
      _salinityValues = (metadata['salinity_values'] as List)
          .map((s) => double.parse(s.replaceAll('%', '')))
          .toList();
      _temperatureValues = (metadata['temperature_values'] as List)
          .map((t) => double.parse(t.replaceAll('°C', '')))
          .toList();
      _biomassValues = (metadata['shrimp_biomass'] as List)
          .map((b) => double.parse(b.replaceAll('g', '')))
          .toList();

      _respirationData = jsonData['data'];
    } catch (e) {
      throw Exception('Failed to load shrimp respiration data: $e');
    }
  }

  double getRespirationRate(double salinity, double temperature, double shrimpWeight) {
    if (_respirationData == null) {
      throw Exception('Respiration data not loaded');
    }

    // Clamp input values to the range of the data
    final clampedSalinity = salinity.clamp(_salinityValues.first, _salinityValues.last);
    final clampedTemperature = temperature.clamp(_temperatureValues.first, _temperatureValues.last);
    final clampedWeight = shrimpWeight.clamp(_biomassValues.first, _biomassValues.last);

    // Find the nearest salinity, temperature, and biomass values for interpolation
    final salinityLow = _salinityValues.lastWhere((s) => s <= clampedSalinity, orElse: () => _salinityValues.first);
    final salinityHigh = _salinityValues.firstWhere((s) => s >= clampedSalinity, orElse: () => _salinityValues.last);
    final tempLow = _temperatureValues.lastWhere((t) => t <= clampedTemperature, orElse: () => _temperatureValues.first);
    final tempHigh = _temperatureValues.firstWhere((t) => t >= clampedTemperature, orElse: () => _temperatureValues.last);
    final weightLow = _biomassValues.lastWhere((w) => w <= clampedWeight, orElse: () => _biomassValues.first);
    final weightHigh = _biomassValues.firstWhere((w) => w >= clampedWeight, orElse: () => _biomassValues.last);

    // Convert to string keys for lookup
    final salinityLowKey = '${salinityLow.toInt()}%';
    final salinityHighKey = '${salinityHigh.toInt()}%';
    final tempLowKey = '${tempLow.toInt()}°C';
    final tempHighKey = '${tempHigh.toInt()}°C';
    final weightLowKey = '${weightLow.toInt()}g';
    final weightHighKey = '${weightHigh.toInt()}g';

    // Get respiration rates at the 8 corners of the interpolation cube
    final r000 = _respirationData![salinityLowKey]![tempLowKey]![weightLowKey] as double;
    final r001 = _respirationData![salinityLowKey]![tempLowKey]![weightHighKey] as double;
    final r010 = _respirationData![salinityLowKey]![tempHighKey]![weightLowKey] as double;
    final r011 = _respirationData![salinityLowKey]![tempHighKey]![weightHighKey] as double;
    final r100 = _respirationData![salinityHighKey]![tempLowKey]![weightLowKey] as double;
    final r101 = _respirationData![salinityHighKey]![tempLowKey]![weightHighKey] as double;
    final r110 = _respirationData![salinityHighKey]![tempHighKey]![weightLowKey] as double;
    final r111 = _respirationData![salinityHighKey]![tempHighKey]![weightHighKey] as double;

    // Perform trilinear interpolation
    final s = (clampedSalinity - salinityLow) / (salinityHigh - salinityLow).clamp(0.001, double.infinity);
    final t = (clampedTemperature - tempLow) / (tempHigh - tempLow).clamp(0.001, double.infinity);
    final w = (clampedWeight - weightLow) / (weightHigh - weightLow).clamp(0.001, double.infinity);

    // Interpolate along weight (w)
    final r00 = r000 + (r001 - r000) * w;
    final r01 = r010 + (r011 - r010) * w;
    final r10 = r100 + (r101 - r100) * w;
    final r11 = r110 + (r111 - r110) * w;

    // Interpolate along temperature (t)
    final r0 = r00 + (r01 - r00) * t;
    final r1 = r10 + (r11 - r10) * t;

    // Interpolate along salinity (s)
    final respirationRate = r0 + (r1 - r0) * s;

    return respirationRate;
  }
}
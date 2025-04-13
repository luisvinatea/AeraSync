import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/app_state.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AeratorComparisonForm extends StatefulWidget {
  const AeratorComparisonForm({super.key});

  @override
  State<AeratorComparisonForm> createState() => _AeratorComparisonFormState();
}

class _AeratorComparisonFormState extends State<AeratorComparisonForm> {
  final _formKey = GlobalKey<FormState>();
  final _sotr1Controller = TextEditingController(text: '1.4');
  final _sotr2Controller = TextEditingController(text: '2.2');
  final _price1Controller = TextEditingController(text: '500');
  final _price2Controller = TextEditingController(text: '800');
  final _maintenance1Controller = TextEditingController(text: '65');
  final _maintenance2Controller = TextEditingController(text: '50');
  final _durability1Controller = TextEditingController(text: '2');
  final _durability2Controller = TextEditingController(text: '4.5');
  final _temperatureController = TextEditingController(text: '31.5');
  final _salinityController = TextEditingController(text: '20');
  final _biomassController = TextEditingController(text: '3333.33'); // Adjusted to match article
  final _discountRateController = TextEditingController(text: '10'); // %
  final _inflationRateController = TextEditingController(text: '2.5'); // %
  final _analysisHorizonController = TextEditingController(text: '9'); // years
  final _manualTODController = TextEditingController(text: '5443.7675'); // kg O₂/h for 1000 ha

  // Custom respiration rate controllers
  final _shrimpRespirationController = TextEditingController(text: '0.3436'); // mg O₂/g/h
  final _waterRespirationController = TextEditingController(text: '0.49125'); // mg/L/h
  final _bottomRespirationController = TextEditingController(text: '0.245625'); // mg/L/h

  // Toggles for manual TOD and custom respiration rates
  bool _useManualTOD = false;
  bool _useCustomShrimpRespiration = false;
  bool _useCustomWaterRespiration = false;
  bool _useCustomBottomRespiration = false;

  Map<String, dynamic>? _saturationData;
  Map<String, dynamic>? _respirationData;

  // Intermediate values for display (Consider removing if not used elsewhere)
  double? otrT1;
  double? otrT2;
  double? shrimpDemand;
  double? waterDemand;
  double? bottomDemand;
  double? totalDemand;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final saturationString = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
      final respirationString = await rootBundle.loadString('assets/data/shrimp_respiration_salinity_temperature_weight.json');
      if (mounted) { // Check if widget is still mounted before calling setState
        setState(() {
          _saturationData = jsonDecode(saturationString);
          _respirationData = jsonDecode(respirationString);
        });
      }
    } catch (e) {
       // Handle potential errors during file loading/parsing
       print("Error loading data: $e");
       // Optionally show an error message to the user via AppState
       // Provider.of<AppState>(context, listen: false).setError("Failed to load necessary data.");
    }
  }

  @override
  void dispose() {
    _sotr1Controller.dispose();
    _sotr2Controller.dispose();
    _price1Controller.dispose();
    _price2Controller.dispose();
    _maintenance1Controller.dispose();
    _maintenance2Controller.dispose();
    _durability1Controller.dispose();
    _durability2Controller.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _biomassController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _analysisHorizonController.dispose();
    _manualTODController.dispose();
    _shrimpRespirationController.dispose();
    _waterRespirationController.dispose();
    _bottomRespirationController.dispose();
    super.dispose();
  }

  // --- Calculation Helper Methods ---

  double _interpolate(double x, double x0, double x1, double y0, double y1) {
    // Avoid division by zero
    if ((x1 - x0) == 0) return y0;
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }

  double _getCs100(double temperature, double salinity) {
    if (_saturationData == null || _saturationData!['data'] == null) {
       throw Exception("Saturation data not loaded");
    }
    // Ensure indices are within bounds
    final tempIndexLow = temperature.floor().clamp(0, _saturationData!['data'].length - 2);
    final tempIndexHigh = tempIndexLow + 1;
    // Assuming salinity steps of 5 ppt, find the correct column index
    final salIndex = (salinity / 5).floor().clamp(0, _saturationData!['data'][0].length - 1);

    final csLow = _saturationData!['data'][tempIndexLow][salIndex];
    final csHigh = _saturationData!['data'][tempIndexHigh][salIndex];

    // Ensure csLow and csHigh are doubles
    final double csLowDouble = (csLow is int) ? csLow.toDouble() : csLow;
    final double csHighDouble = (csHigh is int) ? csHigh.toDouble() : csHigh;


    return _interpolate(temperature, tempIndexLow.toDouble(), tempIndexHigh.toDouble(), csLowDouble, csHighDouble);
  }

  double _getRespirationRate(double temperature, double salinity, double weight) {
     if (_respirationData == null || _respirationData!['data'] == null) {
       throw Exception("Respiration data not loaded");
     }

    // Determine keys based on input values
    String salKey;
    if (salinity <= 7) salKey = "1%";
    else if (salinity <= 19) salKey = "13%";
    else if (salinity <= 31) salKey = "25%";
    else salKey = "37%";

    String tempKeyLow, tempKeyHigh;
    double tempLow, tempHigh;
    if (temperature <= 22.5) {
      tempKeyLow = "20°C"; tempKeyHigh = "25°C"; tempLow = 20.0; tempHigh = 25.0;
    } else if (temperature < 30) { // Interpolate between 25 and 30
       tempKeyLow = "25°C"; tempKeyHigh = "30°C"; tempLow = 25.0; tempHigh = 30.0;
    }
     else { // Temperature is 30 or above, use 30°C data
       tempKeyLow = "30°C"; tempKeyHigh = "30°C"; tempLow = 30.0; tempHigh = 30.0;
    }


    String weightKey;
    if (weight <= 7.5) weightKey = "5g";
    else if (weight <= 12.5) weightKey = "10g";
    else if (weight <= 17.5) weightKey = "15g";
    else weightKey = "20g";

    // Safely access data, provide default or handle missing keys
    final rateLowData = _respirationData!['data'][salKey]?[tempKeyLow]?[weightKey];
    final rateHighData = _respirationData!['data'][salKey]?[tempKeyHigh]?[weightKey];

    if (rateLowData == null || rateHighData == null) {
      // Handle missing data, e.g., return a default or throw a more specific error
      print("Warning: Missing respiration data for sal: $salKey, temp: $tempKeyLow/$tempKeyHigh, weight: $weightKey");
      // Returning a plausible default or the closest available value might be an option
      return 0.5; // Example default, adjust as needed
    }

    // Ensure rates are doubles
    final double rateLow = (rateLowData is int) ? rateLowData.toDouble() : rateLowData;
    final double rateHigh = (rateHighData is int) ? rateHighData.toDouble() : rateHighData;

     // If tempHigh equals tempLow (e.g., at 30°C), return the rate directly
     if (tempHigh == tempLow) return rateLow;

    return _interpolate(temperature, tempLow, tempHigh, rateLow, rateHigh);
  }


  double _calculateTIR(double additionalCost, double annualSavings, double inflationRate, double analysisHorizon) {
    // Handle edge case where additionalCost is zero or negative
    if (additionalCost <= 0) {
        // TIR is infinite if savings are positive, undefined otherwise.
        // Returning a large number or specific indicator might be appropriate.
        return annualSavings > 0 ? double.infinity : double.nan;
    }

    // Newton-Raphson method
    double tir = 0.1; // Initial guess (10%)
    const int maxIterations = 100; // Reduced iterations, usually converges fast
    const double tolerance = 1e-7; // Standard tolerance

    for (int i = 0; i < maxIterations; i++) {
      double presentValue = 0.0;
      double derivative = 0.0;
      double effectiveDiscountRate = (1 + tir);

      for (int t = 1; t <= analysisHorizon; t++) {
        double discountFactor = math.pow(effectiveDiscountRate, t).toDouble();
        // Check for potential overflow with large horizons/rates
        if (discountFactor.isInfinite || discountFactor == 0) break;

        double cashFlow = annualSavings * math.pow(1 + inflationRate, t);
        presentValue += cashFlow / discountFactor;
        derivative += -t * cashFlow / (discountFactor * effectiveDiscountRate);
      }

      double f = presentValue - additionalCost; // f(TIR) = PV(Savings) - Initial Investment Difference
      if (f.isNaN || derivative.isNaN || derivative == 0) {
         // Handle cases where calculation breaks down
         print("Warning: TIR calculation encountered NaN or zero derivative.");
         return double.nan; // Indicate failure
      }

      if (f.abs() < tolerance) break; // Use f.abs() instead of math.abs(f)

      tir -= f / derivative; // Newton-Raphson update

      // Prevent TIR from going too low (e.g., below -100%) or too high unreasonably
      if (tir <= -1.0) {
        tir = -0.99; // Adjust if TIR goes below -100%
      }
      // Add upper bound check if necessary, e.g., if (tir > 10) tir = 10;
      if (tir > 10) {
        tir = 10; // Adjust if TIR goes above 100%
      }
    }

     // Check for convergence failure
     if (tir.isNaN || tir.isInfinite) {
        print("Warning: TIR calculation did not converge or resulted in NaN/Infinity.");
        return double.nan;
     }


    return tir * 100; // Convert to percentage
  }

  // --- Main Calculation Logic ---

  void _calculateEquilibrium() {
     // Get l10n instance once
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);
      appState.clearError(); // Clear previous errors

      try {
        // --- Input Parsing ---
        final temperature = double.parse(_temperatureController.text.replaceAll(',', '.'));
        final salinity = double.parse(_salinityController.text.replaceAll(',', '.'));
        final biomass = _useManualTOD ? 0.0 : double.parse(_biomassController.text.replaceAll(',', '.')); // kg/ha
        final sotr1 = double.parse(_sotr1Controller.text.replaceAll(',', '.'));
        final sotr2 = double.parse(_sotr2Controller.text.replaceAll(',', '.'));
        final price1 = double.parse(_price1Controller.text.replaceAll(',', '.'));
        final price2 = double.parse(_price2Controller.text.replaceAll(',', '.'));
        final maintenance1 = double.parse(_maintenance1Controller.text.replaceAll(',', '.'));
        final maintenance2 = double.parse(_maintenance2Controller.text.replaceAll(',', '.'));
        final durability1 = double.parse(_durability1Controller.text.replaceAll(',', '.'));
        final durability2 = double.parse(_durability2Controller.text.replaceAll(',', '.'));
        final discountRate = double.parse(_discountRateController.text.replaceAll(',', '.')) / 100.0;
        final inflationRate = double.parse(_inflationRateController.text.replaceAll(',', '.')) / 100.0;
        final analysisHorizon = double.parse(_analysisHorizonController.text.replaceAll(',', '.'));

        // Parse custom respiration rates only if toggled
        final shrimpRespirationRate = _useCustomShrimpRespiration
            ? double.parse(_shrimpRespirationController.text.replaceAll(',', '.'))
            : null;
        final waterRespirationRate = _useCustomWaterRespiration
            ? double.parse(_waterRespirationController.text.replaceAll(',', '.'))
            : null;
        final bottomRespirationRate = _useCustomBottomRespiration
            ? double.parse(_bottomRespirationController.text.replaceAll(',', '.'))
            : null;

        // --- Input Validation ---
        if (discountRate == inflationRate) {
          throw Exception(l10n.discountRateInflationRateError);
        }
        if (sotr1 <= 0 || sotr2 <= 0) { // SOTR must be positive
          throw Exception(l10n.sotrZeroError);
        }
         if (durability1 <= 0 || durability2 <= 0) { // Durability must be positive
          throw Exception("Durability must be greater than zero."); // Consider adding localization
        }


        // --- Constants & Intermediate Calculations ---
        const double energyCostPerKWh = 0.05; // USD/kWh
        const double hp1 = 3.0; // HP Aerator 1
        const double hp2 = 3.5; // HP Aerator 2
        const double hoursPerYear = 2920.0; // 8 hours/day * 365 days
        const double kwConversionFactor = 0.746; // HP to kW
        const double theta = 1.024; // Temperature correction factor
        const double standardTemp = 20.0; // °C
        const double totalHectares = 1000.0; // Standard farm size for comparison
        const double pondDepth = 1.0; // meters (Assuming standard depth, make input if variable)
        const double waterVolumePerHa = 10000.0 * pondDepth; // m³/ha
        const double bottomVolumeFactor = 0.1; // Assuming bottom layer is 10% of volume

        final double kw1 = hp1 * kwConversionFactor;
        final double kw2 = hp2 * kwConversionFactor;
        final double energyCost1 = kw1 * energyCostPerKWh * hoursPerYear; // USD/year/aerator
        final double energyCost2 = kw2 * energyCostPerKWh * hoursPerYear; // USD/year/aerator

        // Calculate OTRt (Oxygen Transfer Rate at Temperature T)
        // SOTR is Standard Oxygen Transfer Rate (kg O₂/h at 20°C, 0 DO)
        // OTR20 = SOTR * (Cs20 - C_pond) / Cs20 -> Assuming C_pond = 0 for SOTR definition
        // OTRt = OTR20 * theta^(T-20) * (CsT - C_pond) / (Cs20 - C_pond) -> Assuming C_pond = 0
        // OTRt = SOTR * theta^(T-20) * CsT / Cs20
        final double csT = _getCs100(temperature, salinity);
        final double cs20 = _getCs100(standardTemp, salinity);
        if (cs20 <= 0) throw Exception("Cannot calculate OTR: Cs at 20°C is zero or negative.");

        final double tempCorrectionFactor = math.pow(theta, temperature - standardTemp).toDouble();
        final double saturationCorrectionFactor = csT / cs20;

        otrT1 = sotr1 * tempCorrectionFactor * saturationCorrectionFactor;
        otrT2 = sotr2 * tempCorrectionFactor * saturationCorrectionFactor;

        if (otrT1! <= 0 || otrT2! <= 0) {
           throw Exception("Calculated OTR at operating temperature is zero or negative. Check inputs.");
        }


        // --- Oxygen Demand Calculation ---
        if (_useManualTOD) {
          totalDemand = double.parse(_manualTODController.text.replaceAll(',', '.')); // kg O₂/h for 1000 ha
        } else {
          // Shrimp Respiration (kg O₂/h/ha)
          final double averageWeight = 10.0; // g (Assumption)
          final double respirationRateMg_g_h = _useCustomShrimpRespiration
              ? shrimpRespirationRate!
              : _getRespirationRate(temperature, salinity, averageWeight); // mg O₂/g/h
          // Convert: (mg O₂/g/h) * (1 kg / 1e6 mg) * (biomass kg / ha * 1000 g / kg) = kg O₂ / ha / h
          shrimpDemand = respirationRateMg_g_h * biomass * 1000.0 / 1e6; // kg O₂/h/ha

          // Water Respiration (kg O₂/h/ha)
          final double waterRespirationRateMg_L_h = _useCustomWaterRespiration
              ? waterRespirationRate!
              : 0.1; // Default assumption mg/L/h
          // Convert: (mg/L/h) * (1 kg / 1e6 mg) * (waterVolumePerHa m³/ha * 1000 L/m³) = kg/h/ha
          waterDemand = waterRespirationRateMg_L_h * waterVolumePerHa * 1000.0 / 1e6; // kg O₂/h/ha

          // Bottom Respiration (kg O₂/h/ha)
           final double bottomRespirationRateMg_L_h = _useCustomBottomRespiration
              ? bottomRespirationRate!
              : 0.05; // Default assumption mg/L/h (applied to bottom volume)
           // Convert: (mg/L/h) * (1 kg / 1e6 mg) * (waterVolumePerHa * bottomVolumeFactor m³/ha * 1000 L/m³) = kg/h/ha
           bottomDemand = bottomRespirationRateMg_L_h * waterVolumePerHa * bottomVolumeFactor * 1000.0 / 1e6; // kg O₂/h/ha


          final double totalDemandPerHa = shrimpDemand! + waterDemand! + bottomDemand!;
          totalDemand = totalDemandPerHa * totalHectares; // kg O₂/h for 1000 ha
        }

        if (totalDemand! <= 0) {
           throw Exception("Total Oxygen Demand must be positive.");
        }

        // --- Aerator Unit Calculation ---
        final double totalDemandPerHa = totalDemand! / totalHectares; // kg O₂/h/ha
        // Use ceiling to ensure demand is met
        final int n1PerHa = (totalDemandPerHa / otrT1!).ceil();
        final int n2PerHa = (totalDemandPerHa / otrT2!).ceil();

        final int n1 = n1PerHa * totalHectares.toInt(); // Total units for 1000 ha
        final int n2 = n2PerHa * totalHectares.toInt(); // Total units for 1000 ha

        // --- Cost Calculation ---
        final double capitalCost1 = (price1 / durability1); // USD/year/aerator
        final double capitalCost2 = (price2 / durability2); // USD/year/aerator
        final double annualUnitCost1 = energyCost1 + maintenance1 + capitalCost1; // USD/year/aerator
        final double annualUnitCost2 = energyCost2 + maintenance2 + capitalCost2; // USD/year/aerator

        final double totalCost1 = n1 * annualUnitCost1; // Total annual cost for 1000 ha
        final double totalCost2 = n2 * annualUnitCost2; // Total annual cost for 1000 ha

        // --- Equilibrium & Financial Metrics ---
        // Equilibrium price P2 where total annual costs are equal
        // n1 * (energy1 + maint1 + price1/dur1) = n2 * (energy2 + maint2 + P2_eq/dur2)
        // Solve for P2_eq
        final double p2Equilibrium = durability2 * ( (n1 * annualUnitCost1 / n2) - (energyCost2 + maintenance2) );

        // Comparison & Savings
        final bool isAerator1MoreExpensive = totalCost1 > totalCost2;
        final double annualSavings = (totalCost1 - totalCost2).abs();
        final double initialInvestmentDiff = (n2 * price2) - (n1 * price1); // Positive if A2 costs more initially

        // Present Value of Savings (Annuity)
        double pvSavings;
        if (discountRate == inflationRate) { // Handle the case d=g
           pvSavings = annualSavings * analysisHorizon / (1 + discountRate);
        } else {
           final double effectiveRateFactor = (1 + inflationRate) / (1 + discountRate);
           pvSavings = annualSavings * ( (1 + inflationRate) / (discountRate - inflationRate) ) * (1 - math.pow(effectiveRateFactor, analysisHorizon));
        }


        // Financial Metrics
        final double k = (initialInvestmentDiff != 0) ? pvSavings / initialInvestmentDiff : double.infinity; // Profitability Index
        final double vpn = pvSavings - initialInvestmentDiff; // Net Present Value
        // Payback Period (Simple payback doesn't account for time value, using discounted payback logic)
        // Find year 't' where cumulative discounted savings >= initialInvestmentDiff
        double cumulativeDiscountedSavings = 0;
        double paybackYears = double.nan;
        for (int t = 1; t <= analysisHorizon; t++) {
            double discountedSaving = (annualSavings * math.pow(1 + inflationRate, t)) / math.pow(1 + discountRate, t);
            cumulativeDiscountedSavings += discountedSaving;
            if (cumulativeDiscountedSavings >= initialInvestmentDiff) {
                // Interpolate for fractional year if needed, or just take the year
                paybackYears = t.toDouble(); // Simple payback year
                 // Could refine with: t - 1 + (initialInvestmentDiff - (cumulativeDiscountedSavings - discountedSaving)) / discountedSaving;
                break;
            }
        }
        final double payback = paybackYears.isNaN ? double.infinity : paybackYears * 365; // Payback in days


        final double roi = (initialInvestmentDiff != 0) ? (annualSavings / initialInvestmentDiff) * 100 : double.infinity; // Simple ROI (%)
        final double tir = _calculateTIR(initialInvestmentDiff, annualSavings, inflationRate, analysisHorizon); // TIR (%)

        // Cost of Opportunity & Real Price
        final double costOfOpportunity = vpn.abs(); // The NPV represents the opportunity cost/gain
        String loserLabel;
        double realPriceLoser;
        int loserUnits;

        if (isAerator1MoreExpensive) { // Aerator 2 is better
          loserLabel = l10n.aerator1; // Aerator 1 is the 'loser'
          realPriceLoser = price1 + (vpn / n1); // Real cost of choosing A1 = its price + missed NPV
          loserUnits = n1;
        } else { // Aerator 1 is better or equal
          loserLabel = l10n.aerator2; // Aerator 2 is the 'loser'
          realPriceLoser = price2 + (vpn.abs() / n2); // Real cost of choosing A2 = its price + missed NPV
          loserUnits = n2;
        }

        // --- Prepare Data for AppState ---
        // **FIX:** Use string literals for keys
        final inputs = {
          'totalOxygenDemand': totalDemand, // Calculated or manual TOD for 1000ha
          'sotrAerator1': sotr1,
          'sotrAerator2': sotr2,
          'priceAerator1': price1,
          'priceAerator2': price2,
          'maintenanceCostAerator1': maintenance1,
          'maintenanceCostAerator2': maintenance2,
          'durabilityAerator1': durability1,
          'durabilityAerator2': durability2,
          'annualEnergyCostAerator1': energyCost1, // Per aerator
          'annualEnergyCostAerator2': energyCost2, // Per aerator
          'temperature': temperature,
          'salinity': salinity,
          'biomass': _useManualTOD ? 'N/A' : biomass,
          'shrimpRespirationRate': _useCustomShrimpRespiration ? shrimpRespirationRate : 'Dynamic',
          'waterRespirationRate': _useCustomWaterRespiration ? waterRespirationRate : 'Dynamic',
          'bottomRespirationRate': _useCustomBottomRespiration ? bottomRespirationRate : 'Dynamic',
          'discountRate': discountRate * 100,
          'inflationRate': inflationRate * 100,
          'analysisHorizon': analysisHorizon,
          'useManualTOD': _useManualTOD, // Include toggle states
          'useCustomShrimpRespiration': _useCustomShrimpRespiration,
          'useCustomWaterRespiration': _useCustomWaterRespiration,
          'useCustomBottomRespiration': _useCustomBottomRespiration,
        };

        // **FIX:** Use string literals for keys
        final results = {
          'otrTAerator1': otrT1, // kg O₂/h per aerator at temp T
          'otrTAerator2': otrT2, // kg O₂/h per aerator at temp T
          if (!_useManualTOD) 'shrimpDemandTotal': shrimpDemand! * totalHectares, // kg O₂/h for 1000 ha
          if (!_useManualTOD) 'waterDemandPerHa': waterDemand, // kg O₂/h/ha
          if (!_useManualTOD) 'bottomDemandPerHa': bottomDemand, // kg O₂/h/ha
          'numberOfAerator1Units': n1, // Units for 1000 ha
          'numberOfAerator2Units': n2, // Units for 1000 ha
          'totalAnnualCostAerator1': totalCost1, // USD/year for 1000 ha
          'totalAnnualCostAerator2': totalCost2, // USD/year for 1000 ha
          'equilibriumPriceP2': p2Equilibrium, // USD
          'actualPriceP2': price2, // USD
          'profitabilityIndex': k,
          'netPresentValue': vpn, // USD
          'paybackPeriodDays': payback.isInfinite ? 'Never' : payback.round(), // Days or Never/Infinity
          'returnOnInvestment': roi.isInfinite ? 'Infinite' : roi, // % or Infinite
          'internalRateOfReturn': tir.isNaN ? 'Undefined' : tir, // % or Undefined
          'costOfOpportunity': costOfOpportunity, // USD
          'realPriceLosingAerator': realPriceLoser, // USD
          'loserLabel': loserLabel, // Name of the less optimal aerator
          'numberOfUnitsLosingAerator': loserUnits, // Units of the less optimal aerator
        };

        // --- Update AppState ---
        appState.setResults('Aerator Comparison', results, inputs);

      } catch (e) {
         print("Calculation Error: $e"); // Log the error for debugging
         // Use l10n instance from the start of the method
         appState.setError('${l10n.calculationFailed}: ${e.toString()}');
      } finally {
         if (mounted) { // Check if widget is still mounted
           appState.setLoading(false);
         }
      }
    } else {
       // Form is not valid, optionally provide feedback
       print("Form validation failed.");
       // Optionally set loading to false if it was set true before validation
       // Provider.of<AppState>(context, listen: false).setLoading(false);
    }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Get l10n instance here for use throughout the build method
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appState.error != null
                ? Center(
                    // Use l10n instance from build method
                    child: Text('${l10n.error}: ${appState.error}',
                        style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.5, // Ensure minimum height
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Take minimum space needed
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Image.asset(
                                'assets/images/aerasync.png', // Ensure path is correct
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 100), // Placeholder
                              ),
                            ),
                          ),
                          Text(
                            // Use l10n instance from build method
                            l10n.aeratorComparisonCalculator,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Toggles ---
                                _buildToggleRow(l10n.useManualTODLabel, _useManualTOD, (value) => setState(() => _useManualTOD = value)),
                                if (_useManualTOD)
                                  _buildTextField( // Pass l10n
                                      _manualTODController,
                                      l10n.manualTODLabel, // Use localized label
                                      0,
                                      100000,
                                      l10n.manualTODTooltip, // Use localized tooltip
                                      l10n
                                   ),
                                if (!_useManualTOD) ...[
                                  _buildToggleRow(l10n.useCustomShrimpRespirationLabel, _useCustomShrimpRespiration, (value) => setState(() => _useCustomShrimpRespiration = value)),
                                  if (_useCustomShrimpRespiration)
                                    _buildTextField( // Pass l10n
                                        _shrimpRespirationController,
                                        l10n.shrimpRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.shrimpRespirationRateTooltip,
                                        l10n
                                     ),
                                  _buildToggleRow(l10n.useCustomWaterRespirationLabel, _useCustomWaterRespiration, (value) => setState(() => _useCustomWaterRespiration = value)),
                                  if (_useCustomWaterRespiration)
                                    _buildTextField( // Pass l10n
                                        _waterRespirationController,
                                        l10n.waterRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.waterRespirationRateTooltip,
                                        l10n
                                     ),
                                  _buildToggleRow(l10n.useCustomBottomRespirationLabel, _useCustomBottomRespiration, (value) => setState(() => _useCustomBottomRespiration = value)),
                                  if (_useCustomBottomRespiration)
                                    _buildTextField( // Pass l10n
                                        _bottomRespirationController,
                                        l10n.bottomRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.bottomRespirationRateTooltip,
                                        l10n
                                     ),
                                ],
                                const SizedBox(height: 10), // Spacing before main inputs
                                // --- Main Input Fields ---
                                MediaQuery.of(context).size.width < 600
                                    ? Column( // Single column layout for small screens
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _buildInputFields(l10n),
                                      )
                                    : Row( // Two-column layout for larger screens
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: Column(children: _buildInputFields(l10n, column: 1))),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(children: _buildInputFields(l10n, column: 2))),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              // Disable button if form is invalid
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                   _calculateEquilibrium();
                                } else {
                                   // Optionally show a message if form is invalid
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text(l10n.pleaseFixErrors)),
                                   );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Add horizontal padding
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                              ),
                              // Use l10n instance from build method
                              child: Text(l10n.calculateButton,
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // Helper to build toggle rows
  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
     return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align text and switch
      children: [
        Text(label, style: const TextStyle(fontSize: 16)), // Consistent font size
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1E40AF), // Theme color for switch
        ),
      ],
    );
  }


  // Helper to build list of input fields for layout flexibility
  List<Widget> _buildInputFields(AppLocalizations l10n, {int? column}) {
    final fields = [
      _buildTextField(_temperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip, l10n),
      _buildTextField(_salinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip, l10n),
      if (!_useManualTOD)
         _buildTextField(_biomassController, l10n.shrimpBiomassLabel, 0, 100000, l10n.shrimpBiomassTooltip, l10n), // Use localized labels/tooltips
      _buildTextField(_sotr1Controller, l10n.sotrAerator1Label, 0.1, 10, l10n.sotrAerator1Tooltip, l10n), // Min SOTR > 0
      _buildTextField(_sotr2Controller, l10n.sotrAerator2Label, 0.1, 10, l10n.sotrAerator2Tooltip, l10n), // Min SOTR > 0
      _buildTextField(_price1Controller, l10n.priceAerator1Label, 0, 10000, l10n.priceAerator1Tooltip, l10n),
      _buildTextField(_price2Controller, l10n.priceAerator2Label, 0, 10000, l10n.priceAerator2Tooltip, l10n),
      _buildTextField(_maintenance1Controller, l10n.maintenanceCostAerator1Label, 0, 1000, l10n.maintenanceCostAerator1Tooltip, l10n),
      _buildTextField(_maintenance2Controller, l10n.maintenanceCostAerator2Label, 0, 1000, l10n.maintenanceCostAerator2Tooltip, l10n),
      _buildTextField(_durability1Controller, l10n.durabilityAerator1Label, 0.1, 20, l10n.durabilityAerator1Tooltip, l10n), // Min Durability > 0
      _buildTextField(_durability2Controller, l10n.durabilityAerator2Label, 0.1, 20, l10n.durabilityAerator2Tooltip, l10n), // Min Durability > 0
      _buildTextField(_discountRateController, l10n.discountRateLabel, 0, 100, l10n.discountRateTooltip, l10n),
      _buildTextField(_inflationRateController, l10n.inflationRateLabel, 0, 100, l10n.inflationRateTooltip, l10n),
      _buildTextField(_analysisHorizonController, l10n.analysisHorizonLabel, 1, 50, l10n.analysisHorizonTooltip, l10n),
    ];

    if (column == null) return fields; // Return all for single column layout
    // Distribute fields between columns for two-column layout
    final List<Widget> columnFields = [];
    for (int i = 0; i < fields.length; i++) {
      if (column == 1 && i < fields.length / 2) {
        columnFields.add(fields[i]);
      } else if (column == 2 && i >= fields.length / 2) {
        columnFields.add(fields[i]);
      }
    }
    return columnFields;
  }


  // Helper method for building text fields (requires l10n)
  Widget _buildTextField(
      TextEditingController controller, String label, double min, double max, String tooltip, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Use validator that also receives l10n
              validator: (value) => _validateInput(value, min, max, label, l10n),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: tooltip,
            child: const Icon(Icons.info_outline, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Validator method (requires l10n)
  String? _validateInput(String? value, double min, double max, String label, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.requiredField;
    // Handle both comma and period for decimal separators
    final cleanedValue = value.replaceAll(',', '.');
    final numValue = double.tryParse(cleanedValue);
    if (numValue == null) return l10n.invalidNumber;
    if (numValue < min || numValue > max) return l10n.rangeError(min, max);

    // Use localized labels for specific checks
    if ((label == l10n.sotrAerator1Label || label == l10n.sotrAerator2Label) && numValue <= 0) {
      return l10n.sotrZeroError; // Ensure SOTR is positive
    }
     if ((label == l10n.durabilityAerator1Label || label == l10n.durabilityAerator2Label) && numValue <= 0) {
       return "Durability must be positive."; // Add localization if needed
     }


    // Check for integer if label matches analysis horizon
    if (label == l10n.analysisHorizonLabel && numValue != numValue.roundToDouble()) {
      return l10n.integerError;
    }

    return null; // Validation passed
  }
}

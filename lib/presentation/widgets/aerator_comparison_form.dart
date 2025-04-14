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
  final _hp1Controller = TextEditingController(text: '3.0'); // New controller for HP Aerator 1
  final _hp2Controller = TextEditingController(text: '3.5'); // New controller for HP Aerator 2
  final _price1Controller = TextEditingController(text: '500');
  final _price2Controller = TextEditingController(text: '800');
  final _maintenance1Controller = TextEditingController(text: '65');
  final _maintenance2Controller = TextEditingController(text: '50');
  final _durability1Controller = TextEditingController(text: '2');
  final _durability2Controller = TextEditingController(text: '4.5');
  final _temperatureController = TextEditingController(text: '31.5');
  final _salinityController = TextEditingController(text: '20');
  final _biomassController = TextEditingController(text: '3333.33'); // kg/ha
  final _farmSizeController = TextEditingController(text: '1000'); // New controller for farm size (ha)
  final _shrimpPriceController = TextEditingController(text: '5.0'); // New controller for shrimp price (USD/kg)
  final _discountRateController = TextEditingController(text: '10'); // %
  final _inflationRateController = TextEditingController(text: '2.5'); // %
  final _analysisHorizonController = TextEditingController(text: '9'); // years
  final _manualTODController = TextEditingController(text: '5443.7675'); // kg O₂/h for specified farm size

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

  // Intermediate values for display
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
      if (mounted) {
        setState(() {
          _saturationData = jsonDecode(saturationString);
          _respirationData = jsonDecode(respirationString);
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  @override
  void dispose() {
    _sotr1Controller.dispose();
    _sotr2Controller.dispose();
    _hp1Controller.dispose();
    _hp2Controller.dispose();
    _price1Controller.dispose();
    _price2Controller.dispose();
    _maintenance1Controller.dispose();
    _maintenance2Controller.dispose();
    _durability1Controller.dispose();
    _durability2Controller.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _biomassController.dispose();
    _farmSizeController.dispose();
    _shrimpPriceController.dispose();
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
    if ((x1 - x0) == 0) return y0;
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }

  double _getCs100(double temperature, double salinity) {
    if (_saturationData == null || _saturationData!['data'] == null) {
      throw Exception("Saturation data not loaded");
    }
    final tempIndexLow = temperature.floor().clamp(0, _saturationData!['data'].length - 2);
    final tempIndexHigh = tempIndexLow + 1;
    final salIndex = (salinity / 5).floor().clamp(0, _saturationData!['data'][0].length - 1);

    final csLow = _saturationData!['data'][tempIndexLow][salIndex];
    final csHigh = _saturationData!['data'][tempIndexHigh][salIndex];

    final double csLowDouble = (csLow is int) ? csLow.toDouble() : csLow;
    final double csHighDouble = (csHigh is int) ? csHigh.toDouble() : csHigh;

    return _interpolate(temperature, tempIndexLow.toDouble(), tempIndexHigh.toDouble(), csLowDouble, csHighDouble);
  }

  double _getRespirationRate(double temperature, double salinity, double weight) {
    if (_respirationData == null || _respirationData!['data'] == null) {
      throw Exception("Respiration data not loaded");
    }

    String salKey;
    if (salinity <= 7) salKey = "1%";
    else if (salinity <= 19) salKey = "13%";
    else if (salinity <= 31) salKey = "25%";
    else salKey = "37%";

    String tempKeyLow, tempKeyHigh;
    double tempLow, tempHigh;
    if (temperature <= 22.5) {
      tempKeyLow = "20°C";
      tempKeyHigh = "25°C";
      tempLow = 20.0;
      tempHigh = 25.0;
    } else if (temperature < 30) {
      tempKeyLow = "25°C";
      tempKeyHigh = "30°C";
      tempLow = 25.0;
      tempHigh = 30.0;
    } else {
      tempKeyLow = "30°C";
      tempKeyHigh = "30°C";
      tempLow = 30.0;
      tempHigh = 30.0;
    }

    String weightKey;
    if (weight <= 7.5) weightKey = "5g";
    else if (weight <= 12.5) weightKey = "10g";
    else if (weight <= 17.5) weightKey = "15g";
    else weightKey = "20g";

    final rateLowData = _respirationData!['data'][salKey]?[tempKeyLow]?[weightKey];
    final rateHighData = _respirationData!['data'][salKey]?[tempKeyHigh]?[weightKey];

    if (rateLowData == null || rateHighData == null) {
      print("Warning: Missing respiration data for sal: $salKey, temp: $tempKeyLow/$tempKeyHigh, weight: $weightKey");
      return 0.5;
    }

    final double rateLow = (rateLowData is int) ? rateLowData.toDouble() : rateLowData;
    final double rateHigh = (rateHighData is int) ? rateHighData.toDouble() : rateHighData;

    if (tempHigh == tempLow) return rateLow;

    return _interpolate(temperature, tempLow, tempHigh, rateLow, rateHigh);
  }

  double _calculateIRR(double additionalCost, double annualSavings, double inflationRate, double analysisHorizon) {
    if (additionalCost <= 0) {
      return annualSavings > 0 ? double.infinity : double.nan;
    }

    double irr = 0.1;
    const int maxIterations = 100;
    const double tolerance = 1e-7;

    for (int i = 0; i < maxIterations; i++) {
      double presentValue = 0.0;
      double derivative = 0.0;
      double effectiveDiscountRate = (1 + irr);

      for (int t = 1; t <= analysisHorizon; t++) {
        double discountFactor = math.pow(effectiveDiscountRate, t).toDouble();
        if (discountFactor.isInfinite || discountFactor == 0) break;

        double cashFlow = annualSavings * math.pow(1 + inflationRate, t);
        presentValue += cashFlow / discountFactor;
        derivative += -t * cashFlow / (discountFactor * effectiveDiscountRate);
      }

      double f = presentValue - additionalCost;
      if (f.isNaN || derivative.isNaN || derivative == 0) {
        print("Warning: IRR calculation encountered NaN or zero derivative.");
        return double.nan;
      }

      if (f.abs() < tolerance) break;

      irr -= f / derivative;

      if (irr <= -1.0) {
        irr = -0.99;
      }
      if (irr > 10) {
        irr = 10;
      }
    }

    if (irr.isNaN || irr.isInfinite) {
      print("Warning: IRR calculation did not converge or resulted in NaN/Infinity.");
      return double.nan;
    }

    return irr * 100;
  }

  // --- Main Calculation Logic ---

  void _calculateEquilibrium() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);
      appState.clearError();

      try {
        // --- Input Parsing ---
        final temperature = double.parse(_temperatureController.text.replaceAll(',', '.'));
        final salinity = double.parse(_salinityController.text.replaceAll(',', '.'));
        final biomass = _useManualTOD ? 0.0 : double.parse(_biomassController.text.replaceAll(',', '.')); // kg/ha
        final farmSize = double.parse(_farmSizeController.text.replaceAll(',', '.')); // ha
        final shrimpPrice = double.parse(_shrimpPriceController.text.replaceAll(',', '.')); // USD/kg
        final sotr1 = double.parse(_sotr1Controller.text.replaceAll(',', '.'));
        final sotr2 = double.parse(_sotr2Controller.text.replaceAll(',', '.'));
        final hp1 = double.parse(_hp1Controller.text.replaceAll(',', '.')); // HP Aerator 1
        final hp2 = double.parse(_hp2Controller.text.replaceAll(',', '.')); // HP Aerator 2
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
        if (sotr1 <= 0 || sotr2 <= 0) {
          throw Exception(l10n.sotrZeroError);
        }
        if (durability1 <= 0 || durability2 <= 0) {
          throw Exception(l10n.durabilityZeroError);
        }
        if (hp1 <= 0 || hp2 <= 0) {
          throw Exception(l10n.hpZeroError);
        }
        if (farmSize <= 0) {
          throw Exception(l10n.farmSizeZeroError);
        }
        if (shrimpPrice <= 0) {
          throw Exception(l10n.shrimpPriceZeroError);
        }

        // --- Constants & Intermediate Calculations ---
        const double energyCostPerKWh = 0.05; // USD/kWh
        const double hoursPerYear = 2920.0; // 8 hours/day * 365 days
        const double kwConversionFactor = 0.746; // HP to kW
        const double theta = 1.024; // Temperature correction factor
        const double standardTemp = 20.0; // °C
        const double pondDepth = 1.0; // meters
        const double waterVolumePerHa = 10000.0 * pondDepth; // m³/ha
        const double bottomVolumeFactor = 0.1; // Bottom layer is 10% of volume
        const double shrimpYieldPerHa = 5000.0; // kg/ha/year (assumption for revenue calculation)

        final double kw1 = hp1 * kwConversionFactor;
        final double kw2 = hp2 * kwConversionFactor;
        final double energyCost1 = kw1 * energyCostPerKWh * hoursPerYear; // USD/year/aerator
        final double energyCost2 = kw2 * energyCostPerKWh * hoursPerYear; // USD/year/aerator

        // Calculate OTRt
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
          totalDemand = double.parse(_manualTODController.text.replaceAll(',', '.')); // kg O₂/h for farmSize
        } else {
          // Shrimp Respiration (kg O₂/h/ha)
          final double averageWeight = 10.0; // g (assumption)
          final double respirationRateMg_g_h = _useCustomShrimpRespiration
              ? shrimpRespirationRate!
              : _getRespirationRate(temperature, salinity, averageWeight); // mg O₂/g/h
          shrimpDemand = respirationRateMg_g_h * biomass * 1000.0 / 1e6; // kg O₂/h/ha

          // Water Respiration (kg O₂/h/ha)
          final double waterRespirationRateMg_L_h = _useCustomWaterRespiration
              ? waterRespirationRate!
              : 0.1; // mg/L/h
          waterDemand = waterRespirationRateMg_L_h * waterVolumePerHa * 1000.0 / 1e6; // kg O₂/h/ha

          // Bottom Respiration (kg O₂/h/ha)
          final double bottomRespirationRateMg_L_h = _useCustomBottomRespiration
              ? bottomRespirationRate!
              : 0.05; // mg/L/h
          bottomDemand = bottomRespirationRateMg_L_h * waterVolumePerHa * bottomVolumeFactor * 1000.0 / 1e6; // kg O₂/h/ha

          final double totalDemandPerHa = shrimpDemand! + waterDemand! + bottomDemand!;
          totalDemand = totalDemandPerHa * farmSize; // kg O₂/h for farmSize
        }

        if (totalDemand! <= 0) {
          throw Exception(l10n.totalOxygenDemandZeroError);
        }

        // --- Aerator Unit Calculation ---
        final double totalDemandPerHa = totalDemand! / farmSize; // kg O₂/h/ha
        final int n1PerHa = (totalDemandPerHa / otrT1!).ceil();
        final int n2PerHa = (totalDemandPerHa / otrT2!).ceil();

        final int n1 = (n1PerHa * farmSize).ceil(); // Total units for farmSize
        final int n2 = (n2PerHa * farmSize).ceil(); // Total units for farmSize

        // --- Cost Calculation ---
        final double capitalCost1 = (price1 / durability1); // USD/year/aerator
        final double capitalCost2 = (price2 / durability2); // USD/year/aerator
        final double annualUnitCost1 = energyCost1 + maintenance1 + capitalCost1; // USD/year/aerator
        final double annualUnitCost2 = energyCost2 + maintenance2 + capitalCost2; // USD/year/aerator

        final double totalCost1 = n1 * annualUnitCost1; // Total annual cost for farmSize
        final double totalCost2 = n2 * annualUnitCost2; // Total annual cost for farmSize

        // --- Revenue Impact from Shrimp Price ---
        final double annualRevenue = shrimpPrice * shrimpYieldPerHa * farmSize; // USD/year
        final double netProfit1 = annualRevenue - totalCost1; // USD/year
        final double netProfit2 = annualRevenue - totalCost2; // USD/year

        // --- Equilibrium & Financial Metrics ---
        final double p2Equilibrium = durability2 * ((n1 * annualUnitCost1 / n2) - (energyCost2 + maintenance2));

        // Comparison & Savings
        final bool isAerator1MoreExpensive = totalCost1 > totalCost2;
        final double annualSavings = (totalCost1 - totalCost2).abs();
        final double initialInvestmentDiff = (n2 * price2) - (n1 * price1); // Positive if A2 costs more initially

        // Present Value of Savings (Annuity)
        double pvSavings;
        if (discountRate == inflationRate) {
          pvSavings = annualSavings * analysisHorizon / (1 + discountRate);
        } else {
          final double effectiveRateFactor = (1 + inflationRate) / (1 + discountRate);
          pvSavings = annualSavings * ((1 + inflationRate) / (discountRate - inflationRate)) * (1 - math.pow(effectiveRateFactor, analysisHorizon));
        }

        // Financial Metrics
        final double k = (initialInvestmentDiff != 0) ? pvSavings / initialInvestmentDiff : double.infinity; // Profitability Index
        final double vpn = pvSavings - initialInvestmentDiff; // Net Present Value
        double cumulativeDiscountedSavings = 0;
        double paybackYears = double.nan;
        for (int t = 1; t <= analysisHorizon; t++) {
          double discountedSaving = (annualSavings * math.pow(1 + inflationRate, t)) / math.pow(1 + discountRate, t);
          cumulativeDiscountedSavings += discountedSaving;
          if (cumulativeDiscountedSavings >= initialInvestmentDiff) {
            paybackYears = t.toDouble();
            break;
          }
        }
        final double payback = paybackYears.isNaN ? double.infinity : paybackYears * 365; // Payback in days

        final double roi = (initialInvestmentDiff != 0) ? (annualSavings / initialInvestmentDiff) * 100 : double.infinity; // Simple ROI (%)
        final double irr = _calculateIRR(initialInvestmentDiff, annualSavings, inflationRate, analysisHorizon); // IRR (%)

        // Cost of Opportunity & Real Price (Adjusted for Revenue Impact)
        final double costOfOpportunity = (netProfit1 - netProfit2).abs(); // Opportunity cost based on profit difference
        String loserLabel;
        double realPriceLoser;
        int loserUnits;

        if (isAerator1MoreExpensive) {
          loserLabel = l10n.aerator1;
          realPriceLoser = price1 + (costOfOpportunity / n1); // Adjusted real cost
          loserUnits = n1;
        } else {
          loserLabel = l10n.aerator2;
          realPriceLoser = price2 + (costOfOpportunity / n2); // Adjusted real cost
          loserUnits = n2;
        }

        // --- Prepare Data for AppState ---
        final inputs = {
          'totalOxygenDemand': totalDemand, // kg O₂/h for farmSize
          'farmSize': farmSize, // ha
          'shrimpPrice': shrimpPrice, // USD/kg
          'sotrAerator1': sotr1,
          'sotrAerator2': sotr2,
          'hpAerator1': hp1,
          'hpAerator2': hp2,
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
          'useManualTOD': _useManualTOD,
          'useCustomShrimpRespiration': _useCustomShrimpRespiration,
          'useCustomWaterRespiration': _useCustomWaterRespiration,
          'useCustomBottomRespiration': _useCustomBottomRespiration,
        };

        final results = {
          'otrTAerator1': otrT1, // kg O₂/h per aerator at temp T
          'otrTAerator2': otrT2, // kg O₂/h per aerator at temp T
          if (!_useManualTOD) 'shrimpDemandTotal': shrimpDemand! * farmSize, // kg O₂/h for farmSize
          if (!_useManualTOD) 'waterDemandPerHa': waterDemand, // kg O₂/h/ha
          if (!_useManualTOD) 'bottomDemandPerHa': bottomDemand, // kg O₂/h/ha
          'numberOfAerator1Units': n1, // Units for farmSize
          'numberOfAerator2Units': n2, // Units for farmSize
          'totalAnnualCostAerator1': totalCost1, // USD/year for farmSize
          'totalAnnualCostAerator2': totalCost2, // USD/year for farmSize
          'annualRevenue': annualRevenue, // USD/year
          'netProfitAerator1': netProfit1, // USD/year
          'netProfitAerator2': netProfit2, // USD/year
          'equilibriumPriceP2': p2Equilibrium, // USD
          'actualPriceP2': price2, // USD
          'profitabilityIndex': k,
          'netPresentValue': vpn, // USD
          'paybackPeriodDays': payback.isInfinite ? 'Never' : payback.round(), // Days or Never
          'returnOnInvestment': roi.isInfinite ? 'Infinite' : roi, // % or Infinite
          'internalRateOfReturn': irr.isNaN ? 'Undefined' : irr, // % or Undefined
          'costOfOpportunity': costOfOpportunity, // USD (profit-based)
          'realPriceLosingAerator': realPriceLoser, // USD
          'loserLabel': loserLabel,
          'numberOfUnitsLosingAerator': loserUnits,
        };

        appState.setResults('Aerator Comparison', results, inputs);

      } catch (e) {
        print("Calculation Error: $e");
        appState.setError('${l10n.calculationFailed}: ${e.toString()}');
      } finally {
        if (mounted) {
          appState.setLoading(false);
        }
      }
    } else {
      print("Form validation failed.");
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
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
                    child: Text('${l10n.error}: ${appState.error}',
                        style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Image.asset(
                                'assets/images/aerasync.png',
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported, size: 100),
                              ),
                            ),
                          ),
                          Text(
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
                                  _buildTextField(
                                      _manualTODController,
                                      l10n.manualTODLabel,
                                      0,
                                      100000,
                                      l10n.manualTODTooltip,
                                      l10n),
                                if (!_useManualTOD) ...[
                                  _buildToggleRow(l10n.useCustomShrimpRespirationLabel, _useCustomShrimpRespiration,
                                      (value) => setState(() => _useCustomShrimpRespiration = value)),
                                  if (_useCustomShrimpRespiration)
                                    _buildTextField(
                                        _shrimpRespirationController,
                                        l10n.shrimpRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.shrimpRespirationRateTooltip,
                                        l10n),
                                  _buildToggleRow(l10n.useCustomWaterRespirationLabel, _useCustomWaterRespiration,
                                      (value) => setState(() => _useCustomWaterRespiration = value)),
                                  if (_useCustomWaterRespiration)
                                    _buildTextField(
                                        _waterRespirationController,
                                        l10n.waterRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.waterRespirationRateTooltip,
                                        l10n),
                                  _buildToggleRow(l10n.useCustomBottomRespirationLabel, _useCustomBottomRespiration,
                                      (value) => setState(() => _useCustomBottomRespiration = value)),
                                  if (_useCustomBottomRespiration)
                                    _buildTextField(
                                        _bottomRespirationController,
                                        l10n.bottomRespirationRateLabel,
                                        0,
                                        10,
                                        l10n.bottomRespirationRateTooltip,
                                        l10n),
                                ],
                                const SizedBox(height: 10),
                                // --- Main Input Fields ---
                                MediaQuery.of(context).size.width < 600
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _buildInputFields(l10n),
                                      )
                                    : Row(
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
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _calculateEquilibrium();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.pleaseFixErrors)),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.calculateButton, style: const TextStyle(fontSize: 16)),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1E40AF),
        ),
      ],
    );
  }

  // Helper to build list of input fields for layout flexibility
  List<Widget> _buildInputFields(AppLocalizations l10n, {int? column}) {
    final fields = [
      _buildTextField(_farmSizeController, l10n.farmSizeLabel, 0.1, 10000, l10n.farmSizeTooltip, l10n),
      _buildTextField(_shrimpPriceController, l10n.shrimpPriceLabel, 0.1, 50, l10n.shrimpPriceTooltip, l10n),
      _buildTextField(_temperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip, l10n),
      _buildTextField(_salinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip, l10n),
      if (!_useManualTOD)
        _buildTextField(_biomassController, l10n.shrimpBiomassLabel, 0, 100000, l10n.shrimpBiomassTooltip, l10n),
      _buildTextField(_sotr1Controller, l10n.sotrAerator1Label, 0.1, 10, l10n.sotrAerator1Tooltip, l10n),
      _buildTextField(_hp1Controller, l10n.hpAerator1Label, 0.1, 10, l10n.hpAerator1Tooltip, l10n),
      _buildTextField(_sotr2Controller, l10n.sotrAerator2Label, 0.1, 10, l10n.sotrAerator2Tooltip, l10n),
      _buildTextField(_hp2Controller, l10n.hpAerator2Label, 0.1, 10, l10n.hpAerator2Tooltip, l10n),
      _buildTextField(_price1Controller, l10n.priceAerator1Label, 0, 10000, l10n.priceAerator1Tooltip, l10n),
      _buildTextField(_price2Controller, l10n.priceAerator2Label, 0, 10000, l10n.priceAerator2Tooltip, l10n),
      _buildTextField(_maintenance1Controller, l10n.maintenanceCostAerator1Label, 0, 1000, l10n.maintenanceCostAerator1Tooltip, l10n),
      _buildTextField(_maintenance2Controller, l10n.maintenanceCostAerator2Label, 0, 1000, l10n.maintenanceCostAerator2Tooltip, l10n),
      _buildTextField(_durability1Controller, l10n.durabilityAerator1Label, 0.1, 20, l10n.durabilityAerator1Tooltip, l10n),
      _buildTextField(_durability2Controller, l10n.durabilityAerator2Label, 0.1, 20, l10n.durabilityAerator2Tooltip, l10n),
      _buildTextField(_discountRateController, l10n.discountRateLabel, 0, 100, l10n.discountRateTooltip, l10n),
      _buildTextField(_inflationRateController, l10n.inflationRateLabel, 0, 100, l10n.inflationRateTooltip, l10n),
      _buildTextField(_analysisHorizonController, l10n.analysisHorizonLabel, 1, 50, l10n.analysisHorizonTooltip, l10n),
    ];

    if (column == null) return fields;
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

  // Helper method for building text fields
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

  // Validator method
  String? _validateInput(String? value, double min, double max, String label, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.requiredField;
    final cleanedValue = value.replaceAll(',', '.');
    final numValue = double.tryParse(cleanedValue);
    if (numValue == null) return l10n.invalidNumber;
    if (numValue < min || numValue > max) return l10n.rangeError(min, max);

    if ((label == l10n.sotrAerator1Label || label == l10n.sotrAerator2Label) && numValue <= 0) {
      return l10n.sotrZeroError;
    }
    if ((label == l10n.durabilityAerator1Label || label == l10n.durabilityAerator2Label) && numValue <= 0) {
      return l10n.durabilityZeroError;
    }
    if ((label == l10n.hpAerator1Label || label == l10n.hpAerator2Label) && numValue <= 0) {
      return l10n.hpZeroError;
    }
    if (label == l10n.farmSizeLabel && numValue <= 0) {
      return l10n.farmSizeZeroError;
    }
    if (label == l10n.shrimpPriceLabel && numValue <= 0) {
      return l10n.shrimpPriceZeroError;
    }
    if (label == l10n.analysisHorizonLabel && numValue != numValue.roundToDouble()) {
      return l10n.integerError;
    }

    return null;
  }
}
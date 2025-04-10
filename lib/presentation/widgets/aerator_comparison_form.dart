import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/generated/l10n.dart';
import '../../core/services/app_state.dart';
import 'dart:convert';
import 'dart:math' as math;
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
    final saturationString = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
    final respirationString = await rootBundle.loadString('assets/data/shrimp_respiration_salinity_temperature_weight.json');
    setState(() {
      _saturationData = jsonDecode(saturationString);
      _respirationData = jsonDecode(respirationString);
    });
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

  double _interpolate(double x, double x0, double x1, double y0, double y1) {
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }

  double _getCs100(double temperature, double salinity) {
    final tempIndexLow = temperature.floor();
    final tempIndexHigh = tempIndexLow + 1;
    final salIndex = (salinity / 5).floor();

    final csLow = _saturationData!['data'][tempIndexLow][salIndex];
    final csHigh = _saturationData!['data'][tempIndexHigh][salIndex];

    return _interpolate(temperature, tempIndexLow.toDouble(), tempIndexHigh.toDouble(), csLow, csHigh);
  }

  double _getRespirationRate(double temperature, double salinity, double weight) {
    String salKey;
    if (salinity <= 7) salKey = "1%";
    else if (salinity <= 19) salKey = "13%";
    else if (salinity <= 31) salKey = "25%";
    else salKey = "37%";

    String tempKeyLow, tempKeyHigh;
    if (temperature <= 22.5) {
      tempKeyLow = "20°C";
      tempKeyHigh = "25°C";
    } else {
      tempKeyLow = "25°C";
      tempKeyHigh = "30°C";
    }

    String weightKey;
    if (weight <= 7.5) weightKey = "5g";
    else if (weight <= 12.5) weightKey = "10g";
    else if (weight <= 17.5) weightKey = "15g";
    else weightKey = "20g";

    final rateLow = _respirationData!['data'][salKey][tempKeyLow][weightKey];
    final rateHigh = _respirationData!['data'][salKey][tempKeyHigh][weightKey];

    final tempLow = tempKeyLow == "20°C" ? 20.0 : 25.0;
    final tempHigh = tempKeyHigh == "25°C" ? 25.0 : 30.0;

    return _interpolate(temperature, tempLow, tempHigh, rateLow, rateHigh);
  }

  double _calculateTIR(double additionalCost, double annualSavings, double inflationRate, double analysisHorizon) {
    // Use Newton-Raphson method to solve for TIR
    double tir = 0.1; // Initial guess (10%)
    const maxIterations = 1000;
    const tolerance = 1e-6;

    for (int i = 0; i < maxIterations; i++) {
      double sum = 0.0;
      double derivative = 0.0;

      for (int t = 1; t <= analysisHorizon; t++) {
        double discountFactor = math.pow(1 + tir, t);
        double cashFlow = annualSavings * math.pow(1 + inflationRate, t);
        sum += cashFlow / discountFactor;
        derivative += -t * cashFlow / (discountFactor * (1 + tir));
      }

      double f = sum - additionalCost; // f(TIR) = PV - additionalCost
      if (math.abs(f) < tolerance) break;

      tir -= f / derivative; // Newton-Raphson update
      if (tir < 0) tir = 0.1; // Reset if negative
    }

    return tir * 100; // Convert to percentage
  }

  void _calculateEquilibrium() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);

      try {
        // Parse input values
        final temperature = double.parse(_temperatureController.text.replaceAll(',', ''));
        final salinity = double.parse(_salinityController.text.replaceAll(',', ''));
        final biomass = _useManualTOD ? 0 : double.parse(_biomassController.text.replaceAll(',', '')); // kg/ha
        final sotr1 = double.parse(_sotr1Controller.text.replaceAll(',', ''));
        final sotr2 = double.parse(_sotr2Controller.text.replaceAll(',', ''));
        final price1 = double.parse(_price1Controller.text.replaceAll(',', ''));
        final price2 = double.parse(_price2Controller.text.replaceAll(',', ''));
        final maintenance1 = double.parse(_maintenance1Controller.text.replaceAll(',', ''));
        final maintenance2 = double.parse(_maintenance2Controller.text.replaceAll(',', ''));
        final durability1 = double.parse(_durability1Controller.text.replaceAll(',', ''));
        final durability2 = double.parse(_durability2Controller.text.replaceAll(',', ''));
        final energyCostPerKWh = 0.05; // USD/kWh (hardcoded as per the article)
        final hp1 = 3.0; // Hardcoded for Aireador 1
        final hp2 = 3.5; // Hardcoded for Aireador 2
        final discountRate = double.parse(_discountRateController.text.replaceAll(',', '')) / 100; // Convert to decimal
        final inflationRate = double.parse(_inflationRateController.text.replaceAll(',', '')) / 100; // Convert to decimal
        final analysisHorizon = double.parse(_analysisHorizonController.text.replaceAll(',', ''));

        // Parse custom respiration rates
        final shrimpRespirationRate = _useCustomShrimpRespiration
            ? double.parse(_shrimpRespirationController.text.replaceAll(',', ''))
            : null;
        final waterRespirationRate = _useCustomWaterRespiration
            ? double.parse(_waterRespirationController.text.replaceAll(',', ''))
            : null;
        final bottomRespirationRate = _useCustomBottomRespiration
            ? double.parse(_bottomRespirationController.text.replaceAll(',', ''))
            : null;

        // Additional validation: Check if discount rate equals inflation rate
        if (discountRate == inflationRate) {
          throw Exception(AppLocalizations.of(context)!.discountRateInflationRateError);
        }

        // Additional validation: Check if SOTR values are zero
        if (sotr1 == 0 || sotr2 == 0) {
          throw Exception(AppLocalizations.of(context)!.sotrZeroError);
        }

        // Calculate energy costs based on HP
        const hoursPerYear = 2920; // 8 hours/day * 365 days
        final kw1 = hp1 * 0.746; // kW for Aireador 1
        final kw2 = hp2 * 0.746; // kW for Aireador 2
        final energyCost1 = kw1 * energyCostPerKWh * hoursPerYear; // USD/year for Aireador 1
        final energyCost2 = kw2 * energyCostPerKWh * hoursPerYear; // USD/year for Aireador 2

        // Calculate OTRt with corrected formula including temperature adjustment
        final cs100Ref = _getCs100(20, salinity); // 20°C, experiment salinity
        final cs50 = cs100Ref * 0.5; // Target at 50% saturation
        final otrFactor = (cs100Ref - cs50) / cs100Ref; // Should be 0.5
        final otr20_1 = sotr1 * otrFactor;
        final otr20_2 = sotr2 * otrFactor;

        // Apply temperature correction
        const theta = 1.024;
        const standardTemp = 20.0;
        final tempCorrection = math.pow(theta, standardTemp - temperature);
        otrT1 = otr20_1 * tempCorrection;
        otrT2 = otr20_2 * tempCorrection;

        // Calculate oxygen demand
        if (_useManualTOD) {
          totalDemand = double.parse(_manualTODController.text.replaceAll(',', ''));
        } else {
          // Shrimp respiration
          final averageWeight = 10.0; // g (assumed average over cycle)
          final respirationRate = _useCustomShrimpRespiration
              ? shrimpRespirationRate!
              : _getRespirationRate(temperature, salinity, averageWeight);
          shrimpDemand = (biomass * 1000) * respirationRate / 1000; // kg/ha/h

          // Pond demand: split into water and bottom
          final cs100 = _getCs100(temperature, salinity); // At operating conditions
          final cs50Target = cs100 * 0.5;
          final cs25 = cs100 * 0.25; // For bottom respiration

          // Water respiration
          if (_useCustomWaterRespiration) {
            waterDemand = waterRespirationRate! * 10000000 / 1000; // mg/L/h to kg/ha/h
          } else {
            waterDemand = (cs100 - cs50Target) * 10000000 / 1000 / 8; // kg/ha/h over 8 hours
          }

          // Bottom respiration
          final bottomVolume = 1000000; // 10% of water volume
          if (_useCustomBottomRespiration) {
            bottomDemand = bottomRespirationRate! * bottomVolume / 1000; // mg/L/h to kg/ha/h
          } else {
            bottomDemand = (cs50Target - cs25) * bottomVolume / 1000 / 8; // kg/ha/h over 8 hours
          }

          final pondDemand = waterDemand! + bottomDemand!;
          final totalDemandPerHa = shrimpDemand! + pondDemand;
          const totalHectares = 1000;
          totalDemand = totalDemandPerHa * totalHectares;
        }

        // Calculate number of aerators per hectare
        final totalDemandPerHa = totalDemand! / 1000;
        final n1PerHa = (totalDemandPerHa / otrT1!).ceil();
        final n2PerHa = (totalDemandPerHa / otrT2!).ceil();

        // Total for 1000 ha
        final n1 = n1PerHa * 1000;
        final n2 = n2PerHa * 1000;

        // Calculate total annual costs
        final totalCost1 = n1 * (energyCost1 + maintenance1 + (price1 / durability1));
        final totalCost2 = n2 * (energyCost2 + maintenance2 + (price2 / durability2));

        // Calculate equilibrium price P2
        final p2Equilibrium = (durability2 / otrT1!) *
            (otrT2! * (energyCost1 + maintenance1 + (price1 / durability1)) -
                otrT1! * (energyCost2 + maintenance2));

        // Determine the loser and calculate savings
        bool isAerator1Loser = totalCost1 > totalCost2;
        final annualSavings = isAerator1Loser ? (totalCost1 - totalCost2) : (totalCost2 - totalCost1);
        final additionalCost = (n2 * price2) - (n1 * price1);

        // Calculate present value of savings (PV of savings)
        final factor = (1 + inflationRate) * (1 - (math.pow((1 + inflationRate) / (1 + discountRate), analysisHorizon))) / (discountRate - inflationRate);
        final pvSavings = annualSavings * factor;

        // Calculate coefficient of profitability k
        final k = additionalCost != 0 ? pvSavings / additionalCost : 0;

        // Calculate additional financial metrics
        final vpn = pvSavings - additionalCost;
        final payback = (factor / k) * 365; // Convert to days
        final roi = (additionalCost != 0) ? (annualSavings / additionalCost) * 100 : 0;
        final tir = _calculateTIR(additionalCost, annualSavings, inflationRate, analysisHorizon);

        // Calculate cost of opportunity and real price dynamically
        double costOfOpportunity;
        String loserLabel;
        double realPriceLoser;
        int loserUnits;

        if (isAerator1Loser) {
          costOfOpportunity = pvSavings; // Savings from choosing Aireador 2
          loserLabel = 'Aerator 1';
          realPriceLoser = price1 + (pvSavings / n1);
          loserUnits = n1;
        } else {
          costOfOpportunity = pvSavings; // Savings from choosing Aireador 1
          loserLabel = 'Aerator 2';
          realPriceLoser = price2 + (pvSavings / n2);
          loserUnits = n2;
        }

        // Inputs for CSV download
        final inputs = {
          AppLocalizations.of(context)!.totalOxygenDemandLabel: totalDemand,
          AppLocalizations.of(context)!.sotrAerator1Label: sotr1,
          AppLocalizations.of(context)!.sotrAerator2Label: sotr2,
          AppLocalizations.of(context)!.priceAerator1Label: price1,
          AppLocalizations.of(context)!.priceAerator2Label: price2,
          AppLocalizations.of(context)!.maintenanceCostAerator1Label: maintenance1,
          AppLocalizations.of(context)!.maintenanceCostAerator2Label: maintenance2,
          AppLocalizations.of(context)!.durabilityAerator1Label: durability1,
          AppLocalizations.of(context)!.durabilityAerator2Label: durability2,
          'Annual Energy Cost Aerator 1 (USD/year per aerator)': energyCost1,
          'Annual Energy Cost Aerator 2 (USD/year per aerator)': energyCost2,
          'Temperature (°C)': temperature,
          'Salinity (ppt)': salinity,
          'Biomass (kg/ha)': _useManualTOD ? 'N/A' : biomass,
          'Shrimp Respiration Rate (mg O₂/g/h)': _useCustomShrimpRespiration ? shrimpRespirationRate : 'Dynamic',
          'Water Respiration Rate (mg/L/h)': _useCustomWaterRespiration ? waterRespirationRate : 'Dynamic',
          'Bottom Respiration Rate (mg/L/h)': _useCustomBottomRespiration ? bottomRespirationRate : 'Dynamic',
          'Discount Rate (%)': discountRate * 100,
          'Inflation Rate (%)': inflationRate * 100,
          'Analysis Horizon (years)': analysisHorizon,
        };

        // Results for display
        final results = {
          'OTR_T Aerator 1 (kg O₂/h)': otrT1,
          'OTR_T Aerator 2 (kg O₂/h)': otrT2,
          if (!_useManualTOD) 'Shrimp Demand (kg O₂/h for 1000 ha)': shrimpDemand! * 1000,
          if (!_useManualTOD) 'Water Demand (kg O₂/h/ha)': waterDemand,
          if (!_useManualTOD) 'Bottom Demand (kg O₂/h/ha)': bottomDemand,
          AppLocalizations.of(context)!.numberOfAerator1UnitsLabel: n1,
          AppLocalizations.of(context)!.numberOfAerator2UnitsLabel: n2,
          AppLocalizations.of(context)!.totalAnnualCostAerator1Label: totalCost1,
          AppLocalizations.of(context)!.totalAnnualCostAerator2Label: totalCost2,
          AppLocalizations.of(context)!.equilibriumPriceP2Label: p2Equilibrium,
          AppLocalizations.of(context)!.actualPriceP2Label: price2,
          'Coefficient of Profitability (k)': k,
          'VPN (USD)': vpn,
          'Payback (days)': payback,
          'ROI (%)': roi,
          'TIR (%)': tir,
          'Cost of Opportunity (USD)': costOfOpportunity,
          'Real Price of Losing Aerator (USD) ($loserLabel)': realPriceLoser,
          'Number of Units of Losing Aerator': loserUnits,
        };

        appState.setResults('Aerator Comparison', results, inputs);
      } catch (e) {
        appState.setError('${AppLocalizations.of(context)!.calculationFailed}: $e');
      } finally {
        appState.setLoading(false);
      }
    }
  }

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
                                // Toggle for manual vs dynamic TOD
                                Row(
                                  children: [
                                    Text(l10n.useManualTODLabel),
                                    Switch(
                                      value: _useManualTOD,
                                      onChanged: (value) {
                                        setState(() {
                                          _useManualTOD = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_useManualTOD)
                                  _buildTextField(
                                      _manualTODController,
                                      'Manual Total Oxygen Demand (kg O₂/h for 1000 ha)',
                                      0,
                                      100000),
                                if (!_useManualTOD) ...[
                                  // Toggle for custom shrimp respiration
                                  Row(
                                    children: [
                                      Text('Use Custom Shrimp Respiration Rate'),
                                      Switch(
                                        value: _useCustomShrimpRespiration,
                                        onChanged: (value) {
                                          setState(() {
                                            _useCustomShrimpRespiration = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_useCustomShrimpRespiration)
                                    _buildTextField(
                                        _shrimpRespirationController,
                                        'Shrimp Respiration Rate (mg O₂/g/h)',
                                        0,
                                        10),
                                  // Toggle for custom water respiration
                                  Row(
                                    children: [
                                      Text('Use Custom Water Respiration Rate'),
                                      Switch(
                                        value: _useCustomWaterRespiration,
                                        onChanged: (value) {
                                          setState(() {
                                            _useCustomWaterRespiration = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_useCustomWaterRespiration)
                                    _buildTextField(
                                        _waterRespirationController,
                                        'Water Respiration Rate (mg/L/h)',
                                        0,
                                        10),
                                  // Toggle for custom bottom respiration
                                  Row(
                                    children: [
                                      Text('Use Custom Bottom Respiration Rate'),
                                      Switch(
                                        value: _useCustomBottomRespiration,
                                        onChanged: (value) {
                                          setState(() {
                                            _useCustomBottomRespiration = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_useCustomBottomRespiration)
                                    _buildTextField(
                                        _bottomRespirationController,
                                        'Bottom Respiration Rate (mg/L/h)',
                                        0,
                                        10),
                                ],
                                MediaQuery.of(context).size.width < 600
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildTextField(_temperatureController,
                                              'Temperature (°C)', 0, 40),
                                          _buildTextField(_salinityController,
                                              'Salinity (ppt)', 0, 40),
                                          if (!_useManualTOD)
                                            _buildTextField(_biomassController,
                                                'Biomass (kg/ha)', 0, 100000),
                                          _buildTextField(_sotr1Controller,
                                              l10n.sotrAerator1Label, 0, 10),
                                          _buildTextField(_sotr2Controller,
                                              l10n.sotrAerator2Label, 0, 10),
                                          _buildTextField(_price1Controller,
                                              l10n.priceAerator1Label, 0, 10000),
                                          _buildTextField(_price2Controller,
                                              l10n.priceAerator2Label, 0, 10000),
                                          _buildTextField(
                                              _maintenance1Controller,
                                              l10n.maintenanceCostAerator1Label,
                                              0,
                                              1000),
                                          _buildTextField(
                                              _maintenance2Controller,
                                              l10n.maintenanceCostAerator2Label,
                                              0,
                                              1000),
                                          _buildTextField(_durability1Controller,
                                              l10n.durabilityAerator1Label, 0.1, 20),
                                          _buildTextField(_durability2Controller,
                                              l10n.durabilityAerator2Label, 0.1, 20),
                                          _buildTextField(_discountRateController,
                                              'Discount Rate (%)', 0, 100),
                                          _buildTextField(_inflationRateController,
                                              'Inflation Rate (%)', 0, 100),
                                          _buildTextField(_analysisHorizonController,
                                              'Analysis Horizon (years)', 1, 50),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                _buildTextField(_temperatureController,
                                                    'Temperature (°C)', 0, 40),
                                                _buildTextField(_salinityController,
                                                    'Salinity (ppt)', 0, 40),
                                                if (!_useManualTOD)
                                                  _buildTextField(
                                                      _biomassController,
                                                      'Biomass (kg/ha)',
                                                      0,
                                                      100000),
                                                _buildTextField(_sotr1Controller,
                                                    l10n.sotrAerator1Label, 0, 10),
                                                _buildTextField(_sotr2Controller,
                                                    l10n.sotrAerator2Label, 0, 10),
                                                _buildTextField(_price1Controller,
                                                    l10n.priceAerator1Label, 0, 10000),
                                                _buildTextField(_price2Controller,
                                                    l10n.priceAerator2Label, 0, 10000),
                                                _buildTextField(_discountRateController,
                                                    'Discount Rate (%)', 0, 100),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                _buildTextField(
                                                    _maintenance1Controller,
                                                    l10n.maintenanceCostAerator1Label,
                                                    0,
                                                    1000),
                                                _buildTextField(
                                                    _maintenance2Controller,
                                                    l10n.maintenanceCostAerator2Label,
                                                    0,
                                                    1000),
                                                _buildTextField(
                                                    _durability1Controller,
                                                    l10n.durabilityAerator1Label,
                                                    0.1,
                                                    20),
                                                _buildTextField(
                                                    _durability2Controller,
                                                    l10n.durabilityAerator2Label,
                                                    0.1,
                                                    20),
                                                _buildTextField(
                                                    _inflationRateController,
                                                    'Inflation Rate (%)',
                                                    0,
                                                    100),
                                                _buildTextField(
                                                    _analysisHorizonController,
                                                    'Analysis Horizon (years)',
                                                    1,
                                                    50),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              onPressed: _formKey.currentState!.validate()
                                  ? _calculateEquilibrium
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                              ),
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

  Widget _buildTextField(
      TextEditingController controller, String label, double min, double max) {
    final l10n = AppLocalizations.of(context)!;
    String tooltip;
    switch (label) {
      case 'Temperature (°C)':
        tooltip = 'Temperature of the pond water in degrees Celsius';
        break;
      case 'Salinity (ppt)':
        tooltip = 'Salinity of the pond water in parts per thousand';
        break;
      case 'Biomass (kg/ha)':
        tooltip = 'Shrimp biomass per hectare in kilograms';
        break;
      case 'Manual Total Oxygen Demand (kg O₂/h for 1000 ha)':
        tooltip = 'Manually specified total oxygen demand for 1000 hectares';
        break;
      case 'Shrimp Respiration Rate (mg O₂/g/h)':
        tooltip = 'Custom respiration rate for shrimp in mg O₂ per gram per hour';
        break;
      case 'Water Respiration Rate (mg/L/h)':
        tooltip = 'Custom respiration rate for water in mg O₂ per liter per hour';
        break;
      case 'Bottom Respiration Rate (mg/L/h)':
        tooltip = 'Custom respiration rate for bottom in mg O₂ per liter per hour';
        break;
      case 'SOTR Aerator 1 (kg O₂/h per aerator)':
        tooltip = l10n.sotrAerator1Tooltip;
        break;
      case 'SOTR Aerator 2 (kg O₂/h per aerator)':
        tooltip = l10n.sotrAerator2Tooltip;
        break;
      case 'Price Aerator 1 (USD per aerator)':
        tooltip = l10n.priceAerator1Tooltip;
        break;
      case 'Price Aerator 2 (USD per aerator)':
        tooltip = l10n.priceAerator2Tooltip;
        break;
      case 'Maintenance Cost Aerator 1 (USD/year per aerator)':
        tooltip = l10n.maintenanceCostAerator1Tooltip;
        break;
      case 'Maintenance Cost Aerator 2 (USD/year per aerator)':
        tooltip = l10n.maintenanceCostAerator2Tooltip;
        break;
      case 'Durability Aerator 1 (years)':
        tooltip = l10n.durabilityAerator1Tooltip;
        break;
      case 'Durability Aerator 2 (years)':
        tooltip = l10n.durabilityAerator2Tooltip;
        break;
      case 'Discount Rate (%)':
        tooltip = 'Annual discount rate for present value calculations';
        break;
      case 'Inflation Rate (%)':
        tooltip = 'Annual inflation rate for cost adjustments';
        break;
      case 'Analysis Horizon (years)':
        tooltip = 'Time horizon for the financial analysis';
        break;
      default:
        tooltip = '';
    }

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
              validator: (value) => _validateInput(value, min, max, label),
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

  String? _validateInput(String? value, double min, double max, String label) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredField;
    final numValue = double.tryParse(value);
    if (numValue == null) return AppLocalizations.of(context)!.invalidNumber;
    if (numValue < min || numValue > max) return AppLocalizations.of(context)!.rangeError(min, max);

    // Additional validation for SOTR to prevent zero values
    if ((label == AppLocalizations.of(context)!.sotrAerator1Label || label == AppLocalizations.of(context)!.sotrAerator2Label) && numValue == 0) {
      return AppLocalizations.of(context)!.sotrZeroError;
    }

    // Additional validation for Analysis Horizon to ensure it's an integer
    if (label == 'Analysis Horizon (years)' && numValue != numValue.roundToDouble()) {
      return AppLocalizations.of(context)!.integerError;
    }

    return null;
  }
}
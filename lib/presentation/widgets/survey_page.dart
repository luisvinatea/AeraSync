import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_state.dart';
import './results_page.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  int _currentStep = 0;
  bool _showResults = false;
  bool _dataCollectionConsent = false;

  final List<Map<String, dynamic>> _aerators = [];
  final _aeratorFormKeys = <GlobalKey<FormState>>[];

  final _farmFormKey = GlobalKey<FormState>();
  final _totalAreaController = TextEditingController(text: '1000');
  final _productionPerHaController = TextEditingController(text: '5000');
  final _cyclesPerYearController = TextEditingController(text: '2');
  final _temperatureController = TextEditingController(text: '31.5');
  final _salinityController = TextEditingController(text: '20');
  final _pondDepthController = TextEditingController(text: '1.0');
  final _shrimpWeightController = TextEditingController(text: '15');
  final _biomassController = TextEditingController(text: '2000');
  final _safetyMarginController = TextEditingController(text: '1.2');

  final _financialFormKey = GlobalKey<FormState>();
  final _shrimpPriceController = TextEditingController(text: '5.0');
  final _energyCostController = TextEditingController(text: '0.05');
  final _operatingHoursController = TextEditingController(text: '8');
  final _discountRateController = TextEditingController(text: '10');
  final _inflationRateController = TextEditingController(text: '2.5');
  final _analysisHorizonController = TextEditingController(text: '9');

  @override
  void initState() {
    super.initState();
    _addAerator();
  }

  @override
  void dispose() {
    _totalAreaController.dispose();
    _productionPerHaController.dispose();
    _cyclesPerYearController.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _pondDepthController.dispose();
    _shrimpWeightController.dispose();
    _biomassController.dispose();
    _safetyMarginController.dispose();
    _shrimpPriceController.dispose();
    _energyCostController.dispose();
    _operatingHoursController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _analysisHorizonController.dispose();
    for (var aerator in _aerators) {
      aerator['brandController'].dispose();
      aerator['modelController'].dispose();
      aerator['typeController'].dispose();
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
      aerator['klatController'].dispose();
      aerator['costController'].dispose();
      aerator['durabilityController'].dispose();
      aerator['maintenanceController'].dispose();
    }
    _aerators.clear();
    super.dispose();
  }

  void _addAerator() {
    setState(() {
      _aerators.add({
        'formKey': GlobalKey<FormState>(),
        'brandController': TextEditingController(),
        'modelController': TextEditingController(),
        'typeController': TextEditingController(),
        'powerController': TextEditingController(text: '3.0'),
        'sotrSource': 'supplier',
        'sotrController': TextEditingController(text: '1.4'),
        'klatController': TextEditingController(),
        'costController': TextEditingController(text: '500'),
        'durabilityController': TextEditingController(text: '2'),
        'maintenanceController': TextEditingController(text: '65'),
      });
      _aeratorFormKeys.add(_aerators.last['formKey']);
    });
  }

  void _removeAerator(int index) {
    setState(() {
      final aerator = _aerators[index];
      aerator['brandController'].dispose();
      aerator['modelController'].dispose();
      aerator['typeController'].dispose();
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
      aerator['klatController'].dispose();
      aerator['costController'].dispose();
      aerator['durabilityController'].dispose();
      aerator['maintenanceController'].dispose();
      _aerators.removeAt(index);
      _aeratorFormKeys.removeAt(index);
    });
  }

  bool _validateStep(int step) {
    final l10n = AppLocalizations.of(context)!;
    if (step == 0) {
      bool allValid = true;
      for (var formKey in _aeratorFormKeys) {
        if (!formKey.currentState!.validate()) {
          allValid = false;
        }
      }
      if (_aerators.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.minimumAeratorsError)),
        );
        return false;
      }
      return allValid;
    } else if (step == 1) {
      return _farmFormKey.currentState!.validate();
    } else if (step == 2) {
      if (!_dataCollectionConsent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.consentRequiredError)),
        );
        return false;
      }
      return _financialFormKey.currentState!.validate();
    }
    return true;
  }

  Future<void> _submitSurvey() async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setLoading(true);

    try {
      final aerators = _aerators.map((aerator) {
        return {
          'brand': aerator['brandController'].text.isEmpty
              ? null
              : aerator['brandController'].text,
          'model': aerator['modelController'].text.isEmpty
              ? null
              : aerator['modelController'].text,
          'type': aerator['typeController'].text.isEmpty
              ? null
              : aerator['typeController'].text,
          'power': double.parse(aerator['powerController'].text),
          'sotrSource': aerator['sotrSource'],
          'sotr': aerator['sotrSource'] == 'supplier'
              ? double.parse(aerator['sotrController'].text)
              : null,
          'klat': aerator['sotrSource'] == 'experimental'
              ? double.parse(aerator['klatController'].text)
              : null,
          'cost': double.parse(aerator['costController'].text),
          'durability': double.parse(aerator['durabilityController'].text),
          'maintenance': double.parse(aerator['maintenanceController'].text),
        };
      }).toList();

      final farmData = {
        'totalArea': double.parse(_totalAreaController.text),
        'productionPerHa': double.parse(_productionPerHaController.text),
        'cyclesPerYear': double.parse(_cyclesPerYearController.text),
      };

      final oxygenDemandData = {
        'temperature': double.parse(_temperatureController.text),
        'salinity': double.parse(_salinityController.text),
        'pondDepth': double.parse(_pondDepthController.text),
        'shrimpWeight': double.parse(_shrimpWeightController.text),
        'biomass': double.parse(_biomassController.text),
        'safetyMargin': double.parse(_safetyMarginController.text),
      };

      final financialData = {
        'shrimpPrice': double.parse(_shrimpPriceController.text),
        'energyCost': double.parse(_energyCostController.text),
        'operatingHours': double.parse(_operatingHoursController.text),
        'discountRate': double.parse(_discountRateController.text),
        'inflationRate': double.parse(_inflationRateController.text),
        'analysisHorizon': double.parse(_analysisHorizonController.text),
      };

      final requestBody = {
        'temperature': oxygenDemandData['temperature'],
        'salinity': oxygenDemandData['salinity'],
        'total_area': farmData['totalArea'],
        'pond_depth': oxygenDemandData['pondDepth'],
        'biomass_kg_ha': oxygenDemandData['biomass'],
        'safety_margin': oxygenDemandData['safetyMargin'],
        'shrimp_weight': oxygenDemandData['shrimpWeight'],
        'shrimp_density_kg_ha': farmData['productionPerHa'],
        'shrimp_price_usd_kg': financialData['shrimpPrice'],
        'cycles_per_year': farmData['cyclesPerYear'],
        'power1': aerators[0]['power'],
        'power2': aerators[1]['power'],
        'sotr1':
            aerators[0]['sotrSource'] == 'supplier' ? aerators[0]['sotr'] : 0.0,
        'sotr2':
            aerators[1]['sotrSource'] == 'supplier' ? aerators[1]['sotr'] : 0.0,
        'price1': aerators[0]['cost'],
        'price2': aerators[1]['cost'],
        'maintenance1': aerators[0]['maintenance'],
        'maintenance2': aerators[1]['maintenance'],
        'durability1': aerators[0]['durability'],
        'durability2': aerators[1]['durability'],
        'energy_cost': financialData['energyCost'],
        'operating_hours': financialData['operatingHours'],
        'discount_rate_pct': financialData['discountRate'],
        'inflation_rate_pct': financialData['inflationRate'],
        'analysis_horizon_years': financialData['analysisHorizon']?.toInt(),
        'use_manual_tod': false,
        'manual_tod_value': 0.0,
        'use_custom_shrimp': false,
        'custom_shrimp_rate': 0.0,
        'use_custom_water': false,
        'custom_water_rate': 0.0,
        'use_custom_bottom': false,
        'custom_bottom_rate': 0.0,
        'brand1': aerators[0]['brand'],
        'type1': aerators[0]['type'],
        'brand2': aerators[1]['brand'],
        'type2': aerators[1]['type'],
      };

      const apiUrl =
          String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
      final response = await http.post(
        Uri.parse('$apiUrl/compare-aerators'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('API call failed: ${response.statusCode}');
      }

      final apiResults = jsonDecode(response.body) as Map<String, dynamic>;
      final annualRevenue = (apiResults['computedAnnualRevenue'] as num?)?.toDouble() ?? 0.0;
      final tod = (apiResults['totalOxygenDemand'] as num?)?.toDouble() ?? 0.0;
      final shrimpDemand = (apiResults['shrimpDemand'] as num?)?.toDouble();
      final envDemand = (apiResults['envDemand'] as num?)?.toDouble();

      final aeratorResults = [
        {
          'name':
              '${aerators[0]['brand'] ?? 'Unknown'} ${aerators[0]['model'] ?? 'Aerator'}',
          'type': aerators[0]['type'],
          'numAerators': (apiResults['numberOfAerator1Units'] as num?)?.toDouble() ?? 0.0,
          'totalAnnualCost':
              (apiResults['totalAnnualCostAerator1'] as num?)?.toDouble() ?? 0.0,
          'costPercentage': annualRevenue > 0
              ? (((apiResults['totalAnnualCostAerator1'] as num?)?.toDouble() ?? 0.0) /
                      annualRevenue) *
                  100
              : 0.0,
          'sae': aerators[0]['power'] > 0
              ? ((apiResults['otrtAerator1'] as num?)?.toDouble() ?? 0.0) /
                  (aerators[0]['power'] * 0.746)
              : 0.0,
          'npv': (apiResults['netPresentValue'] as num?)?.toDouble() ?? 0.0,
          'irr': 15.0,
          'paybackPeriod': 365.0,
          'roi': 20.0,
          'profitabilityIndex': apiResults['profitabilityIndex'] is String
              ? double.infinity
              : (apiResults['profitabilityIndex'] as num?)?.toDouble() ?? 0.0,
        },
        {
          'name':
              '${aerators[1]['brand'] ?? 'Unknown'} ${aerators[1]['model'] ?? 'Aerator'}',
          'type': aerators[1]['type'],
          'numAerators': (apiResults['numberOfAerator2Units'] as num?)?.toDouble() ?? 0.0,
          'totalAnnualCost':
              (apiResults['totalAnnualCostAerator2'] as num?)?.toDouble() ?? 0.0,
          'costPercentage': annualRevenue > 0
              ? (((apiResults['totalAnnualCostAerator2'] as num?)?.toDouble() ?? 0.0) /
                      annualRevenue) *
                  100
              : 0.0,
          'sae': aerators[1]['power'] > 0
              ? ((apiResults['otrtAerator2'] as num?)?.toDouble() ?? 0.0) /
                  (aerators[1]['power'] * 0.746)
              : 0.0,
          'npv': (apiResults['netPresentValue'] as num?)?.toDouble() ?? 0.0,
          'irr': 15.0,
          'paybackPeriod': 365.0,
          'roi': 20.0,
          'profitabilityIndex': apiResults['profitabilityIndex'] is String
              ? double.infinity
              : (apiResults['profitabilityIndex'] as num?)?.toDouble() ?? 0.0,
        },
      ];

      aeratorResults.sort((a, b) => (b['profitabilityIndex'] as double)
          .compareTo(a['profitabilityIndex'] as double));

      final surveyData = {
        'aerators': aerators,
        'farmData': farmData,
        'oxygenDemandData': oxygenDemandData,
        'financialData': financialData,
        'aeratorResults': aeratorResults,
        'tod': tod,
        'shrimpDemand': shrimpDemand,
        'envDemand': envDemand,
        'annualRevenue': annualRevenue,
        'apiResults': apiResults,
      };

      appState.setSurveyData(surveyData);
      setState(() {
        _showResults = true;
      });
    } catch (e) {
      appState.setError('Failed to process survey: $e');
    } finally {
      appState.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    if (_showResults) {
      return const ResultsWidget();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appState.error != null
                ? Center(
                    child: Text(
                      appState.error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_validateStep(_currentStep)) {
                          if (_currentStep < 2) {
                            setState(() {
                              _currentStep += 1;
                            });
                          } else {
                            _submitSurvey();
                          }
                        }
                      },
                      onStepCancel: _currentStep > 0
                          ? () {
                              setState(() {
                                _currentStep -= 1;
                              });
                            }
                          : null,
                      controlsBuilder: (context, details) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: Text(
                                  l10n.back,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              child: Text(_currentStep == 2 ? l10n.submit : l10n.next),
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: Text(
                            l10n.aeratorDetails,
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Column(
                            children: [
                              ..._aerators.asMap().entries.map((entry) {
                                final index = entry.key;
                                final aerator = entry.value;
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Form(
                                      key: aerator['formKey'],
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${l10n.aerator1} ${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E40AF),
                                                ),
                                              ),
                                              if (_aerators.length > 2)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () => _removeAerator(index),
                                                ),
                                            ],
                                          ),
                                          _buildTextField(
                                            aerator['brandController'],
                                            l10n.brandLabel,
                                            0,
                                            double.infinity,
                                            l10n.brandTooltip,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['modelController'],
                                            l10n.modelLabel,
                                            0,
                                            double.infinity,
                                            l10n.specifyAeratorTypeLabel,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['typeController'],
                                            l10n.aeratorTypeLabel,
                                            0,
                                            double.infinity,
                                            l10n.aeratorTypeTooltip,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['powerController'],
                                            l10n.horsepowerLabel,
                                            0.1,
                                            100,
                                            l10n.horsepowerTooltip,
                                            l10n,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                l10n.sotrSourceLabel,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'supplier',
                                                    groupValue: aerator['sotrSource'],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        aerator['sotrSource'] = value!;
                                                      });
                                                    },
                                                    activeColor: const Color(0xFF1E40AF),
                                                  ),
                                                  const Text('Supplier'),
                                                  Radio<String>(
                                                    value: 'experimental',
                                                    groupValue: aerator['sotrSource'],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        aerator['sotrSource'] = value!;
                                                      });
                                                    },
                                                    activeColor: const Color(0xFF1E40AF),
                                                  ),
                                                  const Text('Experimental'),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (aerator['sotrSource'] == 'supplier')
                                            _buildTextField(
                                              aerator['sotrController'],
                                              l10n.sotrLabel,
                                              0.1,
                                              10,
                                              l10n.sotrTooltip,
                                              l10n,
                                            ),
                                          if (aerator['sotrSource'] == 'experimental')
                                            _buildTextField(
                                              aerator['klatController'],
                                              l10n.klatLabel,
                                              0.1,
                                              100,
                                              l10n.klatTooltip,
                                              l10n,
                                            ),
                                          _buildTextField(
                                            aerator['costController'],
                                            l10n.priceLabel,
                                            0,
                                            10000,
                                            l10n.priceAerator1Tooltip,
                                            l10n,
                                          ),
                                          _buildTextField(
                                            aerator['durabilityController'],
                                            l10n.durabilityLabel,
                                            0.1,
                                            20,
                                            l10n.durabilityAerator1Tooltip,
                                            l10n,
                                          ),
                                          _buildTextField(
                                            aerator['maintenanceController'],
                                            l10n.maintenanceCostLabel,
                                            0,
                                            1000,
                                            l10n.maintenanceCostAerator1Tooltip,
                                            l10n,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Center(
                                child: TextButton(
                                  onPressed: _addAerator,
                                  child: Text(
                                    l10n.addAerator,
                                    style: const TextStyle(color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: Text(
                            l10n.farmAndOxygenDemand,
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white.withValues(alpha: 0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Form(
                                key: _farmFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      _totalAreaController,
                                      l10n.farmAreaLabel,
                                      0.1,
                                      100000,
                                      l10n.farmAreaTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _productionPerHaController,
                                      l10n.productionPerHaLabel,
                                      0,
                                      100000,
                                      l10n.productionPerHaTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _cyclesPerYearController,
                                      l10n.cyclesPerYearLabel,
                                      1,
                                      10,
                                      l10n.cyclesPerYearTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _temperatureController,
                                      l10n.waterTemperatureLabel,
                                      0,
                                      40,
                                      l10n.waterTemperatureTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _salinityController,
                                      l10n.salinityLabel,
                                      0,
                                      40,
                                      l10n.salinityTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _pondDepthController,
                                      l10n.pondDepthLabel,
                                      0.5,
                                      5,
                                      l10n.pondDepthTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _shrimpWeightController,
                                      l10n.averageShrimpWeightLabel,
                                      0,
                                      50,
                                      l10n.averageShrimpWeightTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _biomassController,
                                      l10n.shrimpBiomassLabel,
                                      0,
                                      100000,
                                      l10n.shrimpBiomassTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _safetyMarginController,
                                      l10n.safetyMarginLabel,
                                      1,
                                      2,
                                      l10n.safetyMarginTooltip,
                                      l10n,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Step(
                          title: Text(
                            l10n.financialAspects,
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white.withValues(alpha: 0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Form(
                                key: _financialFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      _shrimpPriceController,
                                      l10n.shrimpPriceLabel,
                                      0.1,
                                      50,
                                      l10n.shrimpPriceTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _energyCostController,
                                      l10n.electricityCostLabel,
                                      0,
                                      1,
                                      l10n.electricityCostTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _operatingHoursController,
                                      l10n.operatingHoursLabel,
                                      1,
                                      24,
                                      l10n.operatingHoursTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _discountRateController,
                                      l10n.discountRateLabel,
                                      0,
                                      100,
                                      l10n.discountRateTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _inflationRateController,
                                      l10n.inflationRateLabel,
                                      0,
                                      100,
                                      l10n.inflationRateTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _analysisHorizonController,
                                      l10n.analysisHorizonLabel,
                                      1,
                                      50,
                                      l10n.analysisHorizonTooltip,
                                      l10n,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _dataCollectionConsent,
                                            onChanged: (value) {
                                              setState(() {
                                                _dataCollectionConsent = value ?? false;
                                              });
                                            },
                                            activeColor: const Color(0xFF1E40AF),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _dataCollectionConsent =
                                                      !_dataCollectionConsent;
                                                });
                                              },
                                              child: Text(l10n.dataCollectionConsentLabel),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final url = Uri.parse(
                                                  'https://luisvinatea.github.io/AeraSync/privacy.html');
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode.externalApplication,
                                                );
                                              }
                                            },
                                            child: Text(l10n.learnMore),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    double min,
    double max,
    String tooltip,
    AppLocalizations l10n, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (required && (value == null || value.isEmpty)) {
                  return l10n.requiredField;
                }
                if (!required && (value == null || value.isEmpty)) return null;
                final numValue = double.tryParse(value!.replaceAll(',', '.'));
                if (numValue == null) return l10n.invalidNumber;
                if (numValue < min || numValue > max) {
                  return l10n.rangeError(min, max);
                }
                return null;
              },
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
}
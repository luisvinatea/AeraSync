import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import './results_page.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  int _currentStep = 0;
  bool _dataCollectionConsent = false;

  final List<Map<String, dynamic>> _aerators = [];
  final _aeratorFormKeys = <GlobalKey<FormState>>[];

  final _farmFormKey = GlobalKey<FormState>();
  final _totalAreaController = TextEditingController(text: '1000');
  final _productionPerHaController = TextEditingController(text: '10000');
  final _cyclesPerYearController = TextEditingController(text: '3');
  final _temperatureController = TextEditingController(text: '31.5');
  final _salinityController = TextEditingController(text: '20');
  final _pondDepthController = TextEditingController(text: '1.0');
  final _shrimpWeightController = TextEditingController(text: '10');
  final _biomassController = TextEditingController(text: '3333.33');
  final _safetyMarginController = TextEditingController();

  final _financialFormKey = GlobalKey<FormState>();
  final _shrimpPriceController = TextEditingController(text: '5.0');
  final _energyCostController = TextEditingController(text: '0.05');
  final _operatingHoursController = TextEditingController(text: '2920');
  final _discountRateController = TextEditingController(text: '10');
  final _inflationRateController = TextEditingController(text: '2.5');
  final _analysisHorizonController = TextEditingController(text: '9');

  @override
  void initState() {
    super.initState();
    _addAerator();
    _addAerator(); // Start with two aerators
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
      aerator['nameController'].dispose();
      aerator['typeController'].dispose();
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
      aerator['costController'].dispose();
      aerator['durabilityController'].dispose();
      aerator['maintenanceController'].dispose();
    }
    super.dispose();
  }

  void _addAerator() {
    setState(() {
      _aerators.add({
        'formKey': GlobalKey<FormState>(),
        'nameController': TextEditingController(text: 'Aerator ${_aerators.length + 1}'),
        'typeController': TextEditingController(),
        'powerController': TextEditingController(text: '3.0'),
        'sotrController': TextEditingController(text: '1.4'),
        'costController': TextEditingController(text: '500'),
        'durabilityController': TextEditingController(text: '2'),
        'maintenanceController': TextEditingController(text: '65'),
      });
      _aeratorFormKeys.add(_aerators.last['formKey']);
    });
  }

  void _removeAerator(int index) {
    if (_aerators.length <= 2) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.minimumAeratorsError)),
      );
      return;
    }
    setState(() {
      final aerator = _aerators[index];
      aerator['nameController'].dispose();
      aerator['typeController'].dispose();
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final surveyData = {
        'farm': {
          'area_ha': double.parse(_totalAreaController.text),
          'production_kg_ha_year': double.parse(_productionPerHaController.text),
          'cycles_per_year': double.parse(_cyclesPerYearController.text),
          'pond_depth_m': double.parse(_pondDepthController.text),
        },
        'oxygen': {
          'temperature_c': double.parse(_temperatureController.text),
          'salinity_ppt': double.parse(_salinityController.text),
          'shrimp_weight_g': double.parse(_shrimpWeightController.text),
          'biomass_kg_ha': double.parse(_biomassController.text),
        },
        'aerators': _aerators.map((aerator) {
          return {
            'name': aerator['nameController'].text.isEmpty
                ? 'Aerator ${_aerators.indexOf(aerator) + 1}'
                : aerator['nameController'].text,
            'type': aerator['typeController'].text.isEmpty
                ? null
                : aerator['typeController'].text,
            'power_hp': double.parse(aerator['powerController'].text),
            'sotr_kg_o2_h': double.parse(aerator['sotrController'].text),
            'initial_cost_usd': double.parse(aerator['costController'].text),
            'durability_years': double.parse(aerator['durabilityController'].text),
            'maintenance_usd_year': double.parse(aerator['maintenanceController'].text),
          };
        }).toList(),
        'financial': {
          'shrimp_price_usd_kg': double.parse(_shrimpPriceController.text),
          'energy_cost_usd_kwh': double.parse(_energyCostController.text),
          'operating_hours_year': double.parse(_operatingHoursController.text),
          'discount_rate_percent': double.parse(_discountRateController.text),
          'inflation_rate_percent': double.parse(_inflationRateController.text),
          'analysis_horizon_years': double.parse(_analysisHorizonController.text),
          'safety_margin_percent': _safetyMarginController.text.isEmpty
              ? null
              : double.parse(_safetyMarginController.text),
        },
      };

      await Provider.of<AppState>(context, listen: false).compareAerators(surveyData);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.submissionFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: Padding(
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${l10n.aeratorLabel} ${index + 1}',
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
                                  aerator['nameController'],
                                  l10n.nameLabel,
                                  0,
                                  double.infinity,
                                  l10n.nameTooltip,
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
                                _buildTextField(
                                  aerator['sotrController'],
                                  l10n.sotrLabel,
                                  0.1,
                                  10,
                                  l10n.sotrTooltip,
                                  l10n,
                                ),
                                _buildTextField(
                                  aerator['costController'],
                                  l10n.priceLabel,
                                  0,
                                  10000,
                                  l10n.priceAeratorTooltip,
                                  l10n,
                                ),
                                _buildTextField(
                                  aerator['durabilityController'],
                                  l10n.durabilityLabel,
                                  0.1,
                                  20,
                                  l10n.durabilityAeratorTooltip,
                                  l10n,
                                ),
                                _buildTextField(
                                  aerator['maintenanceController'],
                                  l10n.maintenanceCostLabel,
                                  0,
                                  1000,
                                  l10n.maintenanceCostAeratorTooltip,
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
                            0,
                            100,
                            l10n.safetyMarginTooltip,
                            l10n,
                            required: false,
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
                            0,
                            8760,
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
                                        _dataCollectionConsent = !_dataCollectionConsent;
                                      });
                                    },
                                    child: Text(l10n.dataCollectionConsentLabel),
                                  ),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                  return l10n.rangeError(min.toString(), max.toString());
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
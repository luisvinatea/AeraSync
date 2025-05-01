import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:developer' as developer;
import '../../../core/services/app_state.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @visibleForTesting
  static Future<void> submitForTesting(BuildContext context) async {
    final state = context.findAncestorStateOfType<_SurveyPageState>();
    if (state != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context)!;

      state._isLoading = true;

      final surveyData = {
        'farm': {
          'tod': double.tryParse(state._todController.text) ?? 0.0,
          'farm_area_ha': double.tryParse(state._farmAreaController.text) ?? 0.0,
          'shrimp_price': double.tryParse(state._shrimpPriceController.text) ?? 5.0,
          'culture_days': double.tryParse(state._cultureDaysController.text) ?? 120,
          'pond_density': double.tryParse(state._pondDensityController.text) ?? 10.0,
        },
        'financial': {
          'energy_cost': double.tryParse(state._electricityCostController.text) ?? 0.05,
          'operating_hours': double.tryParse(state._operatingHoursController.text) ?? 2920,
          'discount_rate': (double.tryParse(state._discountRateController.text) ?? 10.0) / 100,
          'inflation_rate': (double.tryParse(state._inflationRateController.text) ?? 3.0) / 100,
          'horizon': int.tryParse(state._analysisYearsController.text) ?? 9,
          'safety_margin': (double.tryParse(state._safetyMarginController.text) ?? 0.0) / 100,
          'temperature': double.tryParse(state._temperatureController.text) ?? 31.5,
        },
        'aerators': [
          {
            'name': state._aerator1NameController.text,
            'power_hp': double.tryParse(state._aerator1PowerController.text) ?? 3.0,
            'sotr': double.tryParse(state._aerator1SotrController.text) ?? 1.4,
            'cost': double.tryParse(state._aerator1CostController.text) ?? 500.0,
            'durability': double.tryParse(state._aerator1DurabilityController.text) ?? 2.0,
            'maintenance': double.tryParse(state._aerator1MaintenanceController.text) ?? 65.0
          },
          {
            'name': state._aerator2NameController.text,
            'power_hp': double.tryParse(state._aerator2PowerController.text) ?? 3.0,
            'sotr': double.tryParse(state._aerator2SotrController.text) ?? 2.6,
            'cost': double.tryParse(state._aerator2CostController.text) ?? 800.0,
            'durability': double.tryParse(state._aerator2DurabilityController.text) ?? 4.5,
            'maintenance': double.tryParse(state._aerator2MaintenanceController.text) ?? 50.0
          }
        ]
      };

      try {
        developer.log('Calling compareAerators with data: $surveyData');
        await appState.compareAerators(surveyData);
        developer.log('CompareAerators completed successfully');

        if (!context.mounted) return;
        developer.log('Navigating to results page');
        navigator.pushNamed('/results');
      } catch (e) {
        if (!context.mounted) return;
        developer.log('Error during submission: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.submissionFailed(e.toString()))),
        );
      } finally {
        if (context.mounted) {
          developer.log('Setting isLoading to false');
          state._isLoading = false;
        }
      }
    }
  }

  @override
  // ignore: library_private_types_in_public_api
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _stepperKey = GlobalKey();

  // Farm inputs
  final _todController = TextEditingController(text: "5443.7675");
  final _farmAreaController = TextEditingController(text: "1000");
  final _shrimpPriceController = TextEditingController(text: "5.0");
  final _cultureDaysController = TextEditingController(text: "120");
  final _pondDensityController = TextEditingController(text: "10.0");

  // Financial inputs
  final _electricityCostController = TextEditingController(text: "0.05");
  final _operatingHoursController = TextEditingController(text: "2920");
  final _discountRateController = TextEditingController(text: "10.0");
  final _inflationRateController = TextEditingController(text: "3.0");
  final _analysisYearsController = TextEditingController(text: "9");
  final _safetyMarginController = TextEditingController(text: "0");
  final _temperatureController = TextEditingController(text: "31.5");

  // Aerator inputs - first aerator
  final _aerator1NameController = TextEditingController(text: "Paddlewheel 1");
  final _aerator1PowerController = TextEditingController(text: "3.0");
  final _aerator1SotrController = TextEditingController(text: "1.4");
  final _aerator1CostController = TextEditingController(text: "500");
  final _aerator1DurabilityController = TextEditingController(text: "2");
  final _aerator1MaintenanceController = TextEditingController(text: "65");

  // Aerator inputs - second aerator
  final _aerator2NameController = TextEditingController(text: "Paddlewheel 2");
  final _aerator2PowerController = TextEditingController(text: "3.0");
  final _aerator2SotrController = TextEditingController(text: "2.6");
  final _aerator2CostController = TextEditingController(text: "800");
  final _aerator2DurabilityController = TextEditingController(text: "4.5");
  final _aerator2MaintenanceController = TextEditingController(text: "50");

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _todController.dispose();
    _farmAreaController.dispose();
    _shrimpPriceController.dispose();
    _cultureDaysController.dispose();
    _pondDensityController.dispose();
    _electricityCostController.dispose();
    _operatingHoursController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _analysisYearsController.dispose();
    _safetyMarginController.dispose();
    _temperatureController.dispose();
    _aerator1NameController.dispose();
    _aerator1PowerController.dispose();
    _aerator1SotrController.dispose();
    _aerator1CostController.dispose();
    _aerator1DurabilityController.dispose();
    _aerator1MaintenanceController.dispose();
    _aerator2NameController.dispose();
    _aerator2PowerController.dispose();
    _aerator2SotrController.dispose();
    _aerator2CostController.dispose();
    _aerator2DurabilityController.dispose();
    _aerator2MaintenanceController.dispose();
    super.dispose();
  }

  Future<void> _submitSurvey(BuildContext context) async {
    developer.log('Submitting survey...');
    if (_formKey.currentState!.validate()) {
      developer.log('Form validated, setting isLoading to true');
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Format data according to API expectations
      final surveyData = {
        'farm': {
          'tod': double.tryParse(_todController.text),
          'farm_area_ha': double.tryParse(_farmAreaController.text),
          'shrimp_price': double.tryParse(_shrimpPriceController.text),
          'culture_days': double.tryParse(_cultureDaysController.text),
          'pond_density': double.tryParse(_pondDensityController.text),
        },
        'financial': {
          'energy_cost': double.tryParse(_electricityCostController.text),
          'operating_hours': double.tryParse(_operatingHoursController.text),
          'discount_rate': (double.tryParse(_discountRateController.text) ?? 10.0) / 100,
          'inflation_rate': (double.tryParse(_inflationRateController.text) ?? 2.5) / 100,
          'horizon': int.tryParse(_analysisYearsController.text),
          'safety_margin': double.tryParse(_safetyMarginController.text),
          'temperature': double.tryParse(_temperatureController.text),
        },
        'aerators': [
          {
            'name': _aerator1NameController.text,
            'power_hp': double.tryParse(_aerator1PowerController.text),
            'sotr': double.tryParse(_aerator1SotrController.text),
            'cost': double.tryParse(_aerator1CostController.text),
            'durability': double.tryParse(_aerator1DurabilityController.text),
            'maintenance': double.tryParse(_aerator1MaintenanceController.text)
          },
          {
            'name': _aerator2NameController.text,
            'power_hp': double.tryParse(_aerator2PowerController.text),
            'sotr': double.tryParse(_aerator2SotrController.text),
            'cost': double.tryParse(_aerator2CostController.text),
            'durability': double.tryParse(_aerator2DurabilityController.text),
            'maintenance': double.tryParse(_aerator2MaintenanceController.text)
          }
        ]
      };

      try {
        developer.log('Calling compareAerators with data: $surveyData');
        await appState.compareAerators(surveyData);
        developer.log('CompareAerators completed successfully');
        
        if (!context.mounted) return;
        
        // Show success message and use callback to navigate after animation completes
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.surveySubmissionSuccessful),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
          ),
        );
        
        // Use a slight delay for better UX
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (!context.mounted) return;
        navigator.pushNamed('/results');
      } catch (e) {
        if (!context.mounted) return;
        developer.log('Error during submission: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.submissionFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (context.mounted) {
          developer.log('Setting isLoading to false');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      developer.log('Form validation failed');
    }
  }

  void _nextStep() {
    developer.log('Next step called, current step: $_currentStep');
    if (_currentStep < 1) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep += 1;
        });
        developer.log('Moved to step: $_currentStep');
      } else {
        developer.log('Validation failed, staying on step: $_currentStep');
      }
    }
  }

  void _prevStep() {
    developer.log('Previous step called, current step: $_currentStep');
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
      developer.log('Moved to step: $_currentStep');
    }
  }

  TextFormField _buildNumberField(
      TextEditingController controller, String label, String suffix, bool required,
      {double? min, double? max, String? hint}) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? '' : ' (${l10n.optionalField})'),
        suffixText: suffix,
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withAlpha(242),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withAlpha(204),
          color: const Color.fromARGB(255, 5, 1, 55),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return l10n.requiredField;
              }
              final numValue = double.tryParse(value);
              if (numValue == null) {
                return l10n.invalidNumber;
              }
              if (min != null && numValue < min) {
                return l10n.minimumValueError('$min');
              }
              if (max != null && numValue > max) {
                return l10n.rangeError('$min', '$max');
              }
              return null;
            }
          : null,
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withAlpha(242),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withAlpha(204),
          color: const Color.fromARGB(255, 5, 1, 55),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.requiredField;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    developer.log('Building SurveyPage, current step: $_currentStep');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.survey),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Stepper(
                    key: _stepperKey,
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepTapped: (step) {
                      if (_formKey.currentState!.validate() || step < _currentStep) {
                        setState(() {
                          _currentStep = step;
                        });
                        developer.log('Step tapped, moved to step: $_currentStep');
                      }
                    },
                    controlsBuilder: (context, controls) {
                      developer.log('Rendering controls for step: $_currentStep');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              ElevatedButton(
                                key: const Key('back_button'),
                                onPressed: _prevStep,
                                child: Text(l10n.back),
                              ),
                            const SizedBox(width: 16),
                            if (_currentStep < 1)
                              ElevatedButton(
                                key: const Key('next_button'),
                                onPressed: _nextStep,
                                child: Text(l10n.next),
                              ),
                            if (_currentStep == 1)
                              ElevatedButton(
                                key: const Key('submit_button'),
                                onPressed: () => _submitSurvey(context),
                                child: Text(l10n.submit),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: Text(l10n.farmFinancialDetails),
                        isActive: _currentStep == 0,
                        content: Column(
                          children: [
                            _buildNumberField(
                              _todController,
                              l10n.totalOxygenDemand,
                              'kg O₂/h',
                              true,
                              min: 0.1,
                              hint: '5443.7675',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _farmAreaController,
                              l10n.farmAreaLabel,
                              'ha',
                              true,
                              min: 0.1,
                              max: 10000.0,
                              hint: '1000',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _shrimpPriceController,
                              l10n.shrimpPriceLabel,
                              'USD/kg',
                              true,
                              min: 0.1,
                              max: 100.0,
                              hint: '5.0',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _cultureDaysController,
                              l10n.cultureDaysLabel,
                              'days',
                              true,
                              min: 30,
                              max: 365,
                              hint: '120',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _pondDensityController,
                              l10n.pondDensityLabel,
                              'ton/ha',
                              true,
                              min: 0.1,
                              max: 100.0,
                              hint: '10.0',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _electricityCostController,
                              l10n.electricityCostLabel,
                              'USD/kWh',
                              true,
                              min: 0.0,
                              max: 2.0,
                              hint: '0.05',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _operatingHoursController,
                              l10n.operatingHoursLabel,
                              'hours/year',
                              true,
                              min: 1,
                              max: 8760,
                              hint: '2920',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _discountRateController,
                              l10n.discountRateLabel,
                              '%',
                              true,
                              min: 0.0,
                              max: 100.0,
                              hint: '10.0',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _inflationRateController,
                              l10n.inflationRateLabel,
                              '%',
                              true,
                              min: 0.0,
                              max: 100.0,
                              hint: '3.0',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _analysisYearsController,
                              l10n.analysisHorizonLabel,
                              'years',
                              true,
                              min: 1,
                              max: 50,
                              hint: '9',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _safetyMarginController,
                              l10n.safetyMarginLabel,
                              '%',
                              false,
                              min: 0.0,
                              max: 100.0,
                              hint: '0',
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _temperatureController,
                              l10n.temperatureLabel,
                              '°C',
                              true,
                              min: 0.0,
                              max: 50.0,
                              hint: '31.5',
                            ),
                          ],
                        ),
                      ),
                      Step(
                        title: Text(l10n.aeratorDetails),
                        isActive: _currentStep == 1,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${l10n.aeratorLabel} 1",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(_aerator1NameController, l10n.nameLabel),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator1PowerController,
                              l10n.horsepowerLabel,
                              'hp',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '3.0',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator1SotrController,
                              l10n.sotrLabel,
                              'kg O₂/h',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '1.4',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator1CostController,
                              l10n.priceLabel,
                              'USD',
                              true,
                              min: 0,
                              max: 50000,
                              hint: '500',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator1DurabilityController,
                              l10n.durabilityLabel,
                              'years',
                              true,
                              min: 0.1,
                              max: 50,
                              hint: '2',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator1MaintenanceController,
                              l10n.maintenanceCostLabel,
                              'USD/year',
                              true,
                              min: 0,
                              max: 10000,
                              hint: '65',
                            ),
                            const Divider(height: 32),
                            Text(
                              "${l10n.aeratorLabel} 2",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(_aerator2NameController, l10n.nameLabel),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2PowerController,
                              l10n.horsepowerLabel,
                              'hp',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '3.0',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2SotrController,
                              l10n.sotrLabel,
                              'kg O₂/h',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '2.6',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2CostController,
                              l10n.priceLabel,
                              'USD',
                              true,
                              min: 0,
                              max: 50000,
                              hint: '800',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2DurabilityController,
                              l10n.durabilityLabel,
                              'years',
                              true,
                              min: 0.1,
                              max: 50,
                              hint: '4.5',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2MaintenanceController,
                              l10n.maintenanceCostLabel,
                              'USD/year',
                              true,
                              min: 0,
                              max: 10000,
                              hint: '50',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
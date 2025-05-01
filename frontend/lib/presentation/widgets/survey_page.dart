import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/app_state.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();

  // Farm inputs
  final _todController = TextEditingController(text: "5443.7675");
  final _farmAreaController = TextEditingController(text: "1000");

  // Financial inputs
  final _electricityCostController = TextEditingController(text: "0.05");
  final _operatingHoursController = TextEditingController(text: "2920");
  final _discountRateController = TextEditingController(text: "10.0");
  final _inflationRateController = TextEditingController(text: "2.5");
  final _analysisYearsController = TextEditingController(text: "9");
  final _safetyMarginController = TextEditingController(text: "0");

  // Aerator inputs - first aerator
  final _aerator1NameController = TextEditingController(text: "Paddlewheel");
  final _aerator1PowerController = TextEditingController(text: "3.0");
  final _aerator1SotrController = TextEditingController(text: "1.4");
  final _aerator1CostController = TextEditingController(text: "500");
  final _aerator1DurabilityController = TextEditingController(text: "2");
  final _aerator1MaintenanceController = TextEditingController(text: "65");

  // Aerator inputs - second aerator
  final _aerator2NameController = TextEditingController(text: "Propeller");
  final _aerator2PowerController = TextEditingController(text: "3.5");
  final _aerator2SotrController = TextEditingController(text: "2.2");
  final _aerator2CostController = TextEditingController(text: "800");
  final _aerator2DurabilityController = TextEditingController(text: "4.5");
  final _aerator2MaintenanceController = TextEditingController(text: "50");

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    // Dispose all controllers
    _todController.dispose();
    _farmAreaController.dispose();
    _electricityCostController.dispose();
    _operatingHoursController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _analysisYearsController.dispose();
    _safetyMarginController.dispose();
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Format data according to the backend API structure
      final surveyData = {
        'tod': double.tryParse(_todController.text) ?? 0.0,
        'farm_area_ha': double.tryParse(_farmAreaController.text) ?? 0.0,
        'financial': {
          'energy_cost':
              double.tryParse(_electricityCostController.text) ?? 0.05,
          'operating_hours':
              double.tryParse(_operatingHoursController.text) ?? 2920,
          'discount_rate':
              (double.tryParse(_discountRateController.text) ?? 10.0) / 100,
          'inflation_rate':
              (double.tryParse(_inflationRateController.text) ?? 2.5) / 100,
          'horizon': int.tryParse(_analysisYearsController.text) ?? 9,
          'safety_margin':
              (double.tryParse(_safetyMarginController.text) ?? 0.0) / 100
        },
        'aerators': [
          {
            'name': _aerator1NameController.text,
            'power_hp': double.tryParse(_aerator1PowerController.text) ?? 3.0,
            'sotr': double.tryParse(_aerator1SotrController.text) ?? 1.4,
            'cost': double.tryParse(_aerator1CostController.text) ?? 500.0,
            'durability':
                double.tryParse(_aerator1DurabilityController.text) ?? 2.0,
            'maintenance':
                double.tryParse(_aerator1MaintenanceController.text) ?? 65.0
          },
          {
            'name': _aerator2NameController.text,
            'power_hp': double.tryParse(_aerator2PowerController.text) ?? 3.5,
            'sotr': double.tryParse(_aerator2SotrController.text) ?? 2.2,
            'cost': double.tryParse(_aerator2CostController.text) ?? 800.0,
            'durability':
                double.tryParse(_aerator2DurabilityController.text) ?? 4.5,
            'maintenance':
                double.tryParse(_aerator2MaintenanceController.text) ?? 50.0
          }
        ]
      };

      try {
        await appState.compareAerators(surveyData);
        if (!mounted) return;
        
        // Use Navigator after checking mounted state
        Navigator.pushNamed(context, '/results');
      } catch (e) {
        if (!mounted) return;
        
        // Use ScaffoldMessenger after checking mounted state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.submissionFailed(e.toString()))),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  TextFormField _buildNumberField(TextEditingController controller,
      String label, String suffix, bool required,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withAlpha(204),
          color: const Color(0xFF1E40AF),
          fontWeight: FontWeight.w500,
          fontSize: 14,
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

  TextFormField _buildTextField(
      TextEditingController controller, String label) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withAlpha(242),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withAlpha(204),
          color: const Color(0xFF1E40AF),
          fontWeight: FontWeight.w500,
          fontSize: 14,
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
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepTapped: (step) {
                      setState(() {
                        _currentStep = step;
                      });
                    },
                    controlsBuilder: (context, controls) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              ElevatedButton(
                                onPressed: _prevStep,
                                child: Text(l10n.back),
                              ),
                            const SizedBox(width: 16),
                            if (_currentStep < 1)
                              ElevatedButton(
                                onPressed: _nextStep,
                                child: Text(l10n.next),
                              ),
                            if (_currentStep == 1)
                              ElevatedButton(
                                onPressed: () => _submitSurvey(context),
                                child: Text(l10n.submit),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // Step 1: Farm and Financial Details
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
                              hint: '2.5',
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
                          ],
                        ),
                      ),

                      // Step 2: Aerator Details
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
                            _buildTextField(
                                _aerator1NameController, l10n.nameLabel),
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
                            _buildTextField(
                                _aerator2NameController, l10n.nameLabel),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2PowerController,
                              l10n.horsepowerLabel,
                              'hp',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '3.5',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              _aerator2SotrController,
                              l10n.sotrLabel,
                              'kg O₂/h',
                              true,
                              min: 0.1,
                              max: 100,
                              hint: '2.2',
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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import 'package:logging/logging.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  static final Logger _logger = Logger('SurveyPage');
  final _formKey = GlobalKey<FormState>();

  // Farm inputs
  final _pondAreaController = TextEditingController();
  final _pondDepthController = TextEditingController();

  // Shrimp and oxygen inputs
  final _shrimpDensityController = TextEditingController();
  final _shrimpWeightController = TextEditingController();
  final _waterTempController = TextEditingController(text: '30.0');
  final _salinityController = TextEditingController(text: '15.0');

  // Financial inputs
  final _cultureDaysController = TextEditingController();
  final _electricityCostController = TextEditingController();
  final _shrimpPriceController = TextEditingController(text: '5.0');
  final _discountRateController = TextEditingController(text: '10.0');
  final _inflationRateController = TextEditingController(text: '2.0');
  final _analysisYearsController = TextEditingController(text: '5');
  final _safetyMarginController = TextEditingController(text: '20.0');

  // Aerator inputs - first aerator (optional)
  final _aerator1NameController = TextEditingController(text: "Paddlewheel");
  final _aerator1PowerController = TextEditingController(text: "2.0");
  final _aerator1SotrController = TextEditingController(text: "1.2");
  final _aerator1CostController = TextEditingController(text: "500");
  final _aerator1DurabilityController = TextEditingController(text: "3");
  final _aerator1MaintenanceController = TextEditingController(text: "50");

  // Aerator inputs - second aerator (required for comparison)
  final _aerator2NameController =
      TextEditingController(text: "Comparison Aerator");
  final _aerator2PowerController = TextEditingController(text: "2.2");
  final _aerator2SotrController = TextEditingController(text: "1.3");
  final _aerator2CostController = TextEditingController(text: "600");
  final _aerator2DurabilityController = TextEditingController(text: "3");
  final _aerator2MaintenanceController = TextEditingController(text: "60");

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    // Dispose all controllers
    _pondAreaController.dispose();
    _pondDepthController.dispose();
    _shrimpDensityController.dispose();
    _shrimpWeightController.dispose();
    _waterTempController.dispose();
    _salinityController.dispose();
    _cultureDaysController.dispose();
    _electricityCostController.dispose();
    _shrimpPriceController.dispose();
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

      // Calculate biomass_kg_ha from density and weight
      final double shrimpDensity =
          double.tryParse(_shrimpDensityController.text) ?? 0.0;
      final double shrimpWeight =
          double.tryParse(_shrimpWeightController.text) ?? 0.0;
      final double biomassKgHa = (shrimpDensity * shrimpWeight) / 1000.0;

      // Calculate operating hours from culture days
      final int cultureDays = int.tryParse(_cultureDaysController.text) ?? 120;
      final int operatingHours = cultureDays * 24; // 24 hours per day

      // Format data according to the expected backend API structure
      final surveyData = {
        'farm': {
          'area_ha': double.tryParse(_pondAreaController.text) ?? 0.0,
          'pond_depth_m': double.tryParse(_pondDepthController.text) ?? 0.0,
        },
        'oxygen': {
          'temperature_c': double.tryParse(_waterTempController.text) ?? 30.0,
          'salinity_ppt': double.tryParse(_salinityController.text) ?? 15.0,
          'shrimp_weight_g':
              double.tryParse(_shrimpWeightController.text) ?? 0.0,
          'biomass_kg_ha': biomassKgHa,
        },
        'aerators': [
          {
            'name': _aerator1NameController.text,
            'power_hp': double.tryParse(_aerator1PowerController.text) ?? 2.0,
            'sotr_kg_o2_h':
                double.tryParse(_aerator1SotrController.text) ?? 1.2,
            'initial_cost_usd':
                double.tryParse(_aerator1CostController.text) ?? 500.0,
            'durability_years':
                int.tryParse(_aerator1DurabilityController.text) ?? 3,
            'maintenance_usd_year':
                double.tryParse(_aerator1MaintenanceController.text) ?? 50.0
          },
          {
            'name': _aerator2NameController.text,
            'power_hp': double.tryParse(_aerator2PowerController.text) ?? 2.2,
            'sotr_kg_o2_h':
                double.tryParse(_aerator2SotrController.text) ?? 1.3,
            'initial_cost_usd':
                double.tryParse(_aerator2CostController.text) ?? 600.0,
            'durability_years':
                int.tryParse(_aerator2DurabilityController.text) ?? 3,
            'maintenance_usd_year':
                double.tryParse(_aerator2MaintenanceController.text) ?? 60.0
          }
        ],
        'financial': {
          'shrimp_price_usd_kg':
              double.tryParse(_shrimpPriceController.text) ?? 5.0,
          'energy_cost_usd_kwh':
              double.tryParse(_electricityCostController.text) ?? 0.05,
          'operating_hours_year': operatingHours,
          'discount_rate_percent':
              double.tryParse(_discountRateController.text) ?? 10.0,
          'inflation_rate_percent':
              double.tryParse(_inflationRateController.text) ?? 2.0,
          'analysis_horizon_years':
              int.tryParse(_analysisYearsController.text) ?? 5,
          'safety_margin_percent':
              double.tryParse(_safetyMarginController.text) ?? 20.0
        },
      };

      _logger.info('Submitting survey data: $surveyData');

      try {
        await appState.compareAerators(surveyData);
        if (mounted) {
          Navigator.pushNamed(context, '/results');
        }
      } catch (e) {
        _logger.severe('Error submitting survey: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.surveySubmissionFailed(e.toString()))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _logger.warning('Form validation failed');
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
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
        labelText: label + (required ? '' : ' (${l10n.optional})'),
        suffixText: suffix,
        hintText: hint,
        // Enhanced styling for better readability
        filled: true,
        fillColor: Colors.white.withOpacity(0.95),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withOpacity(0.8),
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
                return '${l10n.positiveNumberRequired} (>= $min)';
              }
              if (max != null && numValue > max) {
                return l10n.rangeError('$min', '$max');
              }
              return null;
            }
          : null,
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
                            if (_currentStep < 3)
                              ElevatedButton(
                                onPressed: _nextStep,
                                child: Text(l10n.next),
                              ),
                            if (_currentStep == 3)
                              ElevatedButton(
                                onPressed: () => _submitSurvey(context),
                                child: Text(l10n.submit),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // Step 1: Pond Details
                      Step(
                        title: Text(l10n.pondDetails),
                        isActive: _currentStep == 0,
                        content: Column(
                          children: [
                            _buildNumberField(_pondAreaController,
                                l10n.pondAreaLabel, 'ha', true,
                                min: 0.1, max: 10000.0, hint: '1.0'),
                            const SizedBox(height: 16),
                            _buildNumberField(_pondDepthController,
                                l10n.pondDepthLabel, 'm', true,
                                min: 0.5, max: 5.0, hint: '1.5'),
                            const SizedBox(height: 16),
                            _buildNumberField(_waterTempController,
                                l10n.waterTemperatureLabel, '°C', true,
                                min: 15.0, max: 40.0),
                            const SizedBox(height: 16),
                            _buildNumberField(_salinityController,
                                l10n.salinityLabel, 'ppt', true,
                                min: 0.0, max: 40.0),
                          ],
                        ),
                      ),

                      // Step 2: Shrimp Details
                      Step(
                        title: Text(l10n.shrimpDetails),
                        isActive: _currentStep == 1,
                        content: Column(
                          children: [
                            _buildNumberField(_shrimpDensityController,
                                l10n.shrimpDensityLabel, 'shrimp/m²', true,
                                min: 1.0, max: 1000.0, hint: '30'),
                            const SizedBox(height: 16),
                            _buildNumberField(_shrimpWeightController,
                                l10n.shrimpWeightLabel, 'g', true,
                                min: 0.1, max: 50.0, hint: '15'),
                            const SizedBox(height: 16),
                            _buildNumberField(_cultureDaysController,
                                l10n.cultureDaysLabel, l10n.days, true,
                                min: 1, max: 365, hint: '120'),
                            const SizedBox(height: 16),
                            _buildNumberField(_shrimpPriceController,
                                l10n.shrimpPriceLabel, 'USD/kg', true,
                                min: 0.1, max: 50.0),
                          ],
                        ),
                      ),

                      // Step 3: Financial Details
                      Step(
                        title: Text(l10n.financialAspects),
                        isActive: _currentStep == 2,
                        content: Column(
                          children: [
                            _buildNumberField(_electricityCostController,
                                l10n.electricityCostLabel, 'USD/kWh', true,
                                min: 0.0, max: 2.0, hint: '0.05'),
                            const SizedBox(height: 16),
                            _buildNumberField(_discountRateController,
                                l10n.discountRateLabel, '%', true,
                                min: 0.0, max: 100.0),
                            const SizedBox(height: 16),
                            _buildNumberField(_inflationRateController,
                                l10n.inflationRateLabel, '%', true,
                                min: 0.0, max: 100.0),
                            const SizedBox(height: 16),
                            _buildNumberField(_analysisYearsController,
                                l10n.analysisHorizonLabel, l10n.days, true,
                                min: 1, max: 50),
                            const SizedBox(height: 16),
                            _buildNumberField(_safetyMarginController,
                                l10n.safetyMarginLabel, '%', false,
                                min: 0.0, max: 100.0),
                          ],
                        ),
                      ),

                      // Step 4: Aerator Details
                      Step(
                        title: Text(l10n.aeratorDetails),
                        isActive: _currentStep == 3,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${l10n.aeratorLabel} 1",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _aerator1NameController,
                              decoration: InputDecoration(
                                labelText: l10n.nameLabel,
                                // Enhanced styling for better readability
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.95),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                labelStyle: TextStyle(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.8),
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E40AF), width: 2),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.requiredField;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator1PowerController,
                                l10n.horsepowerLabel, 'hp', true,
                                min: 0.1, max: 100),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator1SotrController,
                                l10n.sotrLabel, 'kg O₂/h', true,
                                min: 0.1, max: 100),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator1CostController,
                                l10n.priceLabel, 'USD', true,
                                min: 0, max: 50000),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator1DurabilityController,
                                l10n.durabilityLabel, l10n.days, true,
                                min: 0.1, max: 50),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator1MaintenanceController,
                                l10n.maintenanceCostLabel, 'USD/year', true,
                                min: 0, max: 10000),
                            const Divider(height: 32),
                            Text(
                              "${l10n.aeratorLabel} 2",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _aerator2NameController,
                              decoration: InputDecoration(
                                labelText: l10n.nameLabel,
                                // Enhanced styling for better readability
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.95),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                labelStyle: TextStyle(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.8),
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E40AF), width: 2),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.requiredField;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator2PowerController,
                                l10n.horsepowerLabel, 'hp', true,
                                min: 0.1, max: 100),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator2SotrController,
                                l10n.sotrLabel, 'kg O₂/h', true,
                                min: 0.1, max: 100),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator2CostController,
                                l10n.priceLabel, 'USD', true,
                                min: 0, max: 50000),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator2DurabilityController,
                                l10n.durabilityLabel, l10n.days, true,
                                min: 0.1, max: 50),
                            const SizedBox(height: 8),
                            _buildNumberField(_aerator2MaintenanceController,
                                l10n.maintenanceCostLabel, 'USD/year', true,
                                min: 0, max: 10000),
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

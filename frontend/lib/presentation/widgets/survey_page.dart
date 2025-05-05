// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:developer' as developer;
import '../../core/services/app_state.dart';
import 'components/survey/farm_details_form_section.dart';
import 'components/survey/aerator_form_section.dart';
import 'utils/survey_data_processor.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @visibleForTesting
  static Future<void> submitForTesting(BuildContext context) async {
    final state = context.findAncestorStateOfType<_SurveyPageState>();
    if (state != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      state._isLoading = true;

      final surveyData = SurveyDataProcessor.prepareSurveyData(
        // Farm inputs
        todController: state._todController,
        farmAreaController: state._farmAreaController,
        shrimpPriceController: state._shrimpPriceController,
        cultureDaysController: state._cultureDaysController,
        shrimpDensityController: state._shrimpDensityController,
        pondDepthController: state._pondDepthController,

        // Financial inputs
        energyCostController: state._energyCostController,
        hoursPerNightController: state._hoursPerNightController,
        discountRateController: state._discountRateController,
        inflationRateController: state._inflationRateController,
        horizonController: state._horizonController,
        safetyMarginController: state._safetyMarginController,
        temperatureController: state._temperatureController,

        // Aerator 1 inputs
        aerator1NameController: state._aerator1NameController,
        aerator1PowerController: state._aerator1PowerController,
        aerator1SotrController: state._aerator1SotrController,
        aerator1CostController: state._aerator1CostController,
        aerator1DurabilityController: state._aerator1DurabilityController,
        aerator1MaintenanceController: state._aerator1MaintenanceController,

        // Aerator 2 inputs
        aerator2NameController: state._aerator2NameController,
        aerator2PowerController: state._aerator2PowerController,
        aerator2SotrController: state._aerator2SotrController,
        aerator2CostController: state._aerator2CostController,
        aerator2DurabilityController: state._aerator2DurabilityController,
        aerator2MaintenanceController: state._aerator2MaintenanceController,
      );

      try {
        developer.log('Calling compareAerators with data: $surveyData');
        await appState.compareAerators(surveyData);
        developer.log('CompareAerators completed successfully');
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

class _SurveyPageState extends State<SurveyPage> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _stepperKey = GlobalKey();
  late TabController _tabController;

  // Farm inputs
  final _todController = TextEditingController(text: "5443.76");
  final _farmAreaController = TextEditingController(text: "1000");
  final _shrimpPriceController = TextEditingController(text: "5.0");
  final _cultureDaysController = TextEditingController(text: "120");
  final _shrimpDensityController = TextEditingController(text: "0.33");
  final _pondDepthController = TextEditingController(text: "1.0");

  // Financial inputs
  final _energyCostController = TextEditingController(text: "0.05");
  final _hoursPerNightController = TextEditingController(text: "8");
  final _discountRateController = TextEditingController(text: "10.0");
  final _inflationRateController = TextEditingController(text: "3.0");
  final _horizonController = TextEditingController(text: "9");
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _todController.dispose();
    _farmAreaController.dispose();
    _shrimpPriceController.dispose();
    _cultureDaysController.dispose();
    _shrimpDensityController.dispose();
    _pondDepthController.dispose();
    _energyCostController.dispose();
    _hoursPerNightController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _horizonController.dispose();
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
    _tabController.dispose();
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
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Format data using the utility
      final surveyData = SurveyDataProcessor.prepareSurveyData(
        // Farm inputs
        todController: _todController,
        farmAreaController: _farmAreaController,
        shrimpPriceController: _shrimpPriceController,
        cultureDaysController: _cultureDaysController,
        shrimpDensityController: _shrimpDensityController,
        pondDepthController: _pondDepthController,

        // Financial inputs
        energyCostController: _energyCostController,
        hoursPerNightController: _hoursPerNightController,
        discountRateController: _discountRateController,
        inflationRateController: _inflationRateController,
        horizonController: _horizonController,
        safetyMarginController: _safetyMarginController,
        temperatureController: _temperatureController,

        // Aerator 1 inputs
        aerator1NameController: _aerator1NameController,
        aerator1PowerController: _aerator1PowerController,
        aerator1SotrController: _aerator1SotrController,
        aerator1CostController: _aerator1CostController,
        aerator1DurabilityController: _aerator1DurabilityController,
        aerator1MaintenanceController: _aerator1MaintenanceController,

        // Aerator 2 inputs
        aerator2NameController: _aerator2NameController,
        aerator2PowerController: _aerator2PowerController,
        aerator2SotrController: _aerator2SotrController,
        aerator2CostController: _aerator2CostController,
        aerator2DurabilityController: _aerator2DurabilityController,
        aerator2MaintenanceController: _aerator2MaintenanceController,
      );

      SurveyDataProcessor.logSurveyData(surveyData);

      try {
        developer.log('Calling compareAerators with data: $surveyData');
        await appState.compareAerators(surveyData);
        developer.log('CompareAerators completed successfully');

        if (!context.mounted) return;

        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.surveySubmissionSuccessful),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    developer.log('Building SurveyPage, current step: $_currentStep');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.survey,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
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
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Stepper(
                    key: _stepperKey,
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepTapped: (step) {
                      if (_formKey.currentState!.validate() ||
                          step < _currentStep) {
                        setState(() {
                          _currentStep = step;
                        });
                        developer
                            .log('Step tapped, moved to step: $_currentStep');
                      }
                    },
                    controlsBuilder: (context, controls) {
                      developer
                          .log('Rendering controls for step: $_currentStep');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ElevatedButton(
                                    key: const Key('back_button'),
                                    onPressed: _prevStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.back,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentStep < 1)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ElevatedButton(
                                    key: const Key('next_button'),
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.next,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentStep == 1)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ElevatedButton(
                                    key: const Key('submit_button'),
                                    onPressed: () => _submitSurvey(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.submit,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: Text(
                          l10n.farmFinancialDetails,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        isActive: _currentStep == 0,
                        content: FarmDetailsFormSection(
                          todController: _todController,
                          farmAreaController: _farmAreaController,
                          shrimpPriceController: _shrimpPriceController,
                          cultureDaysController: _cultureDaysController,
                          shrimpDensityController: _shrimpDensityController,
                          pondDepthController: _pondDepthController,
                          energyCostController: _energyCostController,
                          hoursPerNightController: _hoursPerNightController,
                          discountRateController: _discountRateController,
                          inflationRateController: _inflationRateController,
                          horizonController: _horizonController,
                          safetyMarginController: _safetyMarginController,
                          temperatureController: _temperatureController,
                        ),
                      ),
                      Step(
                        title: Text(
                          l10n.aeratorDetails,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        isActive: _currentStep == 1,
                        content: Column(
                          children: [
                            AeratorFormSection(
                              aeratorNumber: "1",
                              nameController: _aerator1NameController,
                              powerController: _aerator1PowerController,
                              sotrController: _aerator1SotrController,
                              costController: _aerator1CostController,
                              durabilityController:
                                  _aerator1DurabilityController,
                              maintenanceController:
                                  _aerator1MaintenanceController,
                            ),
                            const SizedBox(height: 16),
                            AeratorFormSection(
                              aeratorNumber: "2",
                              nameController: _aerator2NameController,
                              powerController: _aerator2PowerController,
                              sotrController: _aerator2SotrController,
                              costController: _aerator2CostController,
                              durabilityController:
                                  _aerator2DurabilityController,
                              maintenanceController:
                                  _aerator2MaintenanceController,
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

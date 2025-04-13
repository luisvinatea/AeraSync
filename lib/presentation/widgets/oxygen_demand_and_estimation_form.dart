import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math';
import '../../core/services/app_state.dart';

class OxygenDemandAndEstimationForm extends StatefulWidget {
  const OxygenDemandAndEstimationForm({super.key});

  @override
  State<OxygenDemandAndEstimationForm> createState() => _OxygenDemandAndEstimationFormState();
}

class _OxygenDemandAndEstimationFormState extends State<OxygenDemandAndEstimationForm> with SingleTickerProviderStateMixin {
  final _farmFormKey = GlobalKey<FormState>();
  final _experimentalFormKey = GlobalKey<FormState>();

  // Farm-Based Calculation Controllers
  final _areaController = TextEditingController(text: '1000');
  final _biomassController = TextEditingController(text: '2000'); // kg/ha
  final _farmTemperatureController = TextEditingController(text: '30'); // °C
  final _farmSalinityController = TextEditingController(text: '20'); // ‰
  final _farmShrimpWeightController = TextEditingController(text: '15'); // g
  final _safetyMarginController = TextEditingController(text: '1.2');

  // Experimental Calculation Controllers
  final _expShrimpWeightController = TextEditingController(text: '15'); // g
  final _startO2ColumnController = TextEditingController(text: '7.0');
  final _finalO2ColumnController = TextEditingController(text: '6.0');
  final _startO2BottomController = TextEditingController(text: '6.5');
  final _finalO2BottomController = TextEditingController(text: '5.0');
  final _timeController = TextEditingController(text: '1.0');
  final _expTemperatureController = TextEditingController(text: '30');
  final _expSalinityController = TextEditingController(text: '20');
  final _sotrController = TextEditingController(text: '2.0');
  final _depthController = TextEditingController(text: '1.0');

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _selectedTabIndex = 0; // 0 for Farm-Based, 1 for Experimental

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Dispose Farm-Based Controllers
    _areaController.dispose();
    _biomassController.dispose();
    _farmTemperatureController.dispose();
    _farmSalinityController.dispose();
    _farmShrimpWeightController.dispose();
    _safetyMarginController.dispose();

    // Dispose Experimental Controllers
    _expShrimpWeightController.dispose();
    _startO2ColumnController.dispose();
    _finalO2ColumnController.dispose();
    _startO2BottomController.dispose();
    _finalO2BottomController.dispose();
    _timeController.dispose();
    _expTemperatureController.dispose();
    _expSalinityController.dispose();
    _sotrController.dispose();
    _depthController.dispose();

    _animationController.dispose();
    super.dispose();
  }

  void _calculate() {
    // Get AppLocalizations instance *once* if needed for error messages, etc.
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setLoading(true);

    if (_selectedTabIndex == 0) {
      // Farm-Based Calculation
      if (_farmFormKey.currentState!.validate()) {
        try {
          // Parse input values
          final area = double.parse(_areaController.text.replaceAll(',', ''));
          final biomass = double.parse(_biomassController.text.replaceAll(',', ''));
          final temperature = double.parse(_farmTemperatureController.text.replaceAll(',', ''));
          final salinity = double.parse(_farmSalinityController.text.replaceAll(',', ''));
          final shrimpWeight = double.parse(_farmShrimpWeightController.text.replaceAll(',', ''));
          final safetyMargin = double.parse(_safetyMarginController.text.replaceAll(',', ''));

          // Perform calculations
          final respirationRate = appState.respirationCalculator!.getRespirationRate(
            salinity,
            temperature,
            shrimpWeight,
          );

          // Estimate water and bottom respiration rates (placeholder)
          final waterRespiration = 0.1; // mg/L/h
          final bottomRespiration = 0.05; // mg/L/h
          final environmentalDemandPerHectare = (waterRespiration + bottomRespiration) * 10000 * 1e-6; // kg O₂/h/ha

          final respirationRateMgPerKgPerH = respirationRate * 1000;
          final oxygenDemandFromShrimp = biomass * respirationRateMgPerKgPerH * area;
          final oxygenDemandKgPerHour = oxygenDemandFromShrimp * 1e-6;

          final environmentalDemand = environmentalDemandPerHectare * area;

          final totalOxygenDemand = (oxygenDemandKgPerHour + environmentalDemand) * safetyMargin;

          // **FIX:** Use string literals for keys in AppState
          final inputs = {
            'farmAreaLabel': area,
            'shrimpBiomassLabel': biomass,
            'waterTemperatureLabel': temperature,
            'salinityLabel': salinity,
            'averageShrimpWeightLabel': shrimpWeight,
            'safetyMarginLabel': safetyMargin,
          };

          // **FIX:** Use string literals for keys in AppState
          final results = {
            'respirationRateLabel': respirationRate,
            'oxygenDemandFromShrimpLabel': oxygenDemandKgPerHour,
            'environmentalOxygenDemandLabel': environmentalDemand,
            'totalOxygenDemandLabel': totalOxygenDemand,
          };

          // Set results in AppState
          appState.setResults('Oxygen Demand and Estimation', results, inputs);
        } catch (e) {
          // Use the l10n object fetched at the start of the method
          appState.setError('${l10n.calculationFailed}: $e');
        }
      }
    } else {
      // Experimental Calculation
      if (_experimentalFormKey.currentState!.validate()) {
        final calculator = appState.calculator;
        final respirationCalculator = appState.respirationCalculator;

        // Use the l10n object fetched at the start of the method
        if (calculator == null || respirationCalculator == null) {
          appState.setError(l10n.calculatorNotInitialized);
          return;
        }

        try {
          // Parse input values
          final shrimpWeight = double.parse(_expShrimpWeightController.text.replaceAll(',', ''));
          final startO2Column = double.parse(_startO2ColumnController.text.replaceAll(',', ''));
          final finalO2Column = double.parse(_finalO2ColumnController.text.replaceAll(',', ''));
          final startO2Bottom = double.parse(_startO2BottomController.text.replaceAll(',', ''));
          final finalO2Bottom = double.parse(_finalO2BottomController.text.replaceAll(',', ''));
          final time = double.parse(_timeController.text.replaceAll(',', ''));
          final temperature = double.parse(_expTemperatureController.text.replaceAll(',', ''));
          final salinity = double.parse(_expSalinityController.text.replaceAll(',', ''));
          final sotr = double.parse(_sotrController.text.replaceAll(',', ''));
          final depth = double.parse(_depthController.text.replaceAll(',', ''));

          // Perform calculations
          final shrimpRespiration = respirationCalculator.getRespirationRate(
            salinity,
            temperature,
            shrimpWeight,
          );

          final columnRespiration = (startO2Column - finalO2Column) / time;
          final totalBottomRespiration = (startO2Bottom - finalO2Bottom) / time;
          final bottomRespiration = totalBottomRespiration - columnRespiration;

          const double environmentalDemandPerHectare = 0.5; // kg O₂/h/ha
          final environmentalDemandPerUnitVolume = environmentalDemandPerHectare / (10000 * depth); // kg O₂/h/m³
          final environmentalDemand = environmentalDemandPerUnitVolume; // mg/L/h

          final oxygenDemand = shrimpRespiration + columnRespiration + bottomRespiration + environmentalDemand;
          final volumePerHectare = 10000 * depth; // m³/ha
          final todPerHectare = oxygenDemand * volumePerHectare * 1e-6; // kg O₂/h/ha

          final cs100 = calculator.getO2Saturation(temperature, salinity);
          final otr20 = sotr * 0.5; // Assuming SOTR input is SAE, need OTR20 for correction
          final otrT = otr20 * pow(1.024, temperature - 20).toDouble(); // Corrected OTR formula

          final numberOfAerators = otrT > 0 ? (todPerHectare / otrT) : double.infinity;

          // **FIX:** Use string literals for keys in AppState
          final inputs = {
            'averageShrimpWeightLabel': shrimpWeight,
            'startO2ColumnLabel': startO2Column,
            'finalO2ColumnLabel': finalO2Column,
            'startO2BottomLabel': startO2Bottom,
            'finalO2BottomLabel': finalO2Bottom,
            'timeLabel': time,
            'waterTemperatureLabel': temperature,
            'salinityLabel': salinity,
            'sotrLabel': sotr, // This is likely SAE, not OTR20
            'pondDepthLabel': depth,
          };

          // **FIX:** Use string literals for keys in AppState
          final results = {
            'shrimpRespirationLabel': double.parse(shrimpRespiration.toStringAsFixed(2)),
            'columnRespirationLabel': double.parse(columnRespiration.toStringAsFixed(2)),
            'bottomRespirationLabel': double.parse(bottomRespiration.toStringAsFixed(2)),
            'environmentalOxygenDemandLabel': double.parse(environmentalDemand.toStringAsFixed(2)),
            'totalOxygenDemandMgPerLPerHLabel': double.parse(oxygenDemand.toStringAsFixed(2)),
            'todPerHectareLabel': double.parse(todPerHectare.toStringAsFixed(2)),
            'otr20Label': double.parse(otr20.toStringAsFixed(2)), // Calculated OTR20
            'otrTLabel': double.parse(otrT.toStringAsFixed(2)), // Calculated OTRT
            'numberOfAeratorsPerHectareLabel': double.parse(numberOfAerators.toStringAsFixed(2)),
          };

          // Set results in AppState
          appState.setResults('Oxygen Demand and Estimation', results, inputs);
        } catch (e) {
          // Use the l10n object fetched at the start of the method
          appState.setError('${l10n.calculationFailed}: $e');
        }
      }
    }
    // Ensure loading state is reset even if validation fails or errors occur
    // Might need adjustment based on desired UX for validation failure
     if (mounted) { // Check if widget is still mounted before calling setState
        appState.setLoading(false);
     }
  }

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
                                'assets/images/aerasync.png', // Ensure this path is correct in pubspec.yaml
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 100), // Placeholder on error
                              ),
                            ),
                          ),
                          Text(
                            // Use l10n instance from build method
                            l10n.oxygenDemandAndEstimationCalculator,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tab Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Use l10n instance from build method
                              _buildTabButton(l10n.farmBasedTabLabel, 0),
                              const SizedBox(width: 8),
                              // Use l10n instance from build method
                              _buildTabButton(l10n.experimentalTabLabel, 1),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Tab Content
                          _selectedTabIndex == 0
                              // Pass l10n instance to helper methods
                              ? _buildFarmBasedForm(l10n)
                              // Pass l10n instance to helper methods
                              : _buildExperimentalForm(l10n),
                          const SizedBox(height: 12),
                          Center(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Check form validity before triggering animation/calculation
                                  bool isValid = false;
                                  if (_selectedTabIndex == 0 && _farmFormKey.currentState!.validate()) {
                                     isValid = true;
                                  } else if (_selectedTabIndex == 1 && _experimentalFormKey.currentState!.validate()) {
                                     isValid = true;
                                  }

                                  if (isValid) {
                                    _animationController.forward().then((_) {
                                      _animationController.reverse();
                                      _calculate(); // Call calculate after animation
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // Helper method for building tab buttons
  Widget _buildTabButton(String label, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedTabIndex == index ? const Color(0xFF1E40AF) : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  // Helper method for building the Farm-Based form section
  // Pass l10n instance as parameter
  Widget _buildFarmBasedForm(AppLocalizations l10n) {
    return Form(
      key: _farmFormKey,
      child: MediaQuery.of(context).size.width < 600
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField( // Pass l10n to _buildTextField
                  _areaController,
                  l10n.farmAreaLabel,
                  0,
                  100000,
                  l10n.farmAreaTooltip,
                  l10n, // Pass l10n
                ),
                _buildTextField( // Pass l10n
                  _biomassController,
                  l10n.shrimpBiomassLabel,
                  0,
                  10000,
                  l10n.shrimpBiomassTooltip,
                  l10n, // Pass l10n
                ),
                _buildTextField( // Pass l10n
                  _farmTemperatureController,
                  l10n.waterTemperatureLabel,
                  0,
                  40,
                  l10n.waterTemperatureTooltip,
                  l10n, // Pass l10n
                ),
                _buildTextField( // Pass l10n
                  _farmSalinityController,
                  l10n.salinityLabel,
                  0,
                  40,
                  l10n.salinityTooltip,
                  l10n, // Pass l10n
                ),
                _buildTextField( // Pass l10n
                  _farmShrimpWeightController,
                  l10n.averageShrimpWeightLabel,
                  0,
                  50,
                  l10n.averageShrimpWeightTooltip,
                  l10n, // Pass l10n
                ),
                _buildTextField( // Pass l10n
                  _safetyMarginController,
                  l10n.safetyMarginLabel,
                  1,
                  2,
                  l10n.safetyMarginTooltip,
                  l10n, // Pass l10n
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField( // Pass l10n
                        _areaController,
                        l10n.farmAreaLabel,
                        0,
                        100000,
                        l10n.farmAreaTooltip,
                        l10n, // Pass l10n
                      ),
                      _buildTextField( // Pass l10n
                        _biomassController,
                        l10n.shrimpBiomassLabel,
                        0,
                        10000,
                        l10n.shrimpBiomassTooltip,
                        l10n, // Pass l10n
                      ),
                      _buildTextField( // Pass l10n
                        _farmTemperatureController,
                        l10n.waterTemperatureLabel,
                        0,
                        40,
                        l10n.waterTemperatureTooltip,
                        l10n, // Pass l10n
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField( // Pass l10n
                        _farmSalinityController,
                        l10n.salinityLabel,
                        0,
                        40,
                        l10n.salinityTooltip,
                        l10n, // Pass l10n
                      ),
                      _buildTextField( // Pass l10n
                        _farmShrimpWeightController,
                        l10n.averageShrimpWeightLabel,
                        0,
                        50,
                        l10n.averageShrimpWeightTooltip,
                        l10n, // Pass l10n
                      ),
                      _buildTextField( // Pass l10n
                        _safetyMarginController,
                        l10n.safetyMarginLabel,
                        1,
                        2,
                        l10n.safetyMarginTooltip,
                        l10n, // Pass l10n
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method for building the Experimental form section
  // Pass l10n instance as parameter
  Widget _buildExperimentalForm(AppLocalizations l10n) {
    return Form(
      key: _experimentalFormKey,
      child: MediaQuery.of(context).size.width < 600
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_expShrimpWeightController, // Pass l10n
                    l10n.averageShrimpWeightLabel, 0, 50, l10n.averageShrimpWeightTooltip, l10n),
                _buildTextField(_startO2ColumnController, // Pass l10n
                    l10n.startO2ColumnLabel, 0, 15, l10n.startO2ColumnTooltip, l10n),
                _buildTextField(_finalO2ColumnController, // Pass l10n
                    l10n.finalO2ColumnLabel, 0, 15, l10n.finalO2ColumnTooltip, l10n),
                _buildTextField(_startO2BottomController, // Pass l10n
                    l10n.startO2BottomLabel, 0, 15, l10n.startO2BottomTooltip, l10n),
                _buildTextField(_finalO2BottomController, // Pass l10n
                    l10n.finalO2BottomLabel, 0, 15, l10n.finalO2BottomTooltip, l10n),
                _buildTextField(_timeController, l10n.timeLabel, 0.1, 24, l10n.timeTooltip, l10n), // Pass l10n
                _buildTextField(_expTemperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip, l10n), // Pass l10n
                _buildTextField(_expSalinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip, l10n), // Pass l10n
                _buildTextField(_sotrController, l10n.sotrLabel, 0, 10, l10n.sotrTooltip, l10n), // Pass l10n
                _buildTextField(_depthController, l10n.pondDepthLabel, 0.5, 5, l10n.pondDepthTooltip, l10n), // Pass l10n
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(_expShrimpWeightController, // Pass l10n
                          l10n.averageShrimpWeightLabel, 0, 50, l10n.averageShrimpWeightTooltip, l10n),
                      _buildTextField(_startO2ColumnController, // Pass l10n
                          l10n.startO2ColumnLabel, 0, 15, l10n.startO2ColumnTooltip, l10n),
                      _buildTextField(_finalO2ColumnController, // Pass l10n
                          l10n.finalO2ColumnLabel, 0, 15, l10n.finalO2ColumnTooltip, l10n),
                      _buildTextField(_startO2BottomController, // Pass l10n
                          l10n.startO2BottomLabel, 0, 15, l10n.startO2BottomTooltip, l10n),
                      _buildTextField(_finalO2BottomController, // Pass l10n
                          l10n.finalO2BottomLabel, 0, 15, l10n.finalO2BottomTooltip, l10n),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(_timeController, l10n.timeLabel, 0.1, 24, l10n.timeTooltip, l10n), // Pass l10n
                      _buildTextField(_expTemperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip, l10n), // Pass l10n
                      _buildTextField(_expSalinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip, l10n), // Pass l10n
                      _buildTextField(_sotrController, l10n.sotrLabel, 0, 10, l10n.sotrTooltip, l10n), // Pass l10n
                      _buildTextField(_depthController, l10n.pondDepthLabel, 0.5, 5, l10n.pondDepthTooltip, l10n), // Pass l10n
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method for building text fields
  // Pass l10n instance as parameter for validation messages
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
              // Use numberWithOptions for better mobile keyboard experience
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Allow comma and period for decimal input
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              // Pass l10n to validator
              validator: (value) => _validateInput(value, min, max, controller, l10n),
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
  // Pass l10n instance as parameter
  String? _validateInput(String? value, double min, double max, TextEditingController controller, AppLocalizations l10n) {
    // Use passed l10n instance
    if (value == null || value.isEmpty) return l10n.requiredField;
    // Handle both comma and period as decimal separators
    final cleanedValue = value.replaceAll(',', '.');
    final numValue = double.tryParse(cleanedValue);
    if (numValue == null) return l10n.invalidNumber;
    if (numValue < min || numValue > max) return l10n.rangeError(min, max);

    // Specific validation for experimental O2 fields
    if (controller == _finalO2ColumnController) {
       final startO2 = double.tryParse(_startO2ColumnController.text.replaceAll(',', '.')) ?? double.infinity;
       if (numValue >= startO2) {
         return l10n.finalO2MustBeLessThanStartO2;
       }
    }
     if (controller == _finalO2BottomController) {
       final startO2 = double.tryParse(_startO2BottomController.text.replaceAll(',', '.')) ?? double.infinity;
       if (numValue >= startO2) {
         return l10n.finalO2MustBeLessThanStartO2;
       }
    }
    return null; // Return null if validation passes
  }
}

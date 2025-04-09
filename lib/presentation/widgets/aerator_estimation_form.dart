import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/generated/l10n.dart';
import 'dart:math';
import '../../core/services/app_state.dart';

class AeratorEstimationForm extends StatefulWidget {
  const AeratorEstimationForm({super.key});

  @override
  State<AeratorEstimationForm> createState() => _AeratorEstimationFormState();
}

class _AeratorEstimationFormState extends State<AeratorEstimationForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shrimpWeightController = TextEditingController(text: '15'); // g
  final _startO2ColumnController = TextEditingController(text: '7.0');
  final _finalO2ColumnController = TextEditingController(text: '6.0');
  final _startO2BottomController = TextEditingController(text: '6.5');
  final _finalO2BottomController = TextEditingController(text: '5.0');
  final _timeController = TextEditingController(text: '1.0');
  final _volumeController = TextEditingController(text: '10000');
  final _temperatureController = TextEditingController(text: '30');
  final _salinityController = TextEditingController(text: '20');
  final _sotrController = TextEditingController(text: '2.0');
  final _depthController = TextEditingController(text: '1.0');
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    _shrimpWeightController.dispose();
    _startO2ColumnController.dispose();
    _finalO2ColumnController.dispose();
    _startO2BottomController.dispose();
    _finalO2BottomController.dispose();
    _timeController.dispose();
    _volumeController.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _sotrController.dispose();
    _depthController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final calculator = appState.calculator;
    final respirationCalculator = appState.respirationCalculator;

    if (calculator == null || respirationCalculator == null) {
      appState.setError(AppLocalizations.of(context)!.calculatorNotInitialized);
      return;
    }

    try {
      final shrimpWeight = double.parse(_shrimpWeightController.text.replaceAll(',', ''));
      final startO2Column = double.parse(_startO2ColumnController.text.replaceAll(',', ''));
      final finalO2Column = double.parse(_finalO2ColumnController.text.replaceAll(',', ''));
      final startO2Bottom = double.parse(_startO2BottomController.text.replaceAll(',', ''));
      final finalO2Bottom = double.parse(_finalO2BottomController.text.replaceAll(',', ''));
      final time = double.parse(_timeController.text.replaceAll(',', ''));
      final volume = double.parse(_volumeController.text.replaceAll(',', ''));
      final temperature = double.parse(_temperatureController.text.replaceAll(',', ''));
      final salinity = double.parse(_salinityController.text.replaceAll(',', ''));
      final sotr = double.parse(_sotrController.text.replaceAll(',', ''));
      final depth = double.parse(_depthController.text.replaceAll(',', ''));

      final shrimpRespiration = respirationCalculator.getRespirationRate(
        salinity,
        temperature,
        shrimpWeight,
      );

      final columnRespiration = (startO2Column - finalO2Column) / time;
      final totalBottomRespiration = (startO2Bottom - finalO2Bottom) / time;
      final bottomRespiration = totalBottomRespiration - columnRespiration;

      final oxygenDemand = shrimpRespiration + columnRespiration + bottomRespiration;
      final tod = oxygenDemand * volume * 1e-6;
      final volumePerHectare = 10000 * depth;
      final todPerHectare = (tod / volume) * volumePerHectare;

      final cs100 = calculator.getO2Saturation(temperature, salinity);
      final otr20 = sotr * 0.5;
      final otrT = otr20 * pow(1.024, 20 - temperature).toDouble();

      final numberOfAerators = otrT > 0 ? (todPerHectare / otrT) : double.infinity;

      final inputs = {
        AppLocalizations.of(context)!.averageShrimpWeightLabel: shrimpWeight,
        AppLocalizations.of(context)!.startO2ColumnLabel: startO2Column,
        AppLocalizations.of(context)!.finalO2ColumnLabel: finalO2Column,
        AppLocalizations.of(context)!.startO2BottomLabel: startO2Bottom,
        AppLocalizations.of(context)!.finalO2BottomLabel: finalO2Bottom,
        AppLocalizations.of(context)!.timeLabel: time,
        AppLocalizations.of(context)!.volumeLabel: volume,
        AppLocalizations.of(context)!.waterTemperatureLabel: temperature,
        AppLocalizations.of(context)!.salinityLabel: salinity,
        AppLocalizations.of(context)!.sotrLabel: sotr,
        AppLocalizations.of(context)!.pondDepthLabel: depth,
      };

      final results = {
        AppLocalizations.of(context)!.shrimpRespirationLabel: double.parse(shrimpRespiration.toStringAsFixed(2)),
        AppLocalizations.of(context)!.columnRespirationLabel: double.parse(columnRespiration.toStringAsFixed(2)),
        AppLocalizations.of(context)!.bottomRespirationLabel: double.parse(bottomRespiration.toStringAsFixed(2)),
        AppLocalizations.of(context)!.totalOxygenDemandMgPerLPerHLabel: double.parse(oxygenDemand.toStringAsFixed(2)),
        AppLocalizations.of(context)!.todLabel: double.parse(tod.toStringAsFixed(2)),
        AppLocalizations.of(context)!.todPerHectareLabel: double.parse(todPerHectare.toStringAsFixed(2)),
        AppLocalizations.of(context)!.otr20Label: double.parse(otr20.toStringAsFixed(2)),
        AppLocalizations.of(context)!.otrTLabel: double.parse(otrT.toStringAsFixed(2)),
        AppLocalizations.of(context)!.numberOfAeratorsPerHectareLabel: double.parse(numberOfAerators.toStringAsFixed(2)),
      };

      appState.setResults('Aerator Estimation', results, inputs);
    } catch (e) {
      appState.setError('${AppLocalizations.of(context)!.calculationFailed}: $e');
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
                                'assets/images/aerasync.webp',
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Text(
                            l10n.aeratorEstimationCalculator,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Form(
                            key: _formKey,
                            child: MediaQuery.of(context).size.width < 600
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTextField(_shrimpWeightController,
                                          l10n.averageShrimpWeightLabel, 0, 50, l10n.averageShrimpWeightTooltip),
                                      _buildTextField(_startO2ColumnController,
                                          l10n.startO2ColumnLabel, 0, 15, l10n.startO2ColumnTooltip),
                                      _buildTextField(_finalO2ColumnController,
                                          l10n.finalO2ColumnLabel, 0, 15, l10n.finalO2ColumnTooltip),
                                      _buildTextField(_startO2BottomController,
                                          l10n.startO2BottomLabel, 0, 15, l10n.startO2BottomTooltip),
                                      _buildTextField(_finalO2BottomController,
                                          l10n.finalO2BottomLabel, 0, 15, l10n.finalO2BottomTooltip),
                                      _buildTextField(_timeController, l10n.timeLabel, 0.1, 24, l10n.timeTooltip),
                                      _buildTextField(_volumeController, l10n.volumeLabel, 1000, 100000, l10n.volumeTooltip),
                                      _buildTextField(_temperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip),
                                      _buildTextField(_salinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip),
                                      _buildTextField(_sotrController, l10n.sotrLabel, 0, 10, l10n.sotrTooltip),
                                      _buildTextField(_depthController, l10n.pondDepthLabel, 0.5, 5, l10n.pondDepthTooltip),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_shrimpWeightController,
                                                l10n.averageShrimpWeightLabel, 0, 50, l10n.averageShrimpWeightTooltip),
                                            _buildTextField(_startO2ColumnController,
                                                l10n.startO2ColumnLabel, 0, 15, l10n.startO2ColumnTooltip),
                                            _buildTextField(_finalO2ColumnController,
                                                l10n.finalO2ColumnLabel, 0, 15, l10n.finalO2ColumnTooltip),
                                            _buildTextField(_startO2BottomController,
                                                l10n.startO2BottomLabel, 0, 15, l10n.startO2BottomTooltip),
                                            _buildTextField(_finalO2BottomController,
                                                l10n.finalO2BottomLabel, 0, 15, l10n.finalO2BottomTooltip),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_timeController, l10n.timeLabel, 0.1, 24, l10n.timeTooltip),
                                            _buildTextField(_volumeController, l10n.volumeLabel, 1000, 100000, l10n.volumeTooltip),
                                            _buildTextField(_temperatureController, l10n.waterTemperatureLabel, 0, 40, l10n.waterTemperatureTooltip),
                                            _buildTextField(_salinityController, l10n.salinityLabel, 0, 40, l10n.salinityTooltip),
                                            _buildTextField(_sotrController, l10n.sotrLabel, 0, 10, l10n.sotrTooltip),
                                            _buildTextField(_depthController, l10n.pondDepthLabel, 0.5, 5, l10n.pondDepthTooltip),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: ElevatedButton(
                                onPressed: _formKey.currentState!.validate()
                                    ? () {
                                        _animationController.forward().then((_) {
                                          _animationController.reverse();
                                          _calculate();
                                        });
                                      }
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
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, double min, double max, String tooltip) {
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (value) => _validateInput(value, min, max),
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

  String? _validateInput(String? value, double min, double max) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredField;
    final cleanedValue = value.replaceAll(',', '');
    final numValue = double.tryParse(cleanedValue);
    if (numValue == null) return AppLocalizations.of(context)!.invalidNumber;
    if (numValue < min || numValue > max) return AppLocalizations.of(context)!.rangeError(min, max);
    return null;
  }
}
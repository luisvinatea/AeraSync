import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/generated/l10n.dart';
import '../../core/services/app_state.dart';

class OxygenDemandForm extends StatefulWidget {
  const OxygenDemandForm({super.key});

  @override
  State<OxygenDemandForm> createState() => _OxygenDemandFormState();
}

class _OxygenDemandFormState extends State<OxygenDemandForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController(text: '1000');
  final _biomassController = TextEditingController(text: '2000'); // kg/ha
  final _temperatureController = TextEditingController(text: '30'); // °C
  final _salinityController = TextEditingController(text: '20'); // ‰
  final _shrimpWeightController = TextEditingController(text: '15'); // g
  final _safetyMarginController = TextEditingController(text: '1.2');
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
    _areaController.dispose();
    _biomassController.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _shrimpWeightController.dispose();
    _safetyMarginController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateOxygenDemand() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);

      try {
        final area = double.parse(_areaController.text.replaceAll(',', ''));
        final biomass = double.parse(_biomassController.text.replaceAll(',', ''));
        final temperature = double.parse(_temperatureController.text.replaceAll(',', ''));
        final salinity = double.parse(_salinityController.text.replaceAll(',', ''));
        final shrimpWeight = double.parse(_shrimpWeightController.text.replaceAll(',', ''));
        final safetyMargin = double.parse(_safetyMarginController.text.replaceAll(',', ''));

        final respirationRate = appState.respirationCalculator!.getRespirationRate(
          salinity,
          temperature,
          shrimpWeight,
        );

        final respirationRateMgPerKgPerH = respirationRate * 1000;
        final oxygenDemandFromShrimp = biomass * respirationRateMgPerKgPerH * area;
        final oxygenDemandKgPerHour = oxygenDemandFromShrimp * 1e-6;

        const double environmentalDemandPerHectare = 0.5;
        final environmentalDemand = environmentalDemandPerHectare * area;

        final totalOxygenDemand = (oxygenDemandKgPerHour + environmentalDemand) * safetyMargin;

        final inputs = {
          AppLocalizations.of(context)!.farmAreaLabel: area,
          AppLocalizations.of(context)!.shrimpBiomassLabel: biomass,
          AppLocalizations.of(context)!.waterTemperatureLabel: temperature,
          AppLocalizations.of(context)!.salinityLabel: salinity,
          AppLocalizations.of(context)!.averageShrimpWeightLabel: shrimpWeight,
          AppLocalizations.of(context)!.safetyMarginLabel: safetyMargin,
        };

        final results = {
          AppLocalizations.of(context)!.respirationRateLabel: respirationRate,
          AppLocalizations.of(context)!.oxygenDemandFromShrimpLabel: oxygenDemandKgPerHour,
          AppLocalizations.of(context)!.environmentalOxygenDemandLabel: environmentalDemand,
          AppLocalizations.of(context)!.totalOxygenDemandLabel: totalOxygenDemand,
        };

        appState.setResults('Oxygen Demand', results, inputs);
      } catch (e) {
        appState.setError('Calculation failed: $e');
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
                    child: Text('Error: ${appState.error}',
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
                            l10n.oxygenDemandCalculator,
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
                                      _buildTextField(
                                        _areaController,
                                        l10n.farmAreaLabel,
                                        0,
                                        100000,
                                        l10n.farmAreaTooltip,
                                      ),
                                      _buildTextField(
                                        _biomassController,
                                        l10n.shrimpBiomassLabel,
                                        0,
                                        10000,
                                        l10n.shrimpBiomassTooltip,
                                      ),
                                      _buildTextField(
                                        _temperatureController,
                                        l10n.waterTemperatureLabel,
                                        0,
                                        40,
                                        l10n.waterTemperatureTooltip,
                                      ),
                                      _buildTextField(
                                        _salinityController,
                                        l10n.salinityLabel,
                                        0,
                                        40,
                                        l10n.salinityTooltip,
                                      ),
                                      _buildTextField(
                                        _shrimpWeightController,
                                        l10n.averageShrimpWeightLabel,
                                        0,
                                        50,
                                        l10n.averageShrimpWeightTooltip,
                                      ),
                                      _buildTextField(
                                        _safetyMarginController,
                                        l10n.safetyMarginLabel,
                                        1,
                                        2,
                                        l10n.safetyMarginTooltip,
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(
                                              _areaController,
                                              l10n.farmAreaLabel,
                                              0,
                                              100000,
                                              l10n.farmAreaTooltip,
                                            ),
                                            _buildTextField(
                                              _biomassController,
                                              l10n.shrimpBiomassLabel,
                                              0,
                                              10000,
                                              l10n.shrimpBiomassTooltip,
                                            ),
                                            _buildTextField(
                                              _temperatureController,
                                              l10n.waterTemperatureLabel,
                                              0,
                                              40,
                                              l10n.waterTemperatureTooltip,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(
                                              _salinityController,
                                              l10n.salinityLabel,
                                              0,
                                              40,
                                              l10n.salinityTooltip,
                                            ),
                                            _buildTextField(
                                              _shrimpWeightController,
                                              l10n.averageShrimpWeightLabel,
                                              0,
                                              50,
                                              l10n.averageShrimpWeightTooltip,
                                            ),
                                            _buildTextField(
                                              _safetyMarginController,
                                              l10n.safetyMarginLabel,
                                              1,
                                              2,
                                              l10n.safetyMarginTooltip,
                                            ),
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
                                          _calculateOxygenDemand();
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
                // Optional: Add a custom formatter for thousand separators if desired
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
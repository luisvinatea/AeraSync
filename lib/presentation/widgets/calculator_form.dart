import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/app_state.dart';

class CalculatorForm extends StatefulWidget {
  const CalculatorForm({super.key});

  @override
  State<CalculatorForm> createState() => _CalculatorFormState();
}

class _CalculatorFormState extends State<CalculatorForm> {
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController(text: '30');
  final _salinityController = TextEditingController(text: '20');
  final _hpController = TextEditingController(text: '3');
  final _volumeController = TextEditingController(text: '70');
  final _t10Controller = TextEditingController(text: '1');
  final _t70Controller = TextEditingController(text: '12');
  final _kwhController = TextEditingController(text: '0.06');
  final _brandController = TextEditingController();
  final _otherTypeController = TextEditingController();

  String _selectedType = 'Paddlewheel';
  bool _showOtherTypeField = false;
  bool _dataCollectionConsent = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;

    final List<String> _aeratorTypes = [
      l10n.paddlewheel,
      l10n.propeller,
      l10n.splash,
      l10n.diffused,
      l10n.injector,
      l10n.other
    ];

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
                            l10n.aeratorPerformanceCalculator,
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
                                      _buildTextField(_tempController, l10n.waterTemperatureLabel, 0, 40),
                                      _buildTextField(_salinityController, l10n.salinityLabel, 0, 40),
                                      _buildTextField(_hpController, l10n.horsepowerLabel, 0, 100),
                                      _buildTextField(_volumeController, l10n.volumeLabel, 0, 1000),
                                      _buildTextField(_t10Controller, l10n.t10Label, 0, 60, hint: l10n.forPlottingOnly),
                                      _buildTextField(_t70Controller, l10n.t70Label, 0.1, 60, isT70: true),
                                      _buildTextField(_kwhController, l10n.electricityCostLabel, 0, 1),
                                      TextFormField(
                                        controller: _brandController,
                                        decoration: InputDecoration(
                                          labelText: l10n.brandLabel,
                                          labelStyle: const TextStyle(fontSize: 16),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedType,
                                        items: _aeratorTypes.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value, style: const TextStyle(fontSize: 16)),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value!;
                                            _showOtherTypeField = (value == l10n.other);
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: l10n.aeratorTypeLabel,
                                          labelStyle: const TextStyle(fontSize: 16),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (_showOtherTypeField) ...[
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _otherTypeController,
                                          decoration: InputDecoration(
                                            labelText: l10n.specifyAeratorTypeLabel,
                                            labelStyle: const TextStyle(fontSize: 16),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                          ),
                                          style: const TextStyle(fontSize: 16),
                                          validator: (value) {
                                            if (_showOtherTypeField && (value == null || value.isEmpty)) {
                                              return l10n.specifyAeratorTypeRequired;
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_tempController, l10n.waterTemperatureLabel, 0, 40),
                                            _buildTextField(_salinityController, l10n.salinityLabel, 0, 40),
                                            _buildTextField(_hpController, l10n.horsepowerLabel, 0, 100),
                                            _buildTextField(_volumeController, l10n.volumeLabel, 0, 1000),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_t10Controller, l10n.t10Label, 0, 60, hint: l10n.forPlottingOnly),
                                            _buildTextField(_t70Controller, l10n.t70Label, 0.1, 60, isT70: true),
                                            _buildTextField(_kwhController, l10n.electricityCostLabel, 0, 1),
                                            TextFormField(
                                              controller: _brandController,
                                              decoration: InputDecoration(
                                                labelText: l10n.brandLabel,
                                                labelStyle: const TextStyle(fontSize: 16),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              ),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              value: _selectedType,
                                              items: _aeratorTypes.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value, style: const TextStyle(fontSize: 16)),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedType = value!;
                                                  _showOtherTypeField = (value == l10n.other);
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: l10n.aeratorTypeLabel,
                                                labelStyle: const TextStyle(fontSize: 16),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              ),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            if (_showOtherTypeField) ...[
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _otherTypeController,
                                                decoration: InputDecoration(
                                                  labelText: l10n.specifyAeratorTypeLabel,
                                                  labelStyle: const TextStyle(fontSize: 16),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                ),
                                                style: const TextStyle(fontSize: 16),
                                                validator: (value) {
                                                  if (_showOtherTypeField && (value == null || value.isEmpty)) {
                                                    return l10n.specifyAeratorTypeRequired;
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      value: _dataCollectionConsent,
                                      onChanged: (value) {
                                        setState(() {
                                          _dataCollectionConsent = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.dataCollectionConsentLabel,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final url = Uri.parse('https://luisvinatea.github.io/AeraSync/privacy.html');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.couldNotOpenPrivacyPolicy)),
                                        );
                                      }
                                    },
                                    child: Text(l10n.learnMore, style: const TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _dataCollectionConsent && _formKey.currentState!.validate()
                                    ? _calculate
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.calculateButton, style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    double min,
    double max, {
    String? hint,
    bool isT70 = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    String tooltip;
    switch (label) {
      case 'Water Temperature (°C)':
        tooltip = l10n.waterTemperatureTooltip;
        break;
      case 'Salinity (‰)':
        tooltip = l10n.salinityTooltip;
        break;
      case 'Horsepower (HP)':
        tooltip = l10n.horsepowerTooltip;
        break;
      case 'Volume (m³)':
        tooltip = l10n.volumeTooltip;
        break;
      case 'T10 (minutes)':
        tooltip = l10n.t10Tooltip;
        break;
      case 'T70 (minutes)':
        tooltip = l10n.t70Tooltip;
        break;
      case 'Electricity Cost ($/kWh)':
        tooltip = l10n.electricityCostTooltip;
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
                hintText: hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _validateInput(value, min, max, isT70: isT70),
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

  String? _validateInput(String? value, double min, double max, {bool isT70 = false}) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredField;
    final numValue = double.tryParse(value);
    if (numValue == null) return AppLocalizations.of(context)!.invalidNumber;
    if (numValue < min || numValue > max) return AppLocalizations.of(context)!.rangeError(min, max);
    if (isT70) {
      final t10 = double.tryParse(_t10Controller.text) ?? 0;
      if (numValue <= t10) return AppLocalizations.of(context)!.t70MustBeGreaterThanT10;
    }
    return null;
  }

  void _calculate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final calculator = appState.calculator;
    final l10n = AppLocalizations.of(context)!;

    if (calculator == null) {
      appState.setError(l10n.calculatorNotInitialized);
      return;
    }

    try {
      final brand = _brandController.text.isEmpty ? l10n.generic : _brandController.text;
      final type = _selectedType == l10n.other ? _otherTypeController.text : _selectedType;
      final temperature = double.parse(_tempController.text);
      final salinity = double.parse(_salinityController.text);
      final horsepower = double.parse(_hpController.text);
      final volume = double.parse(_volumeController.text);
      final t10 = double.parse(_t10Controller.text);
      final t70 = double.parse(_t70Controller.text);
      final kWhPrice = double.parse(_kwhController.text);

      final inputs = {
        l10n.waterTemperatureLabel: double.parse(temperature.toStringAsFixed(2)),
        l10n.salinityLabel: double.parse(salinity.toStringAsFixed(2)),
        l10n.horsepowerLabel: double.parse(horsepower.toStringAsFixed(2)),
        l10n.volumeLabel: double.parse(volume.toStringAsFixed(2)),
        l10n.t10Label: double.parse(t10.toStringAsFixed(2)),
        l10n.t70Label: double.parse(t70.toStringAsFixed(2)),
        l10n.electricityCostLabel: double.parse(kWhPrice.toStringAsFixed(2)),
        l10n.brandLabel: brand,
        l10n.aeratorTypeLabel: type,
        l10n.dataCollectionConsentLabel: _dataCollectionConsent,
      };

      final results = calculator.calculateMetrics(
        temperature: temperature,
        salinity: salinity,
        horsepower: horsepower,
        volume: volume,
        t10: t10,
        t70: t70,
        kWhPrice: kWhPrice,
        aeratorId: '$brand $type',
      );

      final formattedResults = results.map((key, value) =>
          MapEntry(key, value is double ? double.parse(value.toStringAsFixed(2)) : value));

      appState.setResults('Aerator Performance', formattedResults, inputs);
    } catch (e) {
      appState.setError('${l10n.calculationFailed}: $e');
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _salinityController.dispose();
    _hpController.dispose();
    _volumeController.dispose();
    _t10Controller.dispose();
    _t70Controller.dispose();
    _kwhController.dispose();
    _brandController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }
}
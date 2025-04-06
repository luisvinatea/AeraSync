import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

  final List<String> _aeratorTypes = [
    'Paddlewheel',
    'Propeller',
    'Splash',
    'Diffused',
    'Injector',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                          const Text(
                            'Aerator Performance Calculator',
                            style: TextStyle(
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
                                      _buildTextField(_tempController, 'Temperature (°C)', 0, 40),
                                      _buildTextField(_salinityController, 'Salinity (‰)', 0, 40),
                                      _buildTextField(_hpController, 'Horsepower (HP)', 0, 100),
                                      _buildTextField(_volumeController, 'Volume (m³)', 0, 1000),
                                      _buildTextField(_t10Controller, 'T10 (minutes)', 0, 60, hint: 'For plotting only'),
                                      _buildTextField(_t70Controller, 'T70 (minutes)', 0.1, 60, isT70: true),
                                      _buildTextField(_kwhController, 'Electricity Cost (\$/kWh)', 0, 1),
                                      TextFormField(
                                        controller: _brandController,
                                        decoration: InputDecoration(
                                          labelText: 'Brand (Optional)',
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
                                            _showOtherTypeField = (value == 'Other');
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Aerator Type',
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
                                            labelText: 'Specify Aerator Type',
                                            labelStyle: const TextStyle(fontSize: 16),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                          ),
                                          style: const TextStyle(fontSize: 16),
                                          validator: (value) {
                                            if (_showOtherTypeField && (value == null || value.isEmpty)) {
                                              return 'Please specify the aerator type';
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
                                            _buildTextField(_tempController, 'Temperature (°C)', 0, 40),
                                            _buildTextField(_salinityController, 'Salinity (‰)', 0, 40),
                                            _buildTextField(_hpController, 'Horsepower (HP)', 0, 100),
                                            _buildTextField(_volumeController, 'Volume (m³)', 0, 1000),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_t10Controller, 'T10 (minutes)', 0, 60, hint: 'For plotting only'),
                                            _buildTextField(_t70Controller, 'T70 (minutes)', 0.1, 60, isT70: true),
                                            _buildTextField(_kwhController, 'Electricity Cost (\$/kWh)', 0, 1),
                                            TextFormField(
                                              controller: _brandController,
                                              decoration: InputDecoration(
                                                labelText: 'Brand (Optional)',
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
                                                  _showOtherTypeField = (value == 'Other');
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Aerator Type',
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
                                                  labelText: 'Specify Aerator Type',
                                                  labelStyle: const TextStyle(fontSize: 16),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                ),
                                                style: const TextStyle(fontSize: 16),
                                                validator: (value) {
                                                  if (_showOtherTypeField && (value == null || value.isEmpty)) {
                                                    return 'Please specify the aerator type';
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
                                      'I agree to allow my data to be collected safely for research purposes, in accordance with applicable laws.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final url = Uri.parse('https://luisvinatea.github.io/AeraSync/privacy.html');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open privacy policy')),
                                        );
                                      }
                                    },
                                    child: const Text('Learn More', style: TextStyle(fontSize: 16)),
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
                                child: const Text('Calculate', style: TextStyle(fontSize: 16)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
    );
  }

  String? _validateInput(String? value, double min, double max, {bool isT70 = false}) {
    if (value == null || value.isEmpty) return 'Required';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Invalid number';
    if (numValue < min || numValue > max) return 'Must be between $min and $max';
    if (isT70) {
      final t10 = double.tryParse(_t10Controller.text) ?? 0;
      if (numValue <= t10) return 'T70 must be greater than T10';
    }
    return null;
  }

  void _calculate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final calculator = appState.calculator;

    if (calculator == null) {
      appState.setError('Calculator not initialized');
      return;
    }

    try {
      final brand = _brandController.text.isEmpty ? 'Generic' : _brandController.text;
      final type = _selectedType == 'Other' ? _otherTypeController.text : _selectedType;
      final temperature = double.parse(_tempController.text);
      final salinity = double.parse(_salinityController.text);
      final horsepower = double.parse(_hpController.text);
      final volume = double.parse(_volumeController.text);
      final t10 = double.parse(_t10Controller.text);
      final t70 = double.parse(_t70Controller.text);
      final kWhPrice = double.parse(_kwhController.text);

      final inputs = {
        'Temperature (°C)': double.parse(temperature.toStringAsFixed(2)),
        'Salinity (‰)': double.parse(salinity.toStringAsFixed(2)),
        'Horsepower (HP)': double.parse(horsepower.toStringAsFixed(2)),
        'Volume (m³)': double.parse(volume.toStringAsFixed(2)),
        'T10 (minutes)': double.parse(t10.toStringAsFixed(2)),
        'T70 (minutes)': double.parse(t70.toStringAsFixed(2)),
        'Electricity Cost (\$/kWh)': double.parse(kWhPrice.toStringAsFixed(2)),
        'Brand': brand,
        'Aerator Type': type,
        'Data Collection Consent': _dataCollectionConsent,
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
      appState.setError('Calculation failed: $e');
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
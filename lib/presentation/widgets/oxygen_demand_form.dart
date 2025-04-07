// /home/luisvinatea/Dev/Repos/AeraSync/AeraSync/lib/presentation/widgets/oxygen_demand_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show pow;
import '../../core/services/app_state.dart';

class OxygenDemandForm extends StatefulWidget {
  const OxygenDemandForm({super.key});

  @override
  State<OxygenDemandForm> createState() => _OxygenDemandFormState();
}

class _OxygenDemandFormState extends State<OxygenDemandForm> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController(text: '1000');
  final _biomassController = TextEditingController(text: '2000'); // kg/ha
  final _temperatureController = TextEditingController(text: '30'); // °C
  final _salinityController = TextEditingController(text: '20'); // ‰
  final _baseRespirationController = TextEditingController(text: '0.5'); // mg O₂/kg/h
  final _safetyMarginController = TextEditingController(text: '1.2');

  @override
  void dispose() {
    _areaController.dispose();
    _biomassController.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _baseRespirationController.dispose();
    _safetyMarginController.dispose();
    super.dispose();
  }

  void _calculateOxygenDemand() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);

      try {
        final area = double.parse(_areaController.text);
        final biomass = double.parse(_biomassController.text);
        final temperature = double.parse(_temperatureController.text);
        final salinity = double.parse(_salinityController.text);
        final baseRespiration = double.parse(_baseRespirationController.text);
        final safetyMargin = double.parse(_safetyMarginController.text);

        // Adjust respiration rate based on temperature
        // Using a simplified Q10 temperature coefficient model: respiration increases by a factor of Q10^(ΔT/10)
        const double q10 = 2.0; // Q10 value for shrimp (respiration doubles every 10°C)
        final tempAdjustment = pow(q10, (temperature - 20) / 10).toDouble();
        final adjustedRespiration = baseRespiration * tempAdjustment;

        // Adjust respiration rate based on salinity (simplified linear adjustment)
        // Higher salinity slightly reduces oxygen demand due to lower metabolic rates
        final salinityAdjustment = 1.0 - (salinity / 100); // e.g., at 20‰, reduce by 20%
        final finalRespiration = adjustedRespiration * salinityAdjustment;

        // Calculate oxygen demand from shrimp biomass (kg/ha * mg O₂/kg/h * ha = mg O₂/h)
        final oxygenDemandFromShrimp = biomass * finalRespiration * area;

        // Convert to kg O₂/h (1 mg = 1e-6 kg)
        final oxygenDemandKgPerHour = oxygenDemandFromShrimp * 1e-6;

        // Add environmental oxygen demand (simplified as a base rate per hectare)
        const double environmentalDemandPerHectare = 0.5; // kg O₂/h/ha (e.g., from water column and sediment)
        final environmentalDemand = environmentalDemandPerHectare * area;

        // Total oxygen demand
        final totalOxygenDemand = (oxygenDemandKgPerHour + environmentalDemand) * safetyMargin;

        // Inputs for CSV download
        final inputs = {
          'Farm Area (ha)': area,
          'Shrimp Biomass (kg/ha)': biomass,
          'Water Temperature (°C)': temperature,
          'Salinity (‰)': salinity,
          'Base Respiration Rate (mg O₂/kg/h)': baseRespiration,
          'Safety Margin (multiplier)': safetyMargin,
        };

        // Results for display
        final results = {
          'Oxygen Demand from Shrimp (kg O₂/h)': oxygenDemandKgPerHour,
          'Environmental Oxygen Demand (kg O₂/h)': environmentalDemand,
          'Total Oxygen Demand (kg O₂/h)': totalOxygenDemand,
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
                            'Oxygen Demand Calculator',
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
                                      _buildTextField(
                                        _areaController,
                                        'Farm Area (ha)',
                                        0,
                                        100000,
                                        'Total area of the farm in hectares',
                                      ),
                                      _buildTextField(
                                        _biomassController,
                                        'Shrimp Biomass (kg/ha)',
                                        0,
                                        10000,
                                        'Average shrimp biomass per hectare',
                                      ),
                                      _buildTextField(
                                        _temperatureController,
                                        'Water Temperature (°C)',
                                       0,
                                        40,
                                        'Average water temperature in the pond',
                                      ),
                                      _buildTextField(
                                        _salinityController,
                                        'Salinity (‰)',
                                        0,
                                        40,
                                        'Salinity of the pond water',
                                      ),
                                      _buildTextField(
                                        _baseRespirationController,
                                        'Base Respiration Rate (mg O₂/kg/h)',
                                        0,
                                        10,
                                        'Base oxygen consumption rate per kg of shrimp at 20°C',
                                      ),
                                      _buildTextField(
                                        _safetyMarginController,
                                        'Safety Margin (multiplier)',
                                        1,
                                        2,
                                        'Multiplier to account for safety (e.g., 1.2 for 20% extra demand)',
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
                                              'Farm Area (ha)',
                                              0,
                                              100000,
                                              'Total area of the farm in hectares',
                                            ),
                                            _buildTextField(
                                              _biomassController,
                                              'Shrimp Biomass (kg/ha)',
                                              0,
                                              10000,
                                              'Average shrimp biomass per hectare',
                                            ),
                                            _buildTextField(
                                              _temperatureController,
                                              'Water Temperature (°C)',
                                              0,
                                              40,
                                              'Average water temperature in the pond',
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
                                              'Salinity (‰)',
                                              0,
                                              40,
                                              'Salinity of the pond water',
                                            ),
                                            _buildTextField(
                                              _baseRespirationController,
                                              'Base Respiration Rate (mg O₂/kg/h)',
                                              0,
                                              10,
                                              'Base oxygen consumption rate per kg of shrimp at 20°C',
                                            ),
                                            _buildTextField(
                                              _safetyMarginController,
                                              'Safety Margin (multiplier)',
                                              1,
                                              2,
                                              'Multiplier to account for safety (e.g., 1.2 for 20% extra demand)',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              onPressed: _formKey.currentState!.validate()
                                  ? _calculateOxygenDemand
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Calculate',
                                  style: TextStyle(fontSize: 16)),
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
    if (value == null || value.isEmpty) return 'Required';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Invalid number';
    if (numValue < min || numValue > max) return 'Must be between $min and $max';
    return null;
  }
}
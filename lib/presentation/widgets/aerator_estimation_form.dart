import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../core/services/app_state.dart';

class AeratorEstimationForm extends StatefulWidget {
  const AeratorEstimationForm({super.key});

  @override
  State<AeratorEstimationForm> createState() => _AeratorEstimationFormState();
}

class _AeratorEstimationFormState extends State<AeratorEstimationForm> {
  final _formKey = GlobalKey<FormState>();
  final _shrimpRespirationController = TextEditingController(text: '0.5');
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
                            'Aerator Estimation Calculator',
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
                                      _buildTextField(_shrimpRespirationController,
                                          'Shrimp Respiration (mg/L/h)', 0, 10),
                                      _buildTextField(_startO2ColumnController,
                                          'Start O₂ Column (mg/L)', 0, 15),
                                      _buildTextField(_finalO2ColumnController,
                                          'Final O₂ Column (mg/L)', 0, 15),
                                      _buildTextField(_startO2BottomController,
                                          'Start O₂ Bottom (mg/L)', 0, 15),
                                      _buildTextField(_finalO2BottomController,
                                          'Final O₂ Bottom (mg/L)', 0, 15),
                                      _buildTextField(_timeController, 'Time (hours)', 0.1, 24),
                                      _buildTextField(_volumeController, 'Volume (m³)', 1000, 100000),
                                      _buildTextField(_temperatureController, 'Temperature (°C)', 0, 40),
                                      _buildTextField(_salinityController, 'Salinity (‰)', 0, 40),
                                      _buildTextField(_sotrController, 'SOTR (kg O₂/h)', 0, 10),
                                      _buildTextField(_depthController, 'Pond Depth (m)', 0.5, 5),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_shrimpRespirationController,
                                                'Shrimp Respiration (mg/L/h)', 0, 10),
                                            _buildTextField(_startO2ColumnController,
                                                'Start O₂ Column (mg/L)', 0, 15),
                                            _buildTextField(_finalO2ColumnController,
                                                'Final O₂ Column (mg/L)', 0, 15),
                                            _buildTextField(_startO2BottomController,
                                                'Start O₂ Bottom (mg/L)', 0, 15),
                                            _buildTextField(_finalO2BottomController,
                                                'Final O₂ Bottom (mg/L)', 0, 15),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_timeController, 'Time (hours)', 0.1, 24),
                                            _buildTextField(_volumeController, 'Volume (m³)', 1000, 100000),
                                            _buildTextField(_temperatureController, 'Temperature (°C)', 0, 40),
                                            _buildTextField(_salinityController, 'Salinity (‰)', 0, 40),
                                            _buildTextField(_sotrController, 'SOTR (kg O₂/h)', 0, 10),
                                            _buildTextField(_depthController, 'Pond Depth (m)', 0.5, 5),
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
                                  ? _calculate
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
      TextEditingController controller, String label, double min, double max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
    );
  }

  String? _validateInput(String? value, double min, double max) {
    if (value == null || value.isEmpty) return 'Required';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Invalid number';
    if (numValue < min || numValue > max) return 'Must be between $min and $max';
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
      final shrimpRespiration = double.parse(_shrimpRespirationController.text);
      final startO2Column = double.parse(_startO2ColumnController.text);
      final finalO2Column = double.parse(_finalO2ColumnController.text);
      final startO2Bottom = double.parse(_startO2BottomController.text);
      final finalO2Bottom = double.parse(_finalO2BottomController.text);
      final time = double.parse(_timeController.text);
      final volume = double.parse(_volumeController.text);
      final temperature = double.parse(_temperatureController.text);
      final salinity = double.parse(_salinityController.text);
      final sotr = double.parse(_sotrController.text);
      final depth = double.parse(_depthController.text);

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
        'Shrimp Respiration (mg/L/h)': double.parse(shrimpRespiration.toStringAsFixed(2)),
        'Start O₂ Column (mg/L)': double.parse(startO2Column.toStringAsFixed(2)),
        'Final O₂ Column (mg/L)': double.parse(finalO2Column.toStringAsFixed(2)),
        'Start O₂ Bottom (mg/L)': double.parse(startO2Bottom.toStringAsFixed(2)),
        'Final O₂ Bottom (mg/L)': double.parse(finalO2Bottom.toStringAsFixed(2)),
        'Time (hours)': double.parse(time.toStringAsFixed(2)),
        'Volume (m³)': double.parse(volume.toStringAsFixed(2)),
        'Temperature (°C)': double.parse(temperature.toStringAsFixed(2)),
        'Salinity (‰)': double.parse(salinity.toStringAsFixed(2)),
        'SOTR (kg O₂/h)': double.parse(sotr.toStringAsFixed(2)),
        'Pond Depth (m)': double.parse(depth.toStringAsFixed(2)),
      };

      final results = {
        'Column Respiration (mg/L/h)': double.parse(columnRespiration.toStringAsFixed(2)),
        'Bottom Respiration (mg/L/h)': double.parse(bottomRespiration.toStringAsFixed(2)),
        'Total Oxygen Demand (mg/L/h)': double.parse(oxygenDemand.toStringAsFixed(2)),
        'TOD (kg O₂/h)': double.parse(tod.toStringAsFixed(2)),
        'TOD per Hectare (kg O₂/h/ha)': double.parse(todPerHectare.toStringAsFixed(2)),
        'OTR20 (kg O₂/h)': double.parse(otr20.toStringAsFixed(2)),
        'OTRt (kg O₂/h)': double.parse(otrT.toStringAsFixed(2)),
        'Number of Aerators per Hectare': double.parse(numberOfAerators.toStringAsFixed(2)),
      };

      appState.setResults('Aerator Estimation', results, inputs);
    } catch (e) {
      appState.setError('Calculation failed: $e');
    }
  }

  @override
  void dispose() {
    _shrimpRespirationController.dispose();
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
    super.dispose();
  }
}
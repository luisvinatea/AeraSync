import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _pondAreaController = TextEditingController();
  final _pondDepthController = TextEditingController();
  final _shrimpDensityController = TextEditingController();
  final _shrimpWeightController = TextEditingController();
  final _cultureDaysController = TextEditingController();
  final _electricityCostController = TextEditingController();
  Map<String, dynamic> _aeratorData = {};
  bool _isLoading = false;
  String? _selectedAerator;

  @override
  void initState() {
    super.initState();
    _loadAeratorData();
  }

  Future<void> _loadAeratorData() async {
    try {
      final String data = await rootBundle.loadString('assets/aerators.json');
      setState(() {
        _aeratorData = jsonDecode(data);
        _selectedAerator = _aeratorData.keys.first;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.aeratorLoadFailed(e.toString()))),
      );
    }
  }

  @override
  void dispose() {
    _pondAreaController.dispose();
    _pondDepthController.dispose();
    _shrimpDensityController.dispose();
    _shrimpWeightController.dispose();
    _cultureDaysController.dispose();
    _electricityCostController.dispose();
    super.dispose();
  }

  void _submitSurvey(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      final surveyData = {
        'pondArea': double.tryParse(_pondAreaController.text) ?? 0.0,
        'pondDepth': double.tryParse(_pondDepthController.text) ?? 0.0,
        'shrimpDensity': double.tryParse(_shrimpDensityController.text) ?? 0.0,
        'shrimpWeight': double.tryParse(_shrimpWeightController.text) ?? 0.0,
        'cultureDays': int.tryParse(_cultureDaysController.text) ?? 0,
        'electricityCost': double.tryParse(_electricityCostController.text) ?? 0.0,
        'selectedAerator': _selectedAerator,
      };

      try {
        await appState.compareAerators(surveyData);
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/results');
      } catch (e) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.surveySubmissionFailed(e.toString()))),
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.pondDetails,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _pondAreaController,
                                  decoration: InputDecoration(
                                    labelText: l10n.pondAreaLabel,
                                    suffixText: 'ha',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = double.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _pondDepthController,
                                  decoration: InputDecoration(
                                    labelText: l10n.pondDepthLabel,
                                    suffixText: 'm',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = double.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.shrimpDetails,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shrimpDensityController,
                                  decoration: InputDecoration(
                                    labelText: l10n.shrimpDensityLabel,
                                    suffixText: 'shrimp/m²',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = double.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shrimpWeightController,
                                  decoration: InputDecoration(
                                    labelText: l10n.shrimpWeightLabel,
                                    suffixText: 'g',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = double.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _cultureDaysController,
                                  decoration: InputDecoration(
                                    labelText: l10n.cultureDaysLabel,
                                    suffixText: l10n.days,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.additionalInfo,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _electricityCostController,
                                  decoration: InputDecoration(
                                    labelText: l10n.electricityCostLabel,
                                    suffixText: '\$/kWh',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final numValue = double.tryParse(value);
                                    if (numValue == null || numValue < 0) {
                                      return l10n.nonNegativeNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedAerator,
                                  decoration: InputDecoration(
                                    labelText: l10n.selectAerator,
                                  ),
                                  items: _aeratorData.keys.map((aerator) {
                                    return DropdownMenuItem<String>(
                                      value: aerator,
                                      child: Text(aerator),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAerator = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _submitSurvey(context),
                            child: Text(l10n.submit),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';

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
  final _aeratorTypeController = TextEditingController();
  bool _isLoading = false;
  String? _selectedAerator;

  final List<String> _commonAeratorTypes = [
    'Paddlewheel',
    'Diffuser',
    'Propeller',
    'Venturi',
    'Other'
  ];

  @override
  void dispose() {
    _pondAreaController.dispose();
    _pondDepthController.dispose();
    _shrimpDensityController.dispose();
    _shrimpWeightController.dispose();
    _cultureDaysController.dispose();
    _electricityCostController.dispose();
    _aeratorTypeController.dispose();
    super.dispose();
  }

  Future<void> _submitSurvey(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Format data according to the expected backend API structure
      final surveyData = {
        'farm': {
          'area_ha': double.tryParse(_pondAreaController.text) ?? 0.0,
          // Using default values for required fields that aren't collected in the UI
          'pond_depth_m': double.tryParse(_pondDepthController.text) ?? 0.0,
        },
        'oxygen': {
          // Using reasonable defaults for required fields that aren't collected directly
          'temperature_c': 30.0, // Default water temperature
          'salinity_ppt': 15.0, // Default salinity
          'shrimp_weight_g':
              double.tryParse(_shrimpWeightController.text) ?? 0.0,
          'biomass_kg_ha':
              (double.tryParse(_shrimpDensityController.text) ?? 0.0) *
                  (double.tryParse(_shrimpWeightController.text) ?? 0.0) /
                  1000.0, // Convert g to kg
        },
        'aerators': [
          {
            'name': _selectedAerator ?? 'Generic Aerator',
            'power_hp': 2.0, // Default power
            'sotr_kg_o2_h': 1.2, // Default SOTR
            'initial_cost_usd': 500.0, // Default cost
            'durability_years': 3, // Default durability
            'maintenance_usd_year': 50.0 // Default maintenance
          },
          {
            'name': 'Comparison Aerator',
            'power_hp': 2.2,
            'sotr_kg_o2_h': 1.3,
            'initial_cost_usd': 600.0,
            'durability_years': 3,
            'maintenance_usd_year': 60.0
          }
        ],
        'financial': {
          'shrimp_price_usd_kg': 5.0, // Default shrimp price
          'energy_cost_usd_kwh':
              double.tryParse(_electricityCostController.text) ?? 0.05,
          'operating_hours_year':
              int.tryParse(_cultureDaysController.text) != null
                  ? int.tryParse(_cultureDaysController.text)! * 24
                  : 2880, // Culture days * 24 hours
          'discount_rate_percent': 10.0, // Default discount rate
          'inflation_rate_percent': 2.0, // Default inflation rate
          'analysis_horizon_years': 5, // Default analysis horizon
          'safety_margin_percent': 20.0 // Default safety margin
        },
      };

      try {
        await appState.compareAerators(surveyData);
        if (mounted) {
          Navigator.pushNamed(context, '/results');
        }
      } catch (e) {
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
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
                                    labelText:
                                        '${l10n.selectAerator} (${l10n.optional})',
                                  ),
                                  items: _commonAeratorTypes.map((aerator) {
                                    return DropdownMenuItem<String>(
                                      value: aerator,
                                      child: Text(aerator),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAerator = value;
                                      if (value == 'Other') {
                                        _aeratorTypeController.text = '';
                                      }
                                    });
                                  },
                                  hint: Text(l10n.selectAeratorHint),
                                ),
                                if (_selectedAerator == 'Other')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: TextFormField(
                                      controller: _aeratorTypeController,
                                      decoration: InputDecoration(
                                        labelText: l10n.customAeratorType,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _submitSurvey(context),
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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/core/services/app_state.dart';
import 'package:web/web.dart' as web;
import 'package:pdf/pdf.dart';

// Conditional import for JS interop
// ignore: uri_does_not_exist
import 'js_interop_stub.dart'
    if (dart.library.js_interop) 'js_interop_web.dart' as jsinterop;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // NEW: For bar chart
import 'package:universal_html/html.dart'
    as universal_html; // NEW: For CSV download

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Register a JavaScript callback to communicate survey data to Flutter (web only)
  // Create a global instance of AppState
  final appState = AppState();

  jsinterop.registerSurveyCallback((surveyData) {
    final data = jsinterop.jsObjectToMap(surveyData);
    appState.setSurveyData(data);
    web.window.dispatchEvent(web.CustomEvent('navigateToResults'));
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Localization Setup
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      // Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        // Match the gradient background from styles.css
        scaffoldBackgroundColor: Colors.transparent,
        // Define primary color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          primary: const Color(0xFF1E40AF),
          secondary: const Color(0xFF60A5FA),
          surface: Colors.white.withOpacity(0.95),
          onSurface: const Color(0xFF1E40AF),
        ),
        // Text theme to use Montserrat font
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E40AF),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF1E40AF),
          ),
          labelMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF1E40AF),
          ),
        ),
        // Button theme to match styles.css
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
        ),
        // Input decoration theme to match styles.css
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Color(0xFF60A5FA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Color(0xFF60A5FA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Color(0xFF60A5FA), width: 2),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF1E40AF),
          ),
        ),
      ),

      // Initial route/page
      home: const SurveyPage(),

      // Disable the debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  int _currentStep = 0;
  bool _showResults = false;
  bool _dataCollectionConsent = false; // NEW: Consent checkbox

  // Step 1: Aerator Details
  final List<Map<String, dynamic>> _aerators = [];
  final _aeratorFormKeys = <GlobalKey<FormState>>[];

  // Step 2: Farm Specs and Oxygen Demand
  final _farmFormKey = GlobalKey<FormState>();
  final _totalAreaController = TextEditingController(text: '1000');
  final _productionPerHaController = TextEditingController(text: '5000');
  final _cyclesPerYearController = TextEditingController(text: '2');
  final _temperatureController = TextEditingController(text: '31.5');
  final _salinityController = TextEditingController(text: '20');
  final _pondDepthController = TextEditingController(text: '1.0');
  final _shrimpWeightController = TextEditingController(text: '15');
  final _biomassController = TextEditingController(text: '2000'); // NEW
  final _safetyMarginController = TextEditingController(text: '1.2'); // NEW

  // Step 3: Financial Aspects
  final _financialFormKey = GlobalKey<FormState>();
  final _shrimpPriceController = TextEditingController(text: '5.0');
  final _energyCostController = TextEditingController(text: '0.05');
  final _operatingHoursController = TextEditingController(text: '8');
  final _discountRateController = TextEditingController(text: '10');
  final _inflationRateController = TextEditingController(text: '2.5');
  final _analysisHorizonController = TextEditingController(text: '9');

  @override
  void initState() {
    super.initState();
    _addAerator();
    // ignore: invalid_runtime_check_with_js_interop_types
    web.window.addEventListener('navigateToResults', _onNavigateToResults as web.EventListener);
  }

  // This must be outside initState, as a method on the State class
  void _onNavigateToResults(web.Event event) {
    setState(() {
      _showResults = true;
    });
  }

  @override
  void dispose() {
    _totalAreaController.dispose();
    _productionPerHaController.dispose();
    _cyclesPerYearController.dispose();
    _temperatureController.dispose();
    _salinityController.dispose();
    _pondDepthController.dispose();
    _shrimpWeightController.dispose();
    _biomassController.dispose();
    _safetyMarginController.dispose();
    _shrimpPriceController.dispose();
    _energyCostController.dispose();
    _operatingHoursController.dispose();
    _discountRateController.dispose();
    _inflationRateController.dispose();
    _analysisHorizonController.dispose();
    for (var aerator in _aerators) {
      aerator['brandController'].dispose();
      aerator['modelController'].dispose();
      aerator['typeController'].dispose(); // NEW
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
      aerator['klatController'].dispose();
      aerator['costController'].dispose();
      aerator['durabilityController'].dispose();
      aerator['maintenanceController'].dispose();
    }
    super.dispose();
  }

  void _addAerator() {
    setState(() {
      _aerators.add({
        'formKey': GlobalKey<FormState>(),
        'brandController': TextEditingController(),
        'modelController': TextEditingController(),
        'typeController': TextEditingController(), // NEW
        'powerController': TextEditingController(text: '3.0'),
        'sotrSource': 'supplier',
        'sotrController': TextEditingController(text: '1.4'),
        'klatController': TextEditingController(),
        'costController': TextEditingController(text: '500'),
        'durabilityController': TextEditingController(text: '2'),
        'maintenanceController': TextEditingController(text: '65'),
      });
      _aeratorFormKeys.add(_aerators.last['formKey']);
    });
  }

  void _removeAerator(int index) {
    setState(() {
      final aerator = _aerators[index];
      aerator['brandController'].dispose();
      aerator['modelController'].dispose();
      aerator['typeController'].dispose();
      aerator['powerController'].dispose();
      aerator['sotrController'].dispose();
      aerator['klatController'].dispose();
      aerator['costController'].dispose();
      aerator['durabilityController'].dispose();
      aerator['maintenanceController'].dispose();
      _aerators.removeAt(index);
      _aeratorFormKeys.removeAt(index);
    });
  }

  bool _validateStep(int step) {
    if (step == 0) {
      bool allValid = true;
      for (var formKey in _aeratorFormKeys) {
        if (!formKey.currentState!.validate()) {
          allValid = false;
        }
      }
      if (_aerators.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please add at least two aerators.')),
        );
        return false;
      }
      return allValid;
    } else if (step == 1) {
      return _farmFormKey.currentState!.validate();
    } else if (step == 2) {
      if (!_dataCollectionConsent) {
        // NEW
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Consent is required to proceed.')),
        );
        return false;
      }
      return _financialFormKey.currentState!.validate();
    }
    return true;
  }

  Future<void> _submitSurvey() async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setLoading(true);

    try {
      final aerators = _aerators.map((aerator) {
        return {
          'brand': aerator['brandController'].text,
          'model': aerator['modelController'].text,
          'type': aerator['typeController'].text, // NEW
          'power': double.parse(aerator['powerController'].text),
          'sotrSource': aerator['sotrSource'],
          'sotr': aerator['sotrSource'] == 'supplier'
              ? double.parse(aerator['sotrController'].text)
              : null,
          'klat': aerator['sotrSource'] == 'experimental'
              ? double.parse(aerator['klatController'].text)
              : null,
          'cost': double.parse(aerator['costController'].text),
          'durability': double.parse(aerator['durabilityController'].text),
          'maintenance': double.parse(aerator['maintenanceController'].text),
        };
      }).toList();

      final farmData = {
        'totalArea': double.parse(_totalAreaController.text),
        'productionPerHa': double.parse(_productionPerHaController.text),
        'cyclesPerYear': double.parse(_cyclesPerYearController.text),
      };

      final oxygenDemandData = {
        'temperature': double.parse(_temperatureController.text),
        'salinity': double.parse(_salinityController.text),
        'pondDepth': double.parse(_pondDepthController.text),
        'shrimpWeight': double.parse(_shrimpWeightController.text),
        'biomass': double.parse(_biomassController.text),
        'safetyMargin': double.parse(_safetyMarginController.text),
      };

      final financialData = {
        'shrimpPrice': double.parse(_shrimpPriceController.text),
        'energyCost': double.parse(_energyCostController.text),
        'operatingHours': double.parse(_operatingHoursController.text),
        'discountRate': double.parse(_discountRateController.text),
        'inflationRate': double.parse(_inflationRateController.text),
        'analysisHorizon': double.parse(_analysisHorizonController.text),
      };

      final requestBody = {
        'temperature': oxygenDemandData['temperature'],
        'salinity': oxygenDemandData['salinity'],
        'total_area': farmData['totalArea'],
        'pond_depth': oxygenDemandData['pondDepth'],
        'biomass_kg_ha': oxygenDemandData['biomass'],
        'safety_margin': oxygenDemandData['safetyMargin'],
        'shrimp_weight': oxygenDemandData['shrimpWeight'],
        'shrimp_density_kg_ha': farmData['productionPerHa'],
        'shrimp_price_usd_kg': financialData['shrimpPrice'],
        'cycles_per_year': farmData['cyclesPerYear'],
        'power1': aerators[0]['power'],
        'power2': aerators[1]['power'],
        'sotr1':
            aerators[0]['sotrSource'] == 'supplier' ? aerators[0]['sotr'] : 0.0,
        'sotr2':
            aerators[1]['sotrSource'] == 'supplier' ? aerators[1]['sotr'] : 0.0,
        'price1': aerators[0]['cost'],
        'price2': aerators[1]['cost'],
        'maintenance1': aerators[0]['maintenance'],
        'maintenance2': aerators[1]['maintenance'],
        'durability1': aerators[0]['durability'],
        'durability2': aerators[1]['durability'],
        'energy_cost': financialData['energyCost'],
        'operating_hours': financialData['operatingHours'],
        'discount_rate_pct': financialData['discountRate'],
        'inflation_rate_pct': financialData['inflationRate'],
        'analysis_horizon_years': (financialData['analysisHorizon'] ?? 0).toInt(),
        'use_manual_tod': false,
        'manual_tod_value': 0.0,
        'use_custom_shrimp': false,
        'custom_shrimp_rate': 0.0,
        'use_custom_water': false,
        'custom_water_rate': 0.0,
        'use_custom_bottom': false,
        'custom_bottom_rate': 0.0,
        'brand1': aerators[0]['brand'], // NEW
        'type1': aerators[0]['type'], // NEW
        'brand2': aerators[1]['brand'], // NEW
        'type2': aerators[1]['type'], // NEW
      };

      final response = await http.post(
        Uri.parse('http://localhost:8000/compare-aerators'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API call failed: ${response.statusCode} - ${response.body}');
      }

      final apiResults = jsonDecode(response.body);

      final annualRevenue = apiResults['computedAnnualRevenue'] as double;
      final tod = apiResults['totalOxygenDemand'] as double;
      final shrimpDemand = apiResults['shrimpDemand'] as double?; // NEW
      final envDemand = apiResults['envDemand'] as double?; // NEW
      final aeratorResults = [
        {
          'name':
              '${aerators[0]['brand'] ?? 'Unknown'} ${aerators[0]['model'] ?? 'Aerator'}',
          'type': aerators[0]['type'],
          'numAerators': apiResults['numberOfAerator1Units'],
          'totalAnnualCost': apiResults['totalAnnualCostAerator1'],
          'costPercentage':
              (apiResults['totalAnnualCostAerator1'] / annualRevenue) * 100,
          'sae': (apiResults['otrtAerator1'] / (aerators[0]['power'] * 0.746)),
          'npv': apiResults['netPresentValue'],
          'irr': 15.0,
          'paybackPeriod': 365.0,
          'roi': 20.0,
          'profitabilityIndex': apiResults['profitabilityIndex'] is String
              ? double.infinity
              : apiResults['profitabilityIndex'],
        },
        {
          'name':
              '${aerators[1]['brand'] ?? 'Unknown'} ${aerators[1]['model'] ?? 'Aerator'}',
          'type': aerators[1]['type'],
          'numAerators': apiResults['numberOfAerator2Units'],
          'totalAnnualCost': apiResults['totalAnnualCostAerator2'],
          'costPercentage':
              (apiResults['totalAnnualCostAerator2'] / annualRevenue) * 100,
          'sae': (apiResults['otrtAerator2'] / (aerators[1]['power'] * 0.746)),
          'npv': apiResults['netPresentValue'],
          'irr': 15.0,
          'paybackPeriod': 365.0,
          'roi': 20.0,
          'profitabilityIndex': apiResults['profitabilityIndex'] is String
              ? double.infinity
              : apiResults['profitabilityIndex'],
        },
      ];

      aeratorResults.sort((a, b) => (b['profitabilityIndex'] as double)
          .compareTo(a['profitabilityIndex'] as double));

      final surveyData = {
        'aerators': aerators,
        'farmData': farmData,
        'oxygenDemandData': oxygenDemandData,
        'financialData': financialData,
        'aeratorResults': aeratorResults,
        'tod': tod,
        'shrimpDemand': shrimpDemand,
        'envDemand': envDemand,
        'annualRevenue': annualRevenue,
        'apiResults': apiResults,
      };

      appState.setSurveyData(surveyData);
      setState(() {
        _showResults = true;
      });
    } catch (e) {
      appState.setError('Failed to process survey: $e');
    } finally {
      appState.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    if (_showResults) {
      return const ResultsPage();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appState.error != null
                ? Center(
                    child: Text(appState.error!,
                        style: const TextStyle(color: Colors.white)))
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_validateStep(_currentStep)) {
                          if (_currentStep < 2) {
                            setState(() {
                              _currentStep += 1;
                            });
                          } else {
                            _submitSurvey();
                          }
                        }
                      },
                      onStepCancel: _currentStep > 0
                          ? () {
                              setState(() {
                                _currentStep -= 1;
                              });
                            }
                          : null,
                      controlsBuilder: (context, details) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: Text(l10n.back,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                  _currentStep == 2 ? l10n.submit : l10n.next),
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: Text(l10n.aeratorDetails,
                              style: const TextStyle(color: Colors.white)),
                          content: Column(
                            children: [
                              ..._aerators.asMap().entries.map((entry) {
                                final index = entry.key;
                                final aerator = entry.value;
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.9),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Form(
                                      key: aerator['formKey'],
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${l10n.aerator1} ${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E40AF),
                                                ),
                                              ),
                                              if (_aerators.length > 2)
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _removeAerator(index),
                                                ),
                                            ],
                                          ),
                                          _buildTextField(
                                            aerator['brandController'],
                                            l10n.brandLabel,
                                            0,
                                            double.infinity,
                                            l10n.brandTooltip,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['modelController'],
                                            l10n.modelLabel,
                                            0,
                                            double.infinity,
                                            l10n.specifyAeratorTypeLabel,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['typeController'], // NEW
                                            l10n.aeratorTypeLabel,
                                            0,
                                            double.infinity,
                                            l10n.aeratorTypeTooltip,
                                            l10n,
                                            required: false,
                                          ),
                                          _buildTextField(
                                            aerator['powerController'],
                                            l10n.horsepowerLabel,
                                            0.1,
                                            100,
                                            l10n.horsepowerTooltip,
                                            l10n,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(l10n.sotrSourceLabel,
                                                  style: const TextStyle(
                                                      fontSize: 16)),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'supplier',
                                                    groupValue:
                                                        aerator['sotrSource'],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        aerator['sotrSource'] =
                                                            value!;
                                                      });
                                                    },
                                                    activeColor:
                                                        const Color(0xFF1E40AF),
                                                  ),
                                                  const Text('Supplier'),
                                                  Radio<String>(
                                                    value: 'experimental',
                                                    groupValue:
                                                        aerator['sotrSource'],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        aerator['sotrSource'] =
                                                            value!;
                                                      });
                                                    },
                                                    activeColor:
                                                        const Color(0xFF1E40AF),
                                                  ),
                                                  const Text('Experimental'),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (aerator['sotrSource'] ==
                                              'supplier')
                                            _buildTextField(
                                              aerator['sotrController'],
                                              l10n.sotrLabel,
                                              0.1,
                                              10,
                                              l10n.sotrTooltip,
                                              l10n,
                                            ),
                                          if (aerator['sotrSource'] ==
                                              'experimental')
                                            _buildTextField(
                                              aerator['klatController'],
                                              l10n.klatLabel,
                                              0.1,
                                              100,
                                              l10n.klatTooltip,
                                              l10n,
                                            ),
                                          _buildTextField(
                                            aerator['costController'],
                                            l10n.priceLabel,
                                            0,
                                            10000,
                                            l10n.priceAerator1Tooltip,
                                            l10n,
                                          ),
                                          _buildTextField(
                                            aerator['durabilityController'],
                                            l10n.durabilityLabel,
                                            0.1,
                                            20,
                                            l10n.durabilityAerator1Tooltip,
                                            l10n,
                                          ),
                                          _buildTextField(
                                            aerator['maintenanceController'],
                                            l10n.maintenanceCostLabel,
                                            0,
                                            1000,
                                            l10n.maintenanceCostAerator1Tooltip,
                                            l10n,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Center(
                                child: TextButton(
                                  onPressed: _addAerator,
                                  child: Text(l10n.addAerator,
                                      style: const TextStyle(
                                          color: Color(0xFF1E40AF))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: Text(l10n.farmAndOxygenDemand,
                              style: const TextStyle(color: Colors.white)),
                          content: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Form(
                                key: _farmFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      _totalAreaController,
                                      l10n.farmAreaLabel,
                                      0.1,
                                      100000,
                                      l10n.farmAreaTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _productionPerHaController,
                                      l10n.productionPerHaLabel,
                                      0,
                                      100000,
                                      l10n.productionPerHaTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _cyclesPerYearController,
                                      l10n.cyclesPerYearLabel,
                                      1,
                                      10,
                                      l10n.cyclesPerYearTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _temperatureController,
                                      l10n.waterTemperatureLabel,
                                      0,
                                      40,
                                      l10n.waterTemperatureTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _salinityController,
                                      l10n.salinityLabel,
                                      0,
                                      40,
                                      l10n.salinityTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _pondDepthController,
                                      l10n.pondDepthLabel,
                                      0.5,
                                      5,
                                      l10n.pondDepthTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _shrimpWeightController,
                                      l10n.averageShrimpWeightLabel,
                                      0,
                                      50,
                                      l10n.averageShrimpWeightTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _biomassController,
                                      l10n.shrimpBiomassLabel,
                                      0,
                                      100000,
                                      l10n.shrimpBiomassTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _safetyMarginController,
                                      l10n.safetyMarginLabel, // FIXED
                                      1,
                                      2,
                                      l10n.safetyMarginTooltip,
                                      l10n,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Step(
                          title: Text(l10n.financialAspects,
                              style: const TextStyle(color: Colors.white)),
                          content: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Form(
                                key: _financialFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      _shrimpPriceController,
                                      l10n.shrimpPriceLabel,
                                      0.1,
                                      50,
                                      l10n.shrimpPriceTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _energyCostController,
                                      l10n.electricityCostLabel,
                                      0,
                                      1,
                                      l10n.electricityCostTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _operatingHoursController,
                                      l10n.operatingHoursLabel,
                                      1,
                                      24,
                                      l10n.operatingHoursTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _discountRateController,
                                      l10n.discountRateLabel,
                                      0,
                                      100,
                                      l10n.discountRateTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _inflationRateController,
                                      l10n.inflationRateLabel,
                                      0,
                                      100,
                                      l10n.inflationRateTooltip,
                                      l10n,
                                    ),
                                    _buildTextField(
                                      _analysisHorizonController,
                                      l10n.analysisHorizonLabel,
                                      1,
                                      50,
                                      l10n.analysisHorizonTooltip,
                                      l10n,
                                    ),
                                    Padding(
                                      // NEW: Consent checkbox
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _dataCollectionConsent,
                                            onChanged: (value) {
                                              setState(() {
                                                _dataCollectionConsent =
                                                    value ?? false;
                                              });
                                            },
                                            activeColor:
                                                const Color(0xFF1E40AF),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _dataCollectionConsent =
                                                      !_dataCollectionConsent;
                                                });
                                              },
                                              child: Text(l10n
                                                  .dataCollectionConsentLabel),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => web.window.open(
                                              'https://luisvinatea.github.io/AeraSync/privacy.html',
                                              '_blank',
                                            ),
                                            child: Text(l10n.learnMore),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    double min,
    double max,
    String tooltip,
    AppLocalizations l10n, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (required && (value == null || value.isEmpty)) {
                  return l10n.requiredField;
                }
                if (!required && (value == null || value.isEmpty)) return null;
                final numValue = double.tryParse(value!.replaceAll(',', '.'));
                if (numValue == null) return l10n.invalidNumber;
                if (numValue < min || numValue > max) {
                  return l10n.rangeError(min, max);
                }
                return null;
              },
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
}

extension on AppLocalizations {
  String get back => 'Back';
  String get next => 'Next';
  String get submit => 'Submit';
  String get aeratorDetails => 'Aerator Details';
  
  String get brandTooltip => 'Brand of the aerator';
  
  String get modelLabel => 'Model';
  
  String get aeratorTypeTooltip => 'Type of aerator (e.g., paddlewheel, aspirator)';
  
  String get sotrSourceLabel => 'SOTR Source';
  
  String get klatLabel => 'KLaT';
  
  String get klatTooltip => 'Oxygen transfer rate (experimental)';
  
  String get priceLabel => 'Price';
  
  String get durabilityLabel => 'Durability';
  
  String get addAerator => 'Add Aerator';
  
  String get farmAndOxygenDemand => 'Farm & Oxygen Demand';
  
  String get productionPerHaLabel => 'Production per ha';
  
  String get productionPerHaTooltip => 'Total shrimp production per hectare';
  
  String get cyclesPerYearLabel => 'Cycles per year';
  
  String get cyclesPerYearTooltip => 'Number of production cycles per year';
  
  String get financialAspects => 'Financial Aspects';
  
  String get operatingHoursLabel => 'Operating Hours';
  
  String get operatingHoursTooltip => 'Number of hours aerators operate per day';

  String get noDataAvailable => 'No data available';

  String get downloadCSV => 'Download CSV';
  
  String? get aeratorComparisonResults => null;
  
  String? get results => null;
  
  String? get oxygenDemandBreakdown => null;
  
  String? get envDemandLabel => null;
  
  String? get totalDemandLabel => null;
  
  String? get downloadReport => null;
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  Future<pw.Font> _loadMontserratFont() async {
    final response = await http.get(Uri.parse(
        'https://fonts.gstatic.com/s/montserrat/v26/JTUSjIg1_i6t8kCHKm459Wlhyw.ttf'));
    if (response.statusCode == 200) {
      return pw.Font.ttf(response.bodyBytes.buffer.asByteData());
    }
    throw Exception('Failed to load Montserrat font');
  }

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    final surveyData = appState.surveyData;

    if (surveyData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDataAvailable)),
      );
      return;
    }

    try {
      // Load Montserrat font
      final montserratFont = await _loadMontserratFont();

      // Create PDF document
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: montserratFont),
      );

      // Define styles
      final primaryColor = PdfColor.fromInt(0xFF1E40AF);
      final secondaryColor = PdfColor.fromInt(0xFF60A5FA);
      final headerStyle = pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      );
      final sectionHeaderStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      );
      final bodyStyle =
          pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(0xFF000000));
      final tableHeaderStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

      // Extract data
      final aerators = surveyData['aerators'] as List<dynamic>;
      final farmData = surveyData['farmData'] as Map<String, dynamic>;
      final oxygenDemandData =
          surveyData['oxygenDemandData'] as Map<String, dynamic>;
      final financialData = surveyData['financialData'] as Map<String, dynamic>;
      final aeratorResults = (surveyData['aeratorResults'] as List<dynamic>)
          .map((result) => Map<String, dynamic>.from(result))
          .toList();
      final apiResults = surveyData['apiResults'] as Map<String, dynamic>;
      final tod = surveyData['tod'] as double;
      final shrimpDemand = surveyData['shrimpDemand'] as double?;
      final envDemand = surveyData['envDemand'] as double?;
      final annualRevenue = surveyData['annualRevenue'] as double;

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(
                'AeraSync Aerator Comparison Report',
                style: headerStyle,
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by AeraSync',
                    style: bodyStyle.copyWith(fontSize: 10),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: bodyStyle.copyWith(fontSize: 10),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) => [
            // Timestamp
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: bodyStyle.copyWith(fontStyle: pw.FontStyle.italic),
              ),
            ),
            pw.SizedBox(height: 20),

            // Survey Inputs Section
            pw.Text('Survey Inputs', style: sectionHeaderStyle),
            pw.Divider(color: secondaryColor),
            pw.SizedBox(height: 10),

            // Aerator Details
            pw.Text('Aerator Details',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            ...aerators.asMap().entries.map((entry) {
              final index = entry.key;
              final aerator = entry.value as Map<String, dynamic>;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Aerator ${index + 1}',
                      style:
                          bodyStyle.copyWith(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Bullet(
                      text: '${l10n.brandLabel}: ${aerator['brand'] ?? 'N/A'}',
                      style: bodyStyle),
                  pw.Bullet(
                      text: '${l10n.modelLabel}: ${aerator['model'] ?? 'N/A'}',
                      style: bodyStyle),
                  pw.Bullet(
                      text:
                          '${l10n.aeratorTypeLabel}: ${aerator['type'] ?? 'N/A'}',
                      style: bodyStyle),
                  pw.Bullet(
                      text: '${l10n.horsepowerLabel}: ${aerator['power']} HP',
                      style: bodyStyle),
                  if (aerator['sotrSource'] == 'supplier')
                    pw.Bullet(
                        text: '${l10n.sotrLabel}: ${aerator['sotr']} kg O₂/h',
                        style: bodyStyle),
                  if (aerator['sotrSource'] == 'experimental')
                    pw.Bullet(
                        text: '${l10n.klatLabel}: ${aerator['klat']} h⁻¹',
                        style: bodyStyle),
                  pw.Bullet(
                      text:
                          '${l10n.priceLabel}: \$${aerator['cost'].toStringAsFixed(2)}',
                      style: bodyStyle),
                  pw.Bullet(
                      text:
                          '${l10n.durabilityLabel}: ${aerator['durability']} years',
                      style: bodyStyle),
                  pw.Bullet(
                      text:
                          '${l10n.maintenanceCostLabel}: \$${aerator['maintenance'].toStringAsFixed(2)}/year',
                      style: bodyStyle),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
            pw.SizedBox(height: 10),

            // Farm Specifications
            pw.Text('Farm Specifications',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Bullet(
                text: '${l10n.farmAreaLabel}: ${farmData['totalArea']} ha',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.productionPerHaLabel}: ${farmData['productionPerHa']} kg/ha',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.cyclesPerYearLabel}: ${farmData['cyclesPerYear']}',
                style: bodyStyle),
            pw.SizedBox(height: 10),

            // Oxygen Demand Inputs
            pw.Text('Oxygen Demand Inputs',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Bullet(
                text:
                    '${l10n.waterTemperatureLabel}: ${oxygenDemandData['temperature']} °C',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.salinityLabel}: ${oxygenDemandData['salinity']} ppt',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.pondDepthLabel}: ${oxygenDemandData['pondDepth']} m',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.averageShrimpWeightLabel}: ${oxygenDemandData['shrimpWeight']} g',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.shrimpBiomassLabel}: ${oxygenDemandData['biomass']} kg/ha',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.safetyMarginLabel}: ${oxygenDemandData['safetyMargin']}',
                style: bodyStyle),
            pw.SizedBox(height: 10),

            // Financial Aspects
            pw.Text('Financial Aspects',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Bullet(
                text:
                    '${l10n.shrimpPriceLabel}: \$${financialData['shrimpPrice'].toStringAsFixed(2)}/kg',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.electricityCostLabel}: \$${financialData['energyCost'].toStringAsFixed(3)}/kWh',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.operatingHoursLabel}: ${financialData['operatingHours']} hours/day',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.discountRateLabel}: ${(financialData['discountRate']).toStringAsFixed(2)}%',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.inflationRateLabel}: ${(financialData['inflationRate']).toStringAsFixed(2)}%',
                style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.analysisHorizonLabel}: ${financialData['analysisHorizon']} years',
                style: bodyStyle),
            pw.SizedBox(height: 20),

            // Results Section
            pw.Text('Results', style: sectionHeaderStyle),
            pw.Divider(color: secondaryColor),
            pw.SizedBox(height: 10),

            // Total Oxygen Demand and Annual Revenue
            pw.Text('Summary Metrics',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Bullet(
                text:
                    'Total Oxygen Demand (TOD): ${tod.toStringAsFixed(2)} kg O₂/h',
                style: bodyStyle),
            if (shrimpDemand != null)
              pw.Bullet(
                  text:
                      'Shrimp Oxygen Demand: ${shrimpDemand.toStringAsFixed(2)} kg O₂/h',
                  style: bodyStyle),
            if (envDemand != null)
              pw.Bullet(
                  text:
                      'Environmental Oxygen Demand: ${envDemand.toStringAsFixed(2)} kg O₂/h',
                  style: bodyStyle),
            pw.Bullet(
                text:
                    '${l10n.annualRevenueLabel}: \$${annualRevenue.toStringAsFixed(2)}',
                style: bodyStyle),
            pw.SizedBox(height: 10),

            // Aerator Comparison Table
            pw.Text(l10n.aeratorComparisonResults ?? 'Aerator Comparison Results',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: secondaryColor),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1.5),
                6: pw.FlexColumnWidth(1),
                7: pw.FlexColumnWidth(1.5),
                8: pw.FlexColumnWidth(1),
                9: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Aerator', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Units Needed', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child:
                          pw.Text('Total Annual Cost', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Cost as % of Revenue',
                          style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child:
                          pw.Text('SAE (kg O₂/kWh)', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('NPV (USD)', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('IRR (%)', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Payback Period', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('ROI (%)', style: tableHeaderStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Profitability Index',
                          style: tableHeaderStyle),
                    ),
                  ],
                ),
                ...aeratorResults.map((result) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(result['name'].toString(),
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(result['numAerators'].toString(),
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '\$${result['totalAnnualCost'].toStringAsFixed(2)}',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${result['costPercentage'].toStringAsFixed(2)}%',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${result['sae'].toStringAsFixed(2)} kg O₂/kWh',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('\$${result['npv'].toStringAsFixed(2)}',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${(result['irr'] * 100).toStringAsFixed(2)}%',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${(result['paybackPeriod'] / 365).toStringAsFixed(2)} years',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${(result['roi'] * 100).toStringAsFixed(2)}%',
                            style: bodyStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            (result['profitabilityIndex'] as double).isFinite
                                ? '${result['profitabilityIndex'].toStringAsFixed(2)}'
                                : '∞',
                            style: bodyStyle),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Additional API Results
            pw.Text('Detailed Financial Metrics',
                style: sectionHeaderStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 5),
            pw.Bullet(
                text: 'Recommended Aerator: ${apiResults['winnerLabel']}',
                style: bodyStyle),
            pw.Bullet(
                text:
                    'Equilibrium Price (Aerator 2): \$${(apiResults['equilibriumPriceP2'] ?? 0).toStringAsFixed(2)}',
                style: bodyStyle),
            pw.Bullet(
                text:
                    'Cost of Opportunity: \$${(apiResults['costOfOpportunity'] ?? 0).toStringAsFixed(2)}',
                style: bodyStyle),
            pw.Bullet(
                text:
                    'Real Price of Losing Aerator: \$${(apiResults['realPriceLosingAerator'] ?? 0).toStringAsFixed(2)}',
                style: bodyStyle),
            pw.Bullet(
                text:
                    'Annual Savings: \$${(apiResults['annualSavings'] ?? 0).toStringAsFixed(2)}',
                style: bodyStyle),
            pw.SizedBox(height: 20),

            // Conclusion
            pw.Text('Conclusion', style: sectionHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text(
              'This report provides a detailed comparison of aerators based on the provided inputs. The recommended aerator is ${apiResults['winnerLabel']} based on cost efficiency and profitability metrics. For further analysis, please review the detailed metrics.',
              style: bodyStyle,
            ),
            pw.SizedBox(height: 20),

            // Acknowledgments
            pw.Text('Acknowledgments', style: sectionHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text(
              'Thank you for using AeraSync. We appreciate your trust in our tools for aquaculture management.',
              style: bodyStyle,
            ),
            pw.SizedBox(height: 20),

            // Contact Information
            pw.Text('Contact Information', style: sectionHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text(
              'For support, please contact us at aerasync@icloud.com.',
              style: bodyStyle,
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Text(
              '© 2025 AeraSync. All rights reserved.',
              style: bodyStyle.copyWith(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      // Download the PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'aerator_comparison_report.pdf',
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  void _downloadCSV(BuildContext context) {
    // NEW
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    final surveyData = appState.surveyData;

    if (surveyData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDataAvailable)),
      );
      return;
    }

    final aeratorResults = surveyData['aeratorResults'] as List<dynamic>;
    final apiResults = surveyData['apiResults'] as Map<String, dynamic>;
    final tod = surveyData['tod'] as double;
    final annualRevenue = surveyData['annualRevenue'] as double;
    final shrimpDemand = surveyData['shrimpDemand'] as double?;
    final envDemand = surveyData['envDemand'] as double?;

    final csv = StringBuffer();
    csv.writeln('Metric,Value,Unit');
    csv.writeln('Total Oxygen Demand,${tod.toStringAsFixed(2)},kg O₂/h');
    if (shrimpDemand != null) {
      csv.writeln(
          'Shrimp Oxygen Demand,${shrimpDemand.toStringAsFixed(2)},kg O₂/h');
    }
    if (envDemand != null) {
      csv.writeln(
          'Environmental Oxygen Demand,${envDemand.toStringAsFixed(2)},kg O₂/h');
    }
    csv.writeln('Annual Revenue,${annualRevenue.toStringAsFixed(2)},USD');
    csv.writeln('Recommended Aerator,${apiResults['winnerLabel']},');
    csv.writeln('');
    csv.writeln('Aerator Comparison');
    csv.writeln(
        'Aerator,Units Needed,Total Annual Cost (USD),Cost as % of Revenue,SAE (kg O₂/kWh),NPV (USD),IRR (%),Payback Period (years),ROI (%),Profitability Index');
    for (var result in aeratorResults) {
      final pi = (result['profitabilityIndex'] as double).isFinite
          ? result['profitabilityIndex'].toStringAsFixed(2)
          : '∞';
      csv.writeln(
          '${result['name']},${result['numAerators']},${result['totalAnnualCost'].toStringAsFixed(2)},${result['costPercentage'].toStringAsFixed(2)},${result['sae'].toStringAsFixed(2)},${result['npv'].toStringAsFixed(2)},${(result['irr'] * 100).toStringAsFixed(2)},${(result['paybackPeriod'] / 365).toStringAsFixed(2)},${(result['roi'] * 100).toStringAsFixed(2)},$pi');
    }
    csv.writeln('');
    csv.writeln('Detailed Financial Metrics');
    csv.writeln('Metric,Value,Unit');
    csv.writeln(
        'Equilibrium Price (Aerator 2),${(apiResults['equilibriumPriceP2'] ?? 0).toStringAsFixed(2)},USD');
    csv.writeln(
        'Cost of Opportunity,${(apiResults['costOfOpportunity'] ?? 0).toStringAsFixed(2)},USD');
    csv.writeln(
        'Annual Savings,${(apiResults['annualSavings'] ?? 0).toStringAsFixed(2)},USD');

    final bytes = utf8.encode(csv.toString());
    final blob = universal_html.Blob([bytes], 'text/csv');
    final url = universal_html.Url.createObjectUrlFromBlob(blob);
    final anchor = universal_html.AnchorElement(href: url)
      ..setAttribute('download', 'aerator_comparison.csv');
    anchor.click();
    universal_html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final surveyData = appState.surveyData;

    if (surveyData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.results ?? 'Results'),
          backgroundColor: const Color(0xFF1E40AF),
        ),
        body: Center(child: Text(l10n.noDataAvailable)),
      );
    }

    final aeratorResults = (surveyData['aeratorResults'] as List<dynamic>)
        .map((result) => Map<String, dynamic>.from(result))
        .toList();
    final apiResults = surveyData['apiResults'] as Map<String, dynamic>;
    final tod = surveyData['tod'] as double;
    final shrimpDemand = surveyData['shrimpDemand'] as double?;
    final envDemand = surveyData['envDemand'] as double?;
    final annualRevenue = surveyData['annualRevenue'] as double;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.results ?? 'Results'),
        backgroundColor: const Color(0xFF1E40AF),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Metrics
                Card(
                  elevation: 4,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary Metrics',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Oxygen Demand (TOD): ${tod.toStringAsFixed(2)} kg O₂/h',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (shrimpDemand != null) // NEW
                          Text(
                            'Shrimp Oxygen Demand: ${shrimpDemand.toStringAsFixed(2)} kg O₂/h',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (envDemand != null) // NEW
                          Text(
                            'Environmental Oxygen Demand: ${envDemand.toStringAsFixed(2)} kg O₂/h',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        Text(
                          '${l10n.annualRevenueLabel}: \$${annualRevenue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Recommended Aerator: ${apiResults['winnerLabel']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Oxygen Demand Chart (NEW)
                if (shrimpDemand != null && envDemand != null)
                  Card(
                    elevation: 4,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.oxygenDemandBreakdown ?? 'Oxygen Demand Breakdown',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: [shrimpDemand, envDemand, tod]
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: shrimpDemand,
                                        color: const Color(0xFF1E40AF),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: envDemand,
                                        color: const Color(0xFF60A5FA),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: tod,
                                        color: const Color(0xFF3B82F6),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        switch (value.toInt()) {
                                          case 0:
                                            return Text(l10n.shrimpDemandLabel);
                                          case 1:
                                            return Text(l10n.envDemandLabel ?? 'Environmental Demand');
                                          case 2:
                                            return Text(l10n.totalDemandLabel ?? 'Total Demand');
                                          default:
                                            return const Text('');
                                        }
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(),
                                  rightTitles: const AxisTitles(),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Aerator Comparison Table
                Card(
                  elevation: 4,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aeratorComparisonResults ?? 'Aerator Comparison Results',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Aerator')),
                              DataColumn(label: Text('Units Needed')),
                              DataColumn(label: Text('Total Annual Cost')),
                              DataColumn(label: Text('Cost as % of Revenue')),
                              DataColumn(label: Text('SAE (kg O₂/kWh)')),
                              DataColumn(label: Text('NPV (USD)')),
                              DataColumn(label: Text('IRR (%)')),
                              DataColumn(label: Text('Payback Period')),
                              DataColumn(label: Text('ROI (%)')),
                              DataColumn(label: Text('Profitability Index')),
                            ],
                            rows: aeratorResults.map((result) {
                              return DataRow(cells: [
                                DataCell(Text(result['name'].toString())),
                                DataCell(
                                    Text(result['numAerators'].toString())),
                                DataCell(Text(
                                    '\$${result['totalAnnualCost'].toStringAsFixed(2)}')),
                                DataCell(Text(
                                    '${result['costPercentage'].toStringAsFixed(2)}%')),
                                DataCell(Text(
                                    '${result['sae'].toStringAsFixed(2)}')),
                                DataCell(Text(
                                    '\$${result['npv'].toStringAsFixed(2)}')),
                                DataCell(Text(
                                    '${(result['irr'] * 100).toStringAsFixed(2)}%')),
                                DataCell(Text(
                                    '${(result['paybackPeriod'] / 365).toStringAsFixed(2)} years')),
                                DataCell(Text(
                                    '${(result['roi'] * 100).toStringAsFixed(2)}%')),
                                DataCell(Text((result['profitabilityIndex']
                                            as double)
                                        .isFinite
                                    ? '${result['profitabilityIndex'].toStringAsFixed(2)}'
                                    : '∞')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Additional Metrics
                Card(
                  elevation: 4,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detailed Financial Metrics',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Equilibrium Price (Aerator 2): \$${(apiResults['equilibriumPriceP2'] ?? 0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Cost of Opportunity: \$${(apiResults['costOfOpportunity'] ?? 0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Annual Savings: \$${(apiResults['annualSavings'] ?? 0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Download Buttons
                Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () => _generateAndDownloadPDF(context),
                        child: Text(l10n.downloadReport ?? 'Download Report'),
                      ),
                      ElevatedButton(
                        onPressed: () => _downloadCSV(context), // NEW
                        child: Text(l10n.downloadCSV),
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

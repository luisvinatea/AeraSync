import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import needed for input formatters
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

  // Initialize _selectedType in initState or directly using l10n if available early,
  // otherwise initialize with a default string and update in build if needed.
  // Using a placeholder here and setting it properly in build/initState.
  String _selectedType = 'Paddlewheel'; // Placeholder
  bool _selectedTypeInitialized = false;

  bool _showOtherTypeField = false;
  bool _dataCollectionConsent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _selectedType here where context (and l10n) is available
    if (!_selectedTypeInitialized) {
       final l10n = AppLocalizations.of(context)!;
       _selectedType = l10n.paddlewheel; // Set initial value using l10n
       _selectedTypeInitialized = true;
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Get l10n instance once for the build method
    final l10n = AppLocalizations.of(context)!;

    // Define aerator types using l10n instance
    final List<String> aeratorTypes = [
      l10n.paddlewheel,
      l10n.propeller,
      l10n.splash,
      l10n.diffused,
      l10n.injector,
      l10n.other
    ];

    // Ensure _selectedType is valid if it hasn't been initialized yet
    // This might happen if build runs before didChangeDependencies completes init
    if (!_selectedTypeInitialized || !aeratorTypes.contains(_selectedType)) {
       _selectedType = l10n.paddlewheel; // Default to paddlewheel
       // Avoid calling setState here directly in build
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) { // Check if still mounted
           setState(() {
              _selectedTypeInitialized = true;
           });
         }
       });
    }


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
                                'assets/images/aerasync.png', // Ensure path is correct
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 100), // Placeholder
                              ),
                            ),
                          ),
                          Text(
                            l10n.aeratorPerformanceCalculator, // Use l10n instance
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
                                ? Column( // Single column layout
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _buildInputFields(l10n, aeratorTypes), // Pass l10n and types
                                  )
                                : Row( // Two column layout
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: Column(children: _buildInputFields(l10n, aeratorTypes, column: 1))),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(children: _buildInputFields(l10n, aeratorTypes, column: 2))),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          // Consent and Calculate Button Section
                          Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch, // Make button stretch
                            children: [
                              Row(
                                children: [
                                  // Make checkbox larger and easier to tap
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: _dataCollectionConsent,
                                      onChanged: (value) {
                                        setState(() {
                                          _dataCollectionConsent = value ?? false;
                                        });
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.padded, // Increase tap area
                                      activeColor: const Color(0xFF1E40AF), // Theme color
                                    ),
                                  ),
                                  Expanded(
                                    // Allow text to wrap
                                    child: InkWell( // Make text tappable to toggle checkbox
                                       onTap: () {
                                          setState(() {
                                             _dataCollectionConsent = !_dataCollectionConsent;
                                          });
                                       },
                                       child: Text(
                                          l10n.dataCollectionConsentLabel, // Use l10n instance
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                    ),

                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Consider using a more specific URL if possible
                                      final url = Uri.parse('https://luisvinatea.github.io/AeraSync/privacy.html');
                                      try {
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          } else {
                                             throw 'Could not launch $url';
                                          }
                                      } catch (e) {
                                         if (mounted) { // Check mount status before showing SnackBar
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${l10n.couldNotOpenPrivacyPolicy}: $e')),
                                            );
                                         }
                                      }
                                    },
                                    child: Text(l10n.learnMore, style: const TextStyle(fontSize: 16)), // Use l10n instance
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _dataCollectionConsent && _formKey.currentState?.validate() == true // Check form validity
                                    ? _calculate // Call calculate directly
                                    : null, // Disable button if consent not given or form invalid
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  // Provide visual feedback when disabled
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                                child: Text(l10n.calculateButton, style: const TextStyle(fontSize: 16)), // Use l10n instance
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

  // Helper to build list of input fields for layout flexibility
  List<Widget> _buildInputFields(AppLocalizations l10n, List<String> aeratorTypes, {int? column}) {
    final fields = [
      _buildTextField(l10n, _tempController, l10n.waterTemperatureLabel, 0, 40, tooltip: l10n.waterTemperatureTooltip),
      _buildTextField(l10n, _salinityController, l10n.salinityLabel, 0, 40, tooltip: l10n.salinityTooltip),
      _buildTextField(l10n, _hpController, l10n.horsepowerLabel, 0, 100, tooltip: l10n.horsepowerTooltip),
      _buildTextField(l10n, _volumeController, l10n.volumeLabel, 0, 1000, tooltip: l10n.volumeTooltip),
      _buildTextField(l10n, _t10Controller, l10n.t10Label, 0, 60, hint: l10n.forPlottingOnly, tooltip: l10n.t10Tooltip),
      _buildTextField(l10n, _t70Controller, l10n.t70Label, 0.1, 60, isT70: true, tooltip: l10n.t70Tooltip),
      _buildTextField(l10n, _kwhController, l10n.electricityCostLabel, 0, 1, tooltip: l10n.electricityCostTooltip),
      // Brand TextFormField
      Padding(
         padding: const EdgeInsets.only(bottom: 8.0),
         child: TextFormField(
           controller: _brandController,
           decoration: InputDecoration(
             labelText: l10n.brandLabel,
             labelStyle: const TextStyle(fontSize: 16),
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
             filled: true, fillColor: Colors.grey[100],
             contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
           ),
           style: const TextStyle(fontSize: 16),
         ),
      ),
      // Aerator Type Dropdown
      Padding(
         padding: const EdgeInsets.only(bottom: 8.0),
         child: DropdownButtonFormField<String>(
           value: _selectedType,
           items: aeratorTypes.map((String value) {
             return DropdownMenuItem<String>(
               value: value,
               child: Text(value, style: const TextStyle(fontSize: 16)),
             );
           }).toList(),
           onChanged: (value) {
             if (value != null) {
               setState(() {
                 _selectedType = value;
                 _showOtherTypeField = (value == l10n.other);
               });
             }
           },
           decoration: InputDecoration(
             labelText: l10n.aeratorTypeLabel,
             labelStyle: const TextStyle(fontSize: 16),
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
             filled: true, fillColor: Colors.grey[100],
             contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
           ),
           // style: const TextStyle(fontSize: 16, color: Colors.black), // Ensure text color is appropriate
           isExpanded: true, // Make dropdown take full width
         ),
      ),
      // Other Type Field (Conditional)
      if (_showOtherTypeField)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: _otherTypeController,
            decoration: InputDecoration(
              labelText: l10n.specifyAeratorTypeLabel,
              labelStyle: const TextStyle(fontSize: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              filled: true, fillColor: Colors.grey[100],
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
        ),
    ];

    if (column == null) return fields; // Return all for single column

    // Distribute fields for two columns
    final List<Widget> columnFields = [];
    for (int i = 0; i < fields.length; i++) {
      // Simple alternating distribution
      if (column == 1 && i % 2 == 0) {
        columnFields.add(fields[i]);
      } else if (column == 2 && i % 2 != 0) {
        columnFields.add(fields[i]);
      }
    }
     // Handle case with odd number of fields - add last field to first column
     if (column == 1 && fields.length % 2 != 0 && columnFields.length < (fields.length + 1) / 2) {
        columnFields.add(fields.last);
     }

    return columnFields;
  }


  // Updated helper method for building text fields
  Widget _buildTextField(
    AppLocalizations l10n, // Pass l10n
    TextEditingController controller,
    String label,
    double min,
    double max, {
    String? hint,
    bool isT70 = false,
    String? tooltip, // Use provided tooltip directly
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
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
              // Use appropriate keyboard type
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Allow comma and period for decimals
              inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              // Pass l10n to validator
              validator: (value) => _validateInput(l10n, value, min, max, isT70: isT70),
            ),
          ),
          // Add tooltip if provided
          if (tooltip != null && tooltip.isNotEmpty) ...[
             const SizedBox(width: 8),
             Tooltip(
               message: tooltip,
               child: const Icon(Icons.info_outline, color: Colors.grey, size: 20), // Slightly smaller icon
             ),
          ] else ... [
             // Add some space even if no tooltip to maintain alignment
             const SizedBox(width: 28), // Approx width of icon + padding
          ],
        ],
      ),
    );
  }

  // Updated validator method
  String? _validateInput(AppLocalizations l10n, String? value, double min, double max, {bool isT70 = false}) {
    if (value == null || value.isEmpty) return l10n.requiredField;
    // Handle both comma and period
    final cleanedValue = value.replaceAll(',', '.');
    final numValue = double.tryParse(cleanedValue);
    if (numValue == null) return l10n.invalidNumber;
    if (numValue < min || numValue > max) return l10n.rangeError(min, max);
    if (isT70) {
      // Ensure t10 value is parsed correctly
      final t10Value = _t10Controller.text.replaceAll(',', '.');
      final t10 = double.tryParse(t10Value);
      // Check if t10 is valid before comparing
      if (t10 == null) {
         // This case should ideally be caught by t10's own validator
         return l10n.invalidNumber; // Or a more specific error
      }
      if (numValue <= t10) return l10n.t70MustBeGreaterThanT10;
    }
    return null; // Validation passed
  }

  // Updated calculate method
  void _calculate() async {
    // Ensure form is valid before proceeding
    if (!(_formKey.currentState?.validate() ?? false)) {
       return; // Don't calculate if form is invalid
    }
     if (!_dataCollectionConsent) {
        // Optionally show a message if consent is required but not given
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.consentRequiredMessage)), // Add this to l10n
        );
        return;
     }


    final appState = Provider.of<AppState>(context, listen: false);
    final calculator = appState.calculator;
    // Get l10n instance once
    final l10n = AppLocalizations.of(context)!;

    if (calculator == null) {
      appState.setError(l10n.calculatorNotInitialized);
      return;
    }

    appState.setLoading(true); // Set loading state
    appState.clearError(); // Clear previous errors


    try {
      // Parse values safely, handling potential format errors
      final brand = _brandController.text.trim().isEmpty ? l10n.generic : _brandController.text.trim();
      final type = _selectedType == l10n.other ? _otherTypeController.text.trim() : _selectedType;

      // Use helper to parse doubles, handling commas
      final temperature = _parseDouble(_tempController.text);
      final salinity = _parseDouble(_salinityController.text);
      final horsepower = _parseDouble(_hpController.text);
      final volume = _parseDouble(_volumeController.text);
      final t10 = _parseDouble(_t10Controller.text);
      final t70 = _parseDouble(_t70Controller.text);
      final kWhPrice = _parseDouble(_kwhController.text);

      // **FIX:** Use string literals for keys in AppState inputs map
      final inputs = {
        'waterTemperatureLabel': temperature, // Use consistent string keys
        'salinityLabel': salinity,
        'horsepowerLabel': horsepower,
        'volumeLabel': volume,
        't10Label': t10,
        't70Label': t70,
        'electricityCostLabel': kWhPrice,
        'brandLabel': brand,
        'aeratorTypeLabel': type,
        'dataCollectionConsentLabel': _dataCollectionConsent, // Include consent status
      };

      // Call the calculator method
      final results = calculator.calculateMetrics(
        temperature: temperature,
        salinity: salinity,
        horsepower: horsepower,
        volume: volume,
        t10: t10,
        t70: t70,
        kWhPrice: kWhPrice,
        aeratorId: '$brand $type', // Pass combined ID
      );

      // Format results (ensure keys remain strings)
      final formattedResults = results.map((key, value) {
         // Format only double values, keep other types (like strings) as is
         if (value is double) {
            // Handle NaN or Infinity before formatting
            if (value.isNaN) return MapEntry(key, 'NaN');
            if (value.isInfinite) return MapEntry(key, 'Infinite'); // Or use l10n.infinite
            // Format with 2 decimal places
            return MapEntry(key, double.parse(value.toStringAsFixed(2)));
         }
         return MapEntry(key, value); // Keep non-double values as they are
      });

      // Set results in AppState
      appState.setResults('Aerator Performance', formattedResults, inputs);

    } catch (e) {
       print("Calculation Error: $e"); // Log error
       // Use the l10n instance obtained earlier
       appState.setError('${l10n.calculationFailed}: ${e.toString()}');
    } finally {
       if (mounted) { // Check if widget is still mounted
          appState.setLoading(false); // Ensure loading state is turned off
       }
    }
  }

  // Helper to parse double, handling both comma and period
  double _parseDouble(String value) {
    final cleanedValue = value.trim().replaceAll(',', '.');
    return double.parse(cleanedValue);
  }

}

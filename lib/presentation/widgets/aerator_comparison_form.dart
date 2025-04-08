import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/app_state.dart';

class AeratorComparisonForm extends StatefulWidget {
  const AeratorComparisonForm({super.key});

  @override
  State<AeratorComparisonForm> createState() => _AeratorComparisonFormState();
}

class _AeratorComparisonFormState extends State<AeratorComparisonForm> {
  final _formKey = GlobalKey<FormState>();
  final _oxygenDemandController = TextEditingController(text: '3000');
  final _sotr1Controller = TextEditingController(text: '1.4');
  final _sotr2Controller = TextEditingController(text: '2.2');
  final _price1Controller = TextEditingController(text: '500');
  final _price2Controller = TextEditingController(text: '800');
  final _maintenance1Controller = TextEditingController(text: '65');
  final _maintenance2Controller = TextEditingController(text: '50');
  final _durability1Controller = TextEditingController(text: '2');
  final _durability2Controller = TextEditingController(text: '4.5');
  final _energyCostController = TextEditingController(text: '326.75');

  @override
  void dispose() {
    _oxygenDemandController.dispose();
    _sotr1Controller.dispose();
    _sotr2Controller.dispose();
    _price1Controller.dispose();
    _price2Controller.dispose();
    _maintenance1Controller.dispose();
    _maintenance2Controller.dispose();
    _durability1Controller.dispose();
    _durability2Controller.dispose();
    _energyCostController.dispose();
    super.dispose();
  }

  void _calculateEquilibrium() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLoading(true);

      try {
        final oxygenDemand = double.parse(_oxygenDemandController.text);
        final sotr1 = double.parse(_sotr1Controller.text);
        final sotr2 = double.parse(_sotr2Controller.text);
        final price1 = double.parse(_price1Controller.text);
        final price2 = double.parse(_price2Controller.text);
        final maintenance1 = double.parse(_maintenance1Controller.text);
        final maintenance2 = double.parse(_maintenance2Controller.text);
        final durability1 = double.parse(_durability1Controller.text);
        final durability2 = double.parse(_durability2Controller.text);
        final energyCost = double.parse(_energyCostController.text);

        // Calculate number of aerators needed
        final n1 = oxygenDemand / sotr1;
        final n2 = oxygenDemand / sotr2;

        // Calculate equilibrium price P2
        final p2Equilibrium = (durability2 / sotr1) *
            (sotr2 * (energyCost + maintenance1 + (price1 / durability1)) -
                sotr1 * (energyCost + maintenance2));

        // Calculate total annual costs for each aerator
        final totalCost1 = n1 * (energyCost + maintenance1 + (price1 / durability1));
        final totalCost2 = n2 * (energyCost + maintenance2 + (price2 / durability2));

        // Inputs for CSV download
        final inputs = {
          AppLocalizations.of(context)!.totalOxygenDemandLabel: oxygenDemand,
          AppLocalizations.of(context)!.sotrAerator1Label: sotr1,
          AppLocalizations.of(context)!.sotrAerator2Label: sotr2,
          AppLocalizations.of(context)!.priceAerator1Label: price1,
          AppLocalizations.of(context)!.priceAerator2Label: price2,
          AppLocalizations.of(context)!.maintenanceCostAerator1Label: maintenance1,
          AppLocalizations.of(context)!.maintenanceCostAerator2Label: maintenance2,
          AppLocalizations.of(context)!.durabilityAerator1Label: durability1,
          AppLocalizations.of(context)!.durabilityAerator2Label: durability2,
          AppLocalizations.of(context)!.annualEnergyCostLabel: energyCost,
        };

        // Results for display
        final results = {
          AppLocalizations.of(context)!.numberOfAerator1UnitsLabel: n1,
          AppLocalizations.of(context)!.numberOfAerator2UnitsLabel: n2,
          AppLocalizations.of(context)!.totalAnnualCostAerator1Label: totalCost1,
          AppLocalizations.of(context)!.totalAnnualCostAerator2Label: totalCost2,
          AppLocalizations.of(context)!.equilibriumPriceP2Label: p2Equilibrium,
          AppLocalizations.of(context)!.actualPriceP2Label: price2,
        };

        appState.setResults('Aerator Comparison', results, inputs);
      } catch (e) {
        appState.setError('${AppLocalizations.of(context)!.calculationFailed}: $e');
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
                            l10n.aeratorComparisonCalculator,
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
                                      _buildTextField(_oxygenDemandController,
                                          l10n.totalOxygenDemandLabel, 0, 100000),
                                      _buildTextField(_sotr1Controller,
                                          l10n.sotrAerator1Label, 0, 10),
                                      _buildTextField(_sotr2Controller,
                                          l10n.sotrAerator2Label, 0, 10),
                                      _buildTextField(_price1Controller,
                                          l10n.priceAerator1Label, 0, 10000),
                                      _buildTextField(_price2Controller,
                                          l10n.priceAerator2Label, 0, 10000),
                                      _buildTextField(_maintenance1Controller,
                                          l10n.maintenanceCostAerator1Label, 0, 1000),
                                      _buildTextField(_maintenance2Controller,
                                          l10n.maintenanceCostAerator2Label, 0, 1000),
                                      _buildTextField(_durability1Controller,
                                          l10n.durabilityAerator1Label, 0.1, 20),
                                      _buildTextField(_durability2Controller,
                                          l10n.durabilityAerator2Label, 0.1, 20),
                                      _buildTextField(_energyCostController,
                                          l10n.annualEnergyCostLabel, 0, 1000),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_oxygenDemandController,
                                                l10n.totalOxygenDemandLabel, 0, 100000),
                                            _buildTextField(_sotr1Controller,
                                                l10n.sotrAerator1Label, 0, 10),
                                            _buildTextField(_sotr2Controller,
                                                l10n.sotrAerator2Label, 0, 10),
                                            _buildTextField(_price1Controller,
                                                l10n.priceAerator1Label, 0, 10000),
                                            _buildTextField(_price2Controller,
                                                l10n.priceAerator2Label, 0, 10000),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildTextField(_maintenance1Controller,
                                                l10n.maintenanceCostAerator1Label, 0, 1000),
                                            _buildTextField(_maintenance2Controller,
                                                l10n.maintenanceCostAerator2Label, 0, 1000),
                                            _buildTextField(_durability1Controller,
                                                l10n.durabilityAerator1Label, 0.1, 20),
                                            _buildTextField(_durability2Controller,
                                                l10n.durabilityAerator2Label, 0.1, 20),
                                            _buildTextField(_energyCostController,
                                                l10n.annualEnergyCostLabel, 0, 1000),
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
                                  ? _calculateEquilibrium
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
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, double min, double max) {
    final l10n = AppLocalizations.of(context)!;
    String tooltip;
    switch (label) {
      case 'Total Oxygen Demand (kg O₂/h)':
        tooltip = l10n.totalOxygenDemandTooltip;
        break;
      case 'SOTR Aerator 1 (kg O₂/h per aerator)':
        tooltip = l10n.sotrAerator1Tooltip;
        break;
      case 'SOTR Aerator 2 (kg O₂/h per aerator)':
        tooltip = l10n.sotrAerator2Tooltip;
        break;
      case 'Price Aerator 1 (USD per aerator)':
        tooltip = l10n.priceAerator1Tooltip;
        break;
      case 'Price Aerator 2 (USD per aerator)':
        tooltip = l10n.priceAerator2Tooltip;
        break;
      case 'Maintenance Cost Aerator 1 (USD/year per aerator)':
        tooltip = l10n.maintenanceCostAerator1Tooltip;
        break;
      case 'Maintenance Cost Aerator 2 (USD/year per aerator)':
        tooltip = l10n.maintenanceCostAerator2Tooltip;
        break;
      case 'Durability Aerator 1 (years)':
        tooltip = l10n.durabilityAerator1Tooltip;
        break;
      case 'Durability Aerator 2 (years)':
        tooltip = l10n.durabilityAerator2Tooltip;
        break;
      case 'Annual Energy Cost (USD/year per aerator)':
        tooltip = l10n.annualEnergyCostTooltip;
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
    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredField;
    final numValue = double.tryParse(value);
    if (numValue == null) return AppLocalizations.of(context)!.invalidNumber;
    if (numValue < min || numValue > max) return AppLocalizations.of(context)!.rangeError(min, max);
    return null;
  }
}
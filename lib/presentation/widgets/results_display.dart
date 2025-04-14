import 'dart:math'; // Import for max/min functions used in charts

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../core/services/app_state.dart';

class ResultsDisplay extends StatefulWidget {
  final String tab;

  const ResultsDisplay({super.key, required this.tab});

  @override
  _ResultsDisplayState createState() => _ResultsDisplayState();
}

class _ResultsDisplayState extends State<ResultsDisplay> {
  bool _showBarChart = true; // State to toggle between bar chart and pie chart

  // Helper method to safely get localized string based on string key
  // Maintain this map consistent with keys used in ALL calculator forms
  String _getL10nString(AppLocalizations l10n, String key, {String defaultValue = ''}) {
    switch (key) {
      // Aerator Comparison Keys
      case 'totalAnnualCostAerator1Label': return l10n.totalAnnualCostAerator1Label;
      case 'totalAnnualCostAerator2Label': return l10n.totalAnnualCostAerator2Label;
      case 'totalOxygenDemand': return l10n.totalOxygenDemandLabel;
      case 'numberOfAerator1Units': return l10n.numberOfAerator1UnitsLabel;
      case 'numberOfAerator2Units': return l10n.numberOfAerator2UnitsLabel;
      case 'equilibriumPriceP2': return l10n.equilibriumPriceP2Label;
      case 'actualPriceP2': return l10n.actualPriceP2Label;
      case 'sotrAerator1': return l10n.sotrAerator1Label;
      case 'sotrAerator2': return l10n.sotrAerator2Label;
      case 'priceAerator1': return l10n.priceAerator1Label;
      case 'priceAerator2': return l10n.priceAerator2Label;
      case 'maintenanceCostAerator1': return l10n.maintenanceCostAerator1Label;
      case 'maintenanceCostAerator2': return l10n.maintenanceCostAerator2Label;
      case 'durabilityAerator1': return l10n.durabilityAerator1Label;
      case 'durabilityAerator2': return l10n.durabilityAerator2Label;
      case 'annualEnergyCostAerator1': return l10n.annualEnergyCostLabel;
      case 'annualEnergyCostAerator2': return l10n.annualEnergyCostLabel;
      case 'temperature': return l10n.waterTemperatureLabel;
      case 'salinity': return l10n.salinityLabel;
      case 'biomass': return l10n.shrimpBiomassLabel;
      case 'shrimpRespirationRate': return l10n.shrimpRespirationRateLabel;
      case 'waterRespirationRate': return l10n.waterRespirationRateLabel;
      case 'bottomRespirationRate': return l10n.bottomRespirationRateLabel;
      case 'discountRate': return l10n.discountRateLabel;
      case 'inflationRate': return l10n.inflationRateLabel;
      case 'analysisHorizon': return l10n.analysisHorizonLabel;
      case 'useManualTOD': return l10n.useManualTODLabel;
      case 'useCustomShrimpRespiration': return l10n.useCustomShrimpRespirationLabel;
      case 'useCustomWaterRespiration': return l10n.useCustomWaterRespirationLabel;
      case 'useCustomBottomRespiration': return l10n.useCustomBottomRespirationLabel;
      case 'otrTAerator1': return l10n.otrTLabel;
      case 'otrTAerator2': return l10n.otrTLabel;
      case 'shrimpDemandTotal': return l10n.shrimpDemandLabel;
      case 'waterDemandPerHa': return l10n.waterDemandLabel;
      case 'bottomDemandPerHa': return l10n.bottomDemandLabel;
      case 'profitabilityIndex': return 'Profitability Index (k)';
      case 'netPresentValue': return 'Net Present Value (VPN, USD)';
      case 'paybackPeriodDays': return 'Payback Period (days)';
      case 'returnOnInvestment': return 'Return On Investment (ROI, %)';
      case 'internalRateOfReturn': return l10n.internalRateOfReturn;
      case 'costOfOpportunity': return l10n.costOfOpportunityLabelShort;
      case 'realPriceLosingAerator': return 'Real Price of Losing Aerator (USD)';
      case 'loserLabel': return 'Less Optimal Aerator';
      case 'numberOfUnitsLosingAerator': return 'Units of Losing Aerator';
      case 'annualRevenue': return l10n.annualRevenueLabel;
      case 'netProfitAerator1': return l10n.netProfitAerator1Label;
      case 'netProfitAerator2': return l10n.netProfitAerator2Label;
      case 'farmSize': return l10n.farmSizeLabel;
      case 'shrimpPrice': return l10n.shrimpPriceLabel;
      case 'hpAerator1': return l10n.hpAerator1Label;
      case 'hpAerator2': return l10n.hpAerator2Label;

      // Oxygen Demand Keys
      case 'farmAreaLabel': return l10n.farmAreaLabel;
      case 'shrimpBiomassLabel': return l10n.shrimpBiomassLabel;
      case 'waterTemperatureLabel': return l10n.waterTemperatureLabel;
      case 'salinityLabel': return l10n.salinityLabel;
      case 'averageShrimpWeightLabel': return l10n.averageShrimpWeightLabel;
      case 'safetyMarginLabel': return l10n.safetyMarginLabel;
      case 'respirationRateLabel': return l10n.respirationRateLabel;
      case 'oxygenDemandFromShrimpLabel': return l10n.oxygenDemandFromShrimpLabel;
      case 'environmentalOxygenDemandLabel': return l10n.environmentalOxygenDemandLabel;
      case 'totalOxygenDemandLabel': return l10n.totalOxygenDemandLabel;
      case 'startO2ColumnLabel': return l10n.startO2ColumnLabel;
      case 'finalO2ColumnLabel': return l10n.finalO2ColumnLabel;
      case 'startO2BottomLabel': return l10n.startO2BottomLabel;
      case 'finalO2BottomLabel': return l10n.finalO2BottomLabel;
      case 'timeLabel': return l10n.timeLabel;
      case 'sotrLabel': return l10n.sotrLabel;
      case 'pondDepthLabel': return l10n.pondDepthLabel;
      case 'shrimpRespirationLabel': return l10n.shrimpRespirationLabel;
      case 'columnRespirationLabel': return l10n.columnRespirationLabel;
      case 'bottomRespirationLabel': return l10n.bottomRespirationLabel;
      case 'totalOxygenDemandMgPerLPerHLabel': return l10n.totalOxygenDemandMgPerLPerHLabel;
      case 'todPerHectareLabel': return l10n.todPerHectareLabel;
      case 'otr20Label': return l10n.otr20Label;
      case 'otrTLabel': return l10n.otrTLabel;
      case 'numberOfAeratorsPerHectareLabel': return l10n.numberOfAeratorsPerHectareLabel;

      // Aerator Performance Keys
      case 'horsepowerLabel': return l10n.horsepowerLabel;
      case 'volumeLabel': return l10n.volumeLabel;
      case 't10Label': return l10n.t10Label;
      case 't70Label': return l10n.t70Label;
      case 'electricityCostLabel': return l10n.electricityCostLabel;
      case 'brandLabel': return l10n.brandLabel;
      case 'aeratorTypeLabel': return l10n.aeratorTypeLabel;
      case 'dataCollectionConsentLabel': return l10n.dataCollectionConsentLabel;
      // Results from Aerator Performance calc
      case 'Pond Volume (m³)': return l10n.pondVolumeLabel;
      case 'Cs (mg/L)': return l10n.csLabel;
      case 'KlaT (h⁻¹)': return l10n.klaTLabel;
      case 'Kla20 (h⁻¹)': return l10n.kla20Label;
      case 'SOTR (kg O₂/h)': return l10n.sotrLabel;
      case 'SAE (kg O₂/kWh)': return l10n.saeLabel;
      case 'Cost per kg O₂ (USD/kg O₂)': return l10n.costPerKgO2Label;
      case 'Power (kW)': return l10n.powerLabel;
      case 'Annual Energy Cost (USD/year)': return l10n.annualEnergyCostLabel;
      case 'Normalized Aerator ID': return l10n.aeratorIdLabel;
      case 'Cs20 (mg/L)': return l10n.cs20Label;

      default:
        debugPrint("Warning: Missing localization mapping for key '$key' in ResultsDisplay");
        return key;
    }
  }

  // Helper method to get tooltips for result metrics
  String _getL10nTooltip(AppLocalizations l10n, String key) {
    switch (key) {
      case 'totalOxygenDemand':
        return l10n.totalOxygenDemandTooltip;
      case 'farmSize':
        return l10n.farmSizeTooltip;
      case 'shrimpPrice':
        return l10n.shrimpPriceTooltip;
      case 'sotrAerator1':
        return l10n.sotrAerator1Tooltip;
      case 'sotrAerator2':
        return l10n.sotrAerator2Tooltip;
      case 'hpAerator1':
        return l10n.hpAerator1Tooltip;
      case 'hpAerator2':
        return l10n.hpAerator2Tooltip;
      case 'priceAerator1':
        return l10n.priceAerator1Tooltip;
      case 'priceAerator2':
        return l10n.priceAerator2Tooltip;
      case 'maintenanceCostAerator1':
        return l10n.maintenanceCostAerator1Tooltip;
      case 'maintenanceCostAerator2':
        return l10n.maintenanceCostAerator2Tooltip;
      case 'durabilityAerator1':
        return l10n.durabilityAerator1Tooltip;
      case 'durabilityAerator2':
        return l10n.durabilityAerator2Tooltip;
      case 'annualEnergyCostAerator1':
        return l10n.annualEnergyCostTooltip;
      case 'annualEnergyCostAerator2':
        return l10n.annualEnergyCostTooltip;
      case 'temperature':
        return l10n.waterTemperatureTooltip;
      case 'salinity':
        return l10n.salinityTooltip;
      case 'biomass':
        return l10n.shrimpBiomassTooltip;
      case 'shrimpRespirationRate':
        return l10n.shrimpRespirationRateTooltip;
      case 'waterRespirationRate':
        return l10n.waterRespirationRateTooltip;
      case 'bottomRespirationRate':
        return l10n.bottomRespirationRateTooltip;
      case 'discountRate':
        return l10n.discountRateTooltip;
      case 'inflationRate':
        return l10n.inflationRateTooltip;
      case 'analysisHorizon':
        return l10n.analysisHorizonTooltip;
      // Results
      case 'otrTAerator1':
        return 'Oxygen Transfer Rate for Aerator 1 at operating temperature (kg O₂/h per aerator).';
      case 'otrTAerator2':
        return 'Oxygen Transfer Rate for Aerator 2 at operating temperature (kg O₂/h per aerator).';
      case 'shrimpDemandTotal':
        return 'Total oxygen demand from shrimp for the farm (kg O₂/h).';
      case 'waterDemandPerHa':
        return 'Oxygen demand from the water column per hectare (kg O₂/h/ha).';
      case 'bottomDemandPerHa':
        return 'Oxygen demand from the pond bottom per hectare (kg O₂/h/ha).';
      case 'numberOfAerator1Units':
        return 'Total number of Aerator 1 units required for the farm.';
      case 'numberOfAerator2Units':
        return 'Total number of Aerator 2 units required for the farm.';
      case 'totalAnnualCostAerator1Label':
        return l10n.totalAnnualCostAerator1Tooltip;
      case 'totalAnnualCostAerator2Label':
        return l10n.totalAnnualCostAerator2Tooltip;
      case 'annualRevenue':
        return l10n.annualRevenueTooltip;
      case 'netProfitAerator1':
        return l10n.netProfitAerator1Tooltip;
      case 'netProfitAerator2':
        return l10n.netProfitAerator2Tooltip;
      case 'equilibriumPriceP2':
        return 'Price at which Aerator 2’s total annual cost equals Aerator 1’s.';
      case 'actualPriceP2':
        return 'Current price of Aerator 2 for comparison.';
      case 'profitabilityIndex':
        return 'Ratio of present value of savings to initial investment difference.';
      case 'netPresentValue':
        return 'Net present value of savings over the analysis horizon (USD).';
      case 'paybackPeriodDays':
        return 'Time required to recover the initial investment difference (days).';
      case 'returnOnInvestment':
        return 'Simple return on investment based on annual savings (%).';
      case 'internalRateOfReturn':
        return l10n.internalRateOfReturnTooltip;
      case 'costOfOpportunity':
        return l10n.costOfOpportunityTooltip;
      case 'realPriceLosingAerator':
        return 'Effective price of the less optimal aerator including opportunity cost (USD).';
      case 'loserLabel':
        return 'The aerator that is less cost-effective.';
      case 'numberOfUnitsLosingAerator':
        return 'Number of units required for the less optimal aerator.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults(widget.tab);
        final inputs = appState.getInputs(widget.tab);

        if (results == null || results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.enterValuesToCalculate,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Recommendation message for Aerator Comparison
        String? recommendationMessage;
        double costOfOpportunity = 0.0;
        if (widget.tab == 'Aerator Comparison') {
          final totalCost1Value = results['totalAnnualCostAerator1Label'];
          final totalCost2Value = results['totalAnnualCostAerator2Label'];
          final costOfOpportunityValue = results['costOfOpportunity'];

          final totalCost1 = totalCost1Value is num ? totalCost1Value.toDouble() : 0.0;
          final totalCost2 = totalCost2Value is num ? totalCost2Value.toDouble() : 0.0;
          costOfOpportunity = costOfOpportunityValue is num ? costOfOpportunityValue.toDouble() : 0.0;

          if (totalCost1 > totalCost2) {
            recommendationMessage = l10n.recommendationChooseAerator2(costOfOpportunity.abs());
          } else if (totalCost2 > totalCost1) {
            recommendationMessage = l10n.recommendationChooseAerator1(costOfOpportunity.abs());
          } else {
            recommendationMessage = l10n.recommendationEqualCosts;
          }
        }

        // Group results into sections for Aerator Comparison
        final Map<String, Map<String, dynamic>> groupedResults = {
          l10n.oxygenDemandGroup: <String, dynamic>{},
          l10n.aeratorMetricsGroup: <String, dynamic>{},
          l10n.financialMetricsGroup: <String, dynamic>{},
        };

        if (widget.tab == 'Aerator Comparison') {
          const oxygenKeys = ['totalOxygenDemand', 'shrimpDemandTotal', 'waterDemandPerHa', 'bottomDemandPerHa'];
          const aeratorKeys = ['otrTAerator1', 'otrTAerator2', 'numberOfAerator1Units', 'numberOfAerator2Units'];
          results.forEach((key, value) {
            if (oxygenKeys.contains(key)) {
              groupedResults[l10n.oxygenDemandGroup]![key] = value;
            } else if (aeratorKeys.contains(key)) {
              groupedResults[l10n.aeratorMetricsGroup]![key] = value;
            } else {
              groupedResults[l10n.financialMetricsGroup]![key] = value;
            }
          });
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white.withOpacity(0.9),
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.performanceMetrics,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Toggle button for Aerator Comparison
                  if (widget.tab == 'Aerator Comparison') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _showBarChart = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showBarChart ? const Color(0xFF1E40AF) : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.barChartLabel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _showBarChart = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showBarChart ? const Color(0xFF1E40AF) : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.pieChartLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Chart for Aerator Estimation and Aerator Comparison
                  if (widget.tab == 'Aerator Estimation') ...[
                    _buildAeratorEstimationChart(results, l10n),
                    const SizedBox(height: 16),
                  ],
                  if (widget.tab == 'Aerator Comparison') ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: child),
                        );
                      },
                      child: _showBarChart
                          ? _buildAeratorComparisonBarChart(results, l10n, key: const ValueKey('barChart'))
                          : _buildAeratorComparisonPieChart(results, l10n, key: const ValueKey('pieChart')),
                    ),
                    const SizedBox(height: 16),
                    if (groupedResults[l10n.oxygenDemandGroup]!.isNotEmpty &&
                        groupedResults[l10n.oxygenDemandGroup]!.values.any((v) => v is num && v > 0)) ...[
                      _buildOxygenDemandPieChart(groupedResults[l10n.oxygenDemandGroup]!, l10n),
                      const SizedBox(height: 16),
                    ],
                    if (inputs != null && results.containsKey('totalAnnualCostAerator1Label')) ...[
                      _buildCostBreakdownTable(results, inputs, l10n),
                      const SizedBox(height: 16),
                      _buildCostBreakdownPieChart(results, inputs, l10n),
                      const SizedBox(height: 16),
                    ]
                  ],
                  // Recommendation Message for Aerator Comparison
                  if (recommendationMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        recommendationMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Grouped results for Aerator Comparison
                  if (widget.tab == 'Aerator Comparison') ...[
                    ...groupedResults.entries.map((group) {
                      if (group.value.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              group.key,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: group.value.length,
                            itemBuilder: (context, index) {
                              final entry = group.value.entries.elementAt(index);
                              final isKeyMetric = entry.key == 'profitabilityIndex' ||
                                  entry.key == 'costOfOpportunity' ||
                                  entry.key == 'realPriceLosingAerator';
                              final displayLabel = _getL10nString(l10n, entry.key, defaultValue: entry.key);
                              String displayValue = _formatValueWithThousandSeparator(entry.key, entry.value, l10n);
                              final tooltip = _getL10nTooltip(l10n, entry.key);
                              if (entry.key == 'realPriceLosingAerator') {
                                final loserName = results['loserLabel'] ?? '?';
                                final loserDisplay = loserName == 'Aerator 1'
                                    ? l10n.aerator1
                                    : (loserName == 'Aerator 2' ? l10n.aerator2 : loserName);
                                displayValue += ' ($loserDisplay)';
                              } else if (entry.key == 'loserLabel') {
                                displayValue = entry.value == 'Aerator 1'
                                    ? l10n.aerator1
                                    : (entry.value == 'Aerator 2' ? l10n.aerator2 : entry.value.toString());
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        displayLabel,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayValue,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E40AF),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          if (tooltip.isNotEmpty)
                                            Tooltip(
                                              message: tooltip,
                                              child: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                                            ),
                                          if (isKeyMetric) ...[
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                final formattedVal = _formatValue(entry.value, l10n);
                                                FlutterClipboard.copy(formattedVal).then((_) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(l10n.valueCopied(formattedVal)),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                });
                                              },
                                              tooltip: l10n.copyToClipboardTooltip,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(height: 1),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ] else ...[
                    // Default results list for other tabs
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final entry = results.entries.elementAt(index);
                        final isKeyMetric = (widget.tab == 'Aerator Performance' && entry.key == 'SOTR (kg O₂/h)') ||
                            (widget.tab == 'Oxygen Demand and Estimation' && entry.key == 'numberOfAeratorsPerHectareLabel');
                        final displayLabel = _getL10nString(l10n, entry.key, defaultValue: entry.key);
                        final tooltip = _getL10nTooltip(l10n, entry.key);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  displayLabel,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatValueWithThousandSeparator(entry.key, entry.value, l10n),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (tooltip.isNotEmpty)
                                      Tooltip(
                                        message: tooltip,
                                        child: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                                      ),
                                    if (isKeyMetric) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          final formattedVal = _formatValue(entry.value, l10n);
                                          FlutterClipboard.copy(formattedVal).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.valueCopied(formattedVal)),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          });
                                        },
                                        tooltip: l10n.copyToClipboardTooltip,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (inputs != null)
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadAsCsv(context, inputs, results),
                        icon: const Icon(Icons.download),
                        label: Text(l10n.downloadCsvButton),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Chart Building Methods ---

  Widget _buildAeratorEstimationChart(Map<String, dynamic> results, AppLocalizations l10n) {
    final todValue = results['todPerHectareLabel'];
    final otrTValue = results['otrTLabel'];
    final aeratorsValue = results['numberOfAeratorsPerHectareLabel'];

    final tod = todValue is num ? todValue.toDouble() : 0.0;
    final otrT = otrTValue is num ? otrTValue.toDouble() : 0.0;
    final aerators = aeratorsValue is num ? aeratorsValue.toDouble() : 0.0;

    final metrics = [
      if (tod >= 0) {'title': l10n.todLabelShort, 'value': tod},
      if (otrT >= 0) {'title': l10n.otrTLabelShort, 'value': otrT},
      if (aerators >= 0) {'title': l10n.aeratorsLabelShort, 'value': aerators},
    ];

    if (metrics.isEmpty) {
      return SizedBox(height: 200, child: Center(child: Text(l10n.noDataForChart)));
    }

    final maxYValue = metrics.map((e) => e['value'] as double).fold(0.0, max);
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0;
    final interval = maxY / 5 > 0 ? maxY / 5 : 1.0;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final metric = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: metric['value'] as double,
                  color: const Color(0xFF1E40AF),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (maxY == 1.0 && value == 0) return const SizedBox.shrink();
                  final format = (maxY > 100 || value.abs() > 100) ? NumberFormat.compact() : NumberFormat("0.0");
                  return Text(
                    format.format(value),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < metrics.length) {
                    return Text(
                      metrics[index]['title'] as String,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: interval.toDouble(),
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
    );
  }

  Widget _buildAeratorComparisonBarChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
    final cost1Value = results['totalAnnualCostAerator1Label'];
    final cost2Value = results['totalAnnualCostAerator2Label'];
    final opportunityCostValue = results['costOfOpportunity'];

    final cost1 = cost1Value is num ? cost1Value.toDouble() : 0.0;
    final cost2 = cost2Value is num ? cost2Value.toDouble() : 0.0;
    final opportunityCost = opportunityCostValue is num ? opportunityCostValue.toDouble() : 0.0;

    final metrics = [
      if (cost1 >= 0) {
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': cost1,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
      },
      if (cost2 >= 0) {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': cost2,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
      },
      if (opportunityCost.abs() > 1e-6) {
        'title': l10n.costOfOpportunityLabelShort,
        'value': opportunityCost,
        'tooltip': l10n.costOfOpportunityTooltip,
      },
    ];

    if (metrics.isEmpty) {
      return SizedBox(key: key, height: 200, child: Center(child: Text(l10n.noDataForChart)));
    }

    final allValues = metrics.map((e) => e['value'] as double).toList();
    final maxPositiveValue = allValues.where((v) => v > 0).fold(0.0, max);
    final minNegativeValue = allValues.where((v) => v < 0).fold(0.0, min);

    final maxY = maxPositiveValue > 0 ? maxPositiveValue * 1.2 : (allValues.any((v) => v == 0) ? 1.0 : 0.0);
    final minY = minNegativeValue < 0 ? minNegativeValue * 1.2 : 0.0;
    final interval = (maxY - minY) / 5 > 0 ? (maxY - minY) / 5 : 1.0;

    return SizedBox(
      key: key,
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: minY,
          barGroups: metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final metric = entry.value;
            final value = metric['value'] as double;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: value >= 0 ? const Color(0xFF1E40AF) : Colors.redAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == minY || value == maxY) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < metrics.length) {
                    return Text(
                      metrics[index]['title'] as String,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: interval.toDouble(),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= metrics.length) return null;
                final metric = metrics[groupIndex];
                String text = '${metric['title']}\n${_formatValueWithThousandSeparator(metric['title'], rod.toY, l10n)}';
                return BarTooltipItem(
                  text,
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
    );
  }

  Widget _buildAeratorComparisonPieChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
    final cost1Value = results['totalAnnualCostAerator1Label'];
    final cost2Value = results['totalAnnualCostAerator2Label'];

    final cost1 = cost1Value is num ? cost1Value.toDouble() : 0.0;
    final cost2 = cost2Value is num ? cost2Value.toDouble() : 0.0;

    final metrics = [
      if (cost1 > 0) {
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': cost1,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
        'color': Colors.blue.shade700,
      },
      if (cost2 > 0) {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': cost2,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
        'color': Colors.green.shade700,
      },
    ];

    if (metrics.isEmpty) {
      return SizedBox(key: key, height: 200, child: Center(child: Text(l10n.noDataForChart)));
    }

    final totalValue = metrics.map((e) => e['value'] as double).fold(0.0, (a, b) => a + b);

    if (totalValue <= 0) {
      return SizedBox(key: key, height: 200, child: Center(child: Text(l10n.noPositiveDataForChart)));
    }

    return SizedBox(
      key: key,
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: metrics.asMap().entries.map((entry) {
                  final metric = entry.value;
                  final percentage = (metric['value'] as double) / totalValue * 100;
                  return PieChartSectionData(
                    color: metric['color'] as Color,
                    value: metric['value'] as double,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    showTitle: percentage > 5,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: metrics.map((metric) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: metric['color'] as Color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(metric['title'] as String, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOxygenDemandPieChart(Map<String, dynamic> oxygenDemandResults, AppLocalizations l10n) {
    final shrimpDemandValue = oxygenDemandResults['shrimpDemandTotal'];
    final waterDemandValue = oxygenDemandResults['waterDemandPerHa'];
    final bottomDemandValue = oxygenDemandResults['bottomDemandPerHa'];

    final shrimpDemand = shrimpDemandValue is num ? shrimpDemandValue.toDouble() : 0.0;
    final waterDemand = (waterDemandValue is num ? waterDemandValue.toDouble() : 0.0) * 1000;
    final bottomDemand = (bottomDemandValue is num ? bottomDemandValue.toDouble() : 0.0) * 1000;

    final metrics = [
      if (shrimpDemand > 0) {
        'title': l10n.shrimpDemandLabel,
        'value': shrimpDemand,
        'color': Colors.blue.shade700
      },
      if (waterDemand > 0) {
        'title': l10n.waterDemandLabel,
        'value': waterDemand,
        'color': Colors.green.shade700
      },
      if (bottomDemand > 0) {
        'title': l10n.bottomDemandLabel,
        'value': bottomDemand,
        'color': Colors.orange.shade700
      },
    ];

    if (metrics.isEmpty) return const SizedBox.shrink();

    final totalValue = metrics.map((e) => e['value'] as double).fold(0.0, (a, b) => a + b);

    if (totalValue <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.oxygenDemandBreakdownChartTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: metrics.asMap().entries.map((entry) {
                      final metric = entry.value;
                      final percentage = (metric['value'] as double) / totalValue * 100;
                      return PieChartSectionData(
                        color: metric['color'] as Color,
                        value: metric['value'] as double,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        showTitle: percentage > 5,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 0),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: metrics.map((metric) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: metric['color'] as Color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(metric['title'] as String, style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostBreakdownTable(Map<String, dynamic> results, Map<String, dynamic> inputs, AppLocalizations l10n) {
    final energyCost1Value = inputs['annualEnergyCostAerator1'];
    final energyCost2Value = inputs['annualEnergyCostAerator2'];
    final maintenance1Value = inputs['maintenanceCostAerator1'];
    final maintenance2Value = inputs['maintenanceCostAerator2'];
    final price1Value = inputs['priceAerator1'];
    final price2Value = inputs['priceAerator2'];
    final durability1Value = inputs['durabilityAerator1'];
    final durability2Value = inputs['durabilityAerator2'];

    final energyCost1 = energyCost1Value is num ? energyCost1Value.toDouble() : 0.0;
    final energyCost2 = energyCost2Value is num ? energyCost2Value.toDouble() : 0.0;
    final maintenance1 = maintenance1Value is num ? maintenance1Value.toDouble() : 0.0;
    final maintenance2 = maintenance2Value is num ? maintenance2Value.toDouble() : 0.0;
    final price1 = price1Value is num ? price1Value.toDouble() : 0.0;
    final price2 = price2Value is num ? price2Value.toDouble() : 0.0;
    final durability1 = durability1Value is num && durability1Value > 0 ? durability1Value.toDouble() : 1.0;
    final durability2 = durability2Value is num && durability2Value > 0 ? durability2Value.toDouble() : 1.0;

    final n1Result = results['numberOfAerator1Units'];
    final n2Result = results['numberOfAerator2Units'];
    final n1 = (n1Result is num) ? n1Result.toInt() : 0;
    final n2 = (n2Result is num) ? n2Result.toInt() : 0;

    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = (price1 / durability1) * n1;
    final capitalCost2 = (price2 / durability2) * n2;
    final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
    final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.costBreakdownTableTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2)},
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(l10n.costComponentLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(l10n.aerator1,
                        style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(l10n.aerator2,
                        style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            _buildCostTableRow('energyCostLabel', energyCostTotal1, energyCostTotal2, l10n),
            _buildCostTableRow('maintenanceCostLabel', maintenanceCost1, maintenanceCost2, l10n),
            _buildCostTableRow('capitalCostLabel', capitalCost1, capitalCost2, l10n),
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(l10n.totalAnnualCostLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_formatValueWithThousandSeparator('totalAnnualCostLabel', totalCost1, l10n),
                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_formatValueWithThousandSeparator('totalAnnualCostLabel', totalCost2, l10n),
                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  TableRow _buildCostTableRow(String labelKey, double value1, double value2, AppLocalizations l10n) {
    final color1 =
        value1.isNaN || value2.isNaN || (value1 - value2).abs() < 1e-6 ? Colors.black : (value1 < value2 ? Colors.green : Colors.red);
    final color2 =
        value1.isNaN || value2.isNaN || (value1 - value2).abs() < 1e-6 ? Colors.black : (value2 < value1 ? Colors.green : Colors.red);
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(_getL10nString(l10n, labelKey))),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_formatValueWithThousandSeparator(labelKey, value1, l10n),
                textAlign: TextAlign.right, style: TextStyle(color: color1))),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_formatValueWithThousandSeparator(labelKey, value2, l10n),
                textAlign: TextAlign.right, style: TextStyle(color: color2))),
      ],
    );
  }

  Widget _buildCostBreakdownPieChart(Map<String, dynamic> results, Map<String, dynamic> inputs, AppLocalizations l10n) {
    final energyCost1Value = inputs['annualEnergyCostAerator1'];
    final energyCost2Value = inputs['annualEnergyCostAerator2'];
    final maintenance1Value = inputs['maintenanceCostAerator1'];
    final maintenance2Value = inputs['maintenanceCostAerator2'];
    final price1Value = inputs['priceAerator1'];
    final price2Value = inputs['priceAerator2'];
    final durability1Value = inputs['durabilityAerator1'];
    final durability2Value = inputs['durabilityAerator2'];

    final energyCost1 = energyCost1Value is num ? energyCost1Value.toDouble() : 0.0;
    final energyCost2 = energyCost2Value is num ? energyCost2Value.toDouble() : 0.0;
    final maintenance1 = maintenance1Value is num ? maintenance1Value.toDouble() : 0.0;
    final maintenance2 = maintenance2Value is num ? maintenance2Value.toDouble() : 0.0;
    final price1 = price1Value is num ? price1Value.toDouble() : 0.0;
    final price2 = price2Value is num ? price2Value.toDouble() : 0.0;
    final durability1 = durability1Value is num && durability1Value > 0 ? durability1Value.toDouble() : 1.0;
    final durability2 = durability2Value is num && durability2Value > 0 ? durability2Value.toDouble() : 1.0;

    final n1Result = results['numberOfAerator1Units'];
    final n2Result = results['numberOfAerator2Units'];
    final n1 = (n1Result is num) ? n1Result.toInt() : 0;
    final n2 = (n2Result is num) ? n2Result.toInt() : 0;

    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = (price1 / durability1) * n1;
    final capitalCost2 = (price2 / durability2) * n2;

    final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
    final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;

    final metrics1 = [
      if (energyCostTotal1 > 0) {
        'title': l10n.energyCostLabel,
        'value': energyCostTotal1,
        'color': Colors.blue.shade700
      },
      if (maintenanceCost1 > 0) {
        'title': l10n.maintenanceCostLabel,
        'value': maintenanceCost1,
        'color': Colors.green.shade700
      },
      if (capitalCost1 > 0) {
        'title': l10n.capitalCostLabel,
        'value': capitalCost1,
        'color': Colors.orange.shade700
      },
    ];

    final metrics2 = [
      if (energyCostTotal2 > 0) {
        'title': l10n.energyCostLabel,
        'value': energyCostTotal2,
        'color': Colors.blue.shade700
      },
      if (maintenanceCost2 > 0) {
        'title': l10n.maintenanceCostLabel,
        'value': maintenanceCost2,
        'color': Colors.green.shade700
      },
      if (capitalCost2 > 0) {
        'title': l10n.capitalCostLabel,
        'value': capitalCost2,
        'color': Colors.orange.shade700
      },
    ];

    if (metrics1.isEmpty && metrics2.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.costBreakdownChartTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metrics1.isNotEmpty && totalCost1 > 0)
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.aerator1, style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: metrics1.asMap().entries.map((entry) {
                            final metric = entry.value;
                            final percentage = (metric['value'] as double) / totalCost1 * 100;
                            return PieChartSectionData(
                              color: metric['color'] as Color,
                              value: metric['value'] as double,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              showTitle: percentage > 5,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 0),
                      ),
                    ),
                  ],
                ),
              ),
            if (metrics2.isNotEmpty && totalCost2 > 0)
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.aerator2, style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: metrics2.asMap().entries.map((entry) {
                            final metric = entry.value;
                            final percentage = (metric['value'] as double) / totalCost2 * 100;
                            return PieChartSectionData(
                              color: metric['color'] as Color,
                              value: metric['value'] as double,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              showTitle: percentage > 5,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 0),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            {'title': l10n.energyCostLabel, 'color': Colors.blue.shade700},
            {'title': l10n.maintenanceCostLabel, 'color': Colors.green.shade700},
            {'title': l10n.capitalCostLabel, 'color': Colors.orange.shade700},
          ].map((metric) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: metric['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(metric['title'] as String, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  String _formatValue(dynamic value, AppLocalizations l10n) {
    if (value is double) {
      if (value.isNaN) return "NaN";
      if (value.isInfinite) return "Infinite";
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    }
    if (value is String) {
      if (value == 'inf' || value == 'Infinite') return '∞';
      if (value == '-inf') return '-∞';
      if (value == 'nan' || value == 'NaN') return 'NaN';
      if (value == 'Never') return l10n.paybackNever;
    }
    return value.toString();
  }

  String _formatValueWithThousandSeparator(String key, dynamic value, AppLocalizations l10n) {
    // Define monetary keys that should be formatted with a currency symbol
    const monetaryKeys = [
      'totalAnnualCostAerator1Label',
      'totalAnnualCostAerator2Label',
      'annualEnergyCostAerator1',
      'annualEnergyCostAerator2',
      'maintenanceCostAerator1',
      'maintenanceCostAerator2',
      'priceAerator1',
      'priceAerator2',
      'costOfOpportunity',
      'realPriceLosingAerator',
      'netPresentValue',
      'Annual Energy Cost (USD/year)',
      'Cost per kg O₂ (USD/kg O₂)',
      'energyCostLabel',
      'maintenanceCostLabel',
      'capitalCostLabel',
      'totalAnnualCostLabel',
      'annualRevenue',
      'netProfitAerator1',
      'netProfitAerator2',
    ];

    if (value is double) {
      if (value.isNaN) return "NaN";
      if (value.isInfinite) return "∞";
      if (monetaryKeys.contains(key)) {
        // Use currency format for monetary values
        if (value.abs() >= 1e6) {
          return NumberFormat.compactCurrency(symbol: '\$').format(value);
        }
        return NumberFormat.currency(symbol: '\$').format(value);
      } else {
        // Use decimal format for non-monetary values
        if (value.abs() >= 1e6) {
          return NumberFormat.compact().format(value);
        }
        return NumberFormat.decimalPattern('en_US').format(value);
      }
    } else if (value is int) {
      if (value.abs() >= 1e6) {
        return NumberFormat.compact().format(value);
      }
      return NumberFormat('#,##0').format(value);
    }
    if (value is String) {
      if (value == 'inf' || value == 'Infinite') return '∞';
      if (value == '-inf') return '-∞';
      if (value == 'nan' || value == 'NaN') return 'NaN';
      if (value == 'Never') return l10n.paybackNever;
      return value;
    }
    return value.toString();
  }

  void _downloadAsCsv(BuildContext context, Map<String, dynamic> inputs, Map<String, dynamic> results) {
    final l10n = AppLocalizations.of(context)!;
    final csvRows = <String>[];

    csvRows.add('"Inputs"');
    csvRows.add('"Category","Value"');
    inputs.forEach((key, value) {
      final displayKey = _getL10nString(l10n, key, defaultValue: key);
      final escapedKey = displayKey.replaceAll('"', '""');
      final escapedValue = _formatValue(value, l10n).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    csvRows.add('');
    csvRows.add('"Results"');
    csvRows.add('"Category","Value"');
    results.forEach((key, value) {
      final displayKey = _getL10nString(l10n, key, defaultValue: key);
      String displayValueStr = _formatValue(value, l10n);
      if (key == 'realPriceLosingAerator') {
        final loserName = results['loserLabel'] ?? '?';
        final loserDisplay =
            loserName == 'Aerator 1' ? l10n.aerator1 : (loserName == 'Aerator 2' ? l10n.aerator2 : loserName);
        displayValueStr += ' ($loserDisplay)';
      } else if (key == 'loserLabel') {
        displayValueStr =
            value == 'Aerator 1' ? l10n.aerator1 : (value == 'Aerator 2' ? l10n.aerator2 : value.toString());
      }

      final escapedKey = displayKey.replaceAll('"', '""');
      final escapedValue = displayValueStr.replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    if (widget.tab == 'Aerator Comparison') {
      csvRows.add('');
      csvRows.add('"Cost Breakdown (Annual, USD)"');
      csvRows.add('"Category","${l10n.aerator1}","${l10n.aerator2}"');

      final energyCost1Value = inputs['annualEnergyCostAerator1'];
      final energyCost2Value = inputs['annualEnergyCostAerator2'];
      final maintenance1Value = inputs['maintenanceCostAerator1'];
      final maintenance2Value = inputs['maintenanceCostAerator2'];
      final price1Value = inputs['priceAerator1'];
      final price2Value = inputs['priceAerator2'];
      final durability1Value = inputs['durabilityAerator1'];
      final durability2Value = inputs['durabilityAerator2'];

      final energyCost1 = energyCost1Value is num ? energyCost1Value.toDouble() : 0.0;
      final energyCost2 = energyCost2Value is num ? energyCost2Value.toDouble() : 0.0;
      final maintenance1 = maintenance1Value is num ? maintenance1Value.toDouble() : 0.0;
      final maintenance2 = maintenance2Value is num ? maintenance2Value.toDouble() : 0.0;
      final price1 = price1Value is num ? price1Value.toDouble() : 0.0;
      final price2 = price2Value is num ? price2Value.toDouble() : 0.0;
      final durability1 = durability1Value is num && durability1Value > 0 ? durability1Value.toDouble() : 1.0;
      final durability2 = durability2Value is num && durability2Value > 0 ? durability2Value.toDouble() : 1.0;

      final n1Result = results['numberOfAerator1Units'];
      final n2Result = results['numberOfAerator2Units'];
      final n1 = (n1Result is num) ? n1Result.toInt() : 0;
      final n2 = (n2Result is num) ? n2Result.toInt() : 0;

      final energyCostTotal1 = energyCost1 * n1;
      final energyCostTotal2 = energyCost2 * n2;
      final maintenanceCost1 = maintenance1 * n1;
      final maintenanceCost2 = maintenance2 * n2;
      final capitalCost1 = (price1 / durability1) * n1;
      final capitalCost2 = (price2 / durability2) * n2;
      final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
      final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;

      csvRows.add(
          '"${l10n.energyCostLabel}","${_formatValue(energyCostTotal1, l10n)}","${_formatValue(energyCostTotal2, l10n)}"');
      csvRows.add(
          '"${l10n.maintenanceCostLabel}","${_formatValue(maintenanceCost1, l10n)}","${_formatValue(maintenanceCost2, l10n)}"');
      csvRows.add(
          '"${l10n.capitalCostLabel}","${_formatValue(capitalCost1, l10n)}","${_formatValue(capitalCost2, l10n)}"');
      csvRows.add(
          '"${l10n.totalAnnualCostLabel}","${_formatValue(totalCost1, l10n)}","${_formatValue(totalCost2, l10n)}"');
    }

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'aerasync_data_${widget.tab.replaceAll(' ', '_')}_$timestamp.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:AeraSync/generated/l10n.dart';
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
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Recommendation message for Aerator Comparison
        String? recommendationMessage;
        if (widget.tab == 'Aerator Comparison') {
          final totalCost1 = results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0;
          final totalCost2 = results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0;
          final costOfOpportunity = results['Cost of Opportunity (USD)'] as double? ?? 0.0;
          if (totalCost1 > totalCost2) {
            recommendationMessage = l10n.recommendationChooseAerator2(costOfOpportunity);
          } else if (totalCost2 > totalCost1) {
            recommendationMessage = l10n.recommendationChooseAerator1(costOfOpportunity);
          } else {
            recommendationMessage = l10n.recommendationEqualCosts;
          }
        }

        // Group results into sections for Aerator Comparison
        final Map<String, Map<String, dynamic>> groupedResults = {
          'Oxygen Demand': <String, dynamic>{},
          'Aerator Metrics': <String, dynamic>{},
          'Financial Metrics': <String, dynamic>{},
        };

        if (widget.tab == 'Aerator Comparison') {
          results.forEach((key, value) {
            if (key.contains('Demand') || key == AppLocalizations.of(context)!.totalOxygenDemandLabel) {
              groupedResults['Oxygen Demand']![key] = value;
            } else if (key.contains('OTR_T') ||
                key == AppLocalizations.of(context)!.numberOfAerator1UnitsLabel ||
                key == AppLocalizations.of(context)!.numberOfAerator2UnitsLabel) {
              groupedResults['Aerator Metrics']![key] = value;
            } else {
              groupedResults['Financial Metrics']![key] = value;
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
                          onPressed: () {
                            setState(() {
                              _showBarChart = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showBarChart ? const Color(0xFF1E40AF) : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Bar Chart'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showBarChart = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showBarChart ? const Color(0xFF1E40AF) : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pie Chart'),
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
                          child: child,
                        );
                      },
                      child: _showBarChart
                          ? _buildAeratorComparisonBarChart(results, l10n, key: const Key('barChart'))
                          : _buildAeratorComparisonPieChart(results, l10n, key: const Key('pieChart')),
                    ),
                    const SizedBox(height: 16),
                    // Oxygen Demand Breakdown Pie Chart
                    _buildOxygenDemandPieChart(results, l10n),
                    const SizedBox(height: 16),
                    // Cost Breakdown Table for Aerator Comparison
                    _buildCostBreakdownTable(results, inputs!, l10n),
                    const SizedBox(height: 16),
                    // Cost Breakdown Pie Chart
                    _buildCostBreakdownPieChart(results, inputs!, l10n),
                    const SizedBox(height: 16),
                  ],
                  // Recommendation Message for Aerator Comparison
                  if (recommendationMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        recommendationMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
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
                          ...group.value.entries.map((entry) {
                            final isKeyMetric = entry.key == 'Coefficient of Profitability (k)' ||
                                entry.key == 'Cost of Opportunity (USD)' ||
                                entry.key.contains('Real Price of Losing Aerator');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatValueWithThousandSeparator(entry.value),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                        if (isKeyMetric) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Color(0xFF1E40AF)),
                                            onPressed: () {
                                              FlutterClipboard.copy(_formatValue(entry.value)).then((value) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.valueCopied(value: entry.key),
                                                    ),
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
                          }),
                        ],
                      );
                    }),
                  ] else ...[
                    // Default results list for other tabs
                    ...results.entries.map((entry) {
                      final isKeyMetric = (widget.tab == 'Aerator Performance' &&
                              entry.key == 'SOTR (kg O₂/h)') ||
                          (widget.tab == 'Aerator Estimation' &&
                              entry.key == l10n.numberOfAeratorsPerHectareLabel) ||
                          (widget.tab == 'Aerator Comparison' &&
                              (entry.key == 'Coefficient of Profitability (k)' ||
                                  entry.key == 'Cost of Opportunity (USD)' ||
                                  entry.key.contains('Real Price of Losing Aerator')));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatValueWithThousandSeparator(entry.value),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  if (isKeyMetric) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Color(0xFF1E40AF)),
                                      onPressed: () {
                                        FlutterClipboard.copy(_formatValue(entry.value)).then((value) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.valueCopied(value: entry.key),
                                              ),
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
                    }),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadAsCsv(inputs!, results),
                      icon: const Icon(Icons.download, size: 32),
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

  Widget _buildAeratorEstimationChart(Map<String, dynamic> results, AppLocalizations l10n) {
    final metrics = [
      {'title': l10n.todLabelShort, 'value': results[l10n.todLabel] as double? ?? 0.0},
      {'title': l10n.otrTLabelShort, 'value': results[l10n.otrTLabel] as double? ?? 0.0},
      {'title': l10n.aeratorsLabelShort, 'value': results[l10n.numberOfAeratorsPerHectareLabel] as double? ?? 0.0},
    ];

    final maxY = metrics.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2;

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
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  metrics[value.toInt()]['title'] as String,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
          ),
          barTouchData: BarTouchData(enabled: false), // Disable interactions to improve performance
        ),
        swapAnimationDuration: const Duration(milliseconds: 0), // Disable animations
      ),
    );
  }

  Widget _buildAeratorComparisonBarChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
      },
      {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
      },
      {
        'title': l10n.costOfOpportunityLabelShort,
        'value': results['Cost of Opportunity (USD)'] as double? ?? 0.0,
        'tooltip': l10n.costOfOpportunityTooltip,
      },
    ];

    final maxY = metrics.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      key: key,
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
              showingTooltipIndicators: [0], // Show tooltip for each bar
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  NumberFormat.compact().format(value), // Compact format for large numbers
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  metrics[value.toInt()]['title'] as String,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey.withOpacity(0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatValueWithThousandSeparator(rod.toY),
                  const TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: '\n${metrics[groupIndex]['tooltip']}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0), // Disable animations
      ),
    );
  }

  Widget _buildAeratorComparisonPieChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
        'color': Colors.blue,
      },
      {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
        'color': Colors.green,
      },
      {
        'title': l10n.costOfOpportunityLabelShort,
        'value': results['Cost of Opportunity (USD)'] as double? ?? 0.0,
        'tooltip': l10n.costOfOpportunityTooltip,
        'color': Colors.orange,
      },
    ];

    final totalValue = metrics.map((e) => e['value'] as double).reduce((a, b) => a + b);

    return SizedBox(
      key: key,
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: metrics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final metric = entry.value;
                  return PieChartSectionData(
                    color: metric['color'] as Color,
                    value: metric['value'] as double,
                    title: metric['title'] as String,
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    showTitle: totalValue > 0,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch events if needed
                  },
                  longPressDuration: const Duration(milliseconds: 500),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: metrics.map((metric) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: metric['color'] as Color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metric['title'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOxygenDemandPieChart(Map<String, dynamic> results, AppLocalizations l10n) {
    final metrics = [
      {
        'title': 'Shrimp Demand',
        'value': results['Shrimp Demand (kg O₂/h for 1000 ha)'] as double? ?? 0.0,
        'color': Colors.blue,
      },
      {
        'title': 'Water Demand',
        'value': (results['Water Demand (kg O₂/h/ha)'] as double? ?? 0.0) * 1000, // Convert to total for 1000 ha
        'color': Colors.green,
      },
      {
        'title': 'Bottom Demand',
        'value': (results['Bottom Demand (kg O₂/h/ha)'] as double? ?? 0.0) * 1000, // Convert to total for 1000 ha
        'color': Colors.orange,
      },
    ];

    final totalValue = metrics.map((e) => e['value'] as double).reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Oxygen Demand Breakdown",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
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
                      return PieChartSectionData(
                        color: metric['color'] as Color,
                        value: metric['value'] as double,
                        title: metric['title'] as String,
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                        showTitle: totalValue > 0,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Handle touch events if needed
                      },
                      longPressDuration: const Duration(milliseconds: 500),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 0),
                ),
              ),
              const SizedBox(height: 8),
              // Legend
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: metrics.map((metric) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: metric['color'] as Color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metric['title'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
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
    // Extract input values with correct energy costs
    final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
    final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
    final maintenance1 = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
    final maintenance2 = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
    final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
    final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
    final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
    final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
    final n1 = results[l10n.numberOfAerator1UnitsLabel] as int? ?? 0;
    final n2 = results[l10n.numberOfAerator2UnitsLabel] as int? ?? 0;

    // Calculate cost components
    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = (price1 / durability1) * n1;
    final capitalCost2 = (price2 / durability2) * n2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.costBreakdownTableTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.costComponentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.aerator1, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.aerator2, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.energyCostLabel),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(energyCostTotal1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: energyCostTotal1 <= energyCostTotal2 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(energyCostTotal2),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: energyCostTotal2 <= energyCostTotal1 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.maintenanceCostLabel),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(maintenanceCost1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: maintenanceCost1 <= maintenanceCost2 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(maintenanceCost2),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: maintenanceCost2 <= maintenanceCost1 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.capitalCostLabel),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(capitalCost1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: capitalCost1 <= capitalCost2 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatValueWithThousandSeparator(capitalCost2),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: capitalCost2 <= capitalCost1 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostBreakdownPieChart(Map<String, dynamic> results, Map<String, dynamic> inputs, AppLocalizations l10n) {
    final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
    final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
    final maintenance1 = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
    final maintenance2 = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
    final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
    final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
    final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
    final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
    final n1 = results[l10n.numberOfAerator1UnitsLabel] as int? ?? 0;
    final n2 = results[l10n.numberOfAerator2UnitsLabel] as int? ?? 0;

    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = (price1 / durability1) * n1;
    final capitalCost2 = (price2 / durability2) * n2;

    final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
    final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;

    final metrics1 = [
      {'title': l10n.energyCostLabel, 'value': energyCostTotal1, 'color': Colors.blue},
      {'title': l10n.maintenanceCostLabel, 'value': maintenanceCost1, 'color': Colors.green},
      {'title': l10n.capitalCostLabel, 'value': capitalCost1, 'color': Colors.orange},
    ];

    final metrics2 = [
      {'title': l10n.energyCostLabel, 'value': energyCostTotal2, 'color': Colors.blue},
      {'title': l10n.maintenanceCostLabel, 'value': maintenanceCost2, 'color': Colors.green},
      {'title': l10n.capitalCostLabel, 'value': capitalCost2, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Cost Breakdown Visualization",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pie Chart for Aerator 1
            Column(
              children: [
                Text(l10n.aerator1, style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sections: metrics1.asMap().entries.map((entry) {
                        final metric = entry.value;
                        return PieChartSectionData(
                          color: metric['color'] as Color,
                          value: metric['value'] as double,
                          title: metric['title'] as String,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          showTitle: totalCost1 > 0,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch events if needed
                        },
                        longPressDuration: const Duration(milliseconds: 500),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 0),
                  ),
                ),
              ],
            ),
            // Pie Chart for Aerator 2
            Column(
              children: [
                Text(l10n.aerator2, style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sections: metrics2.asMap().entries.map((entry) {
                        final metric = entry.value;
                        return PieChartSectionData(
                          color: metric['color'] as Color,
                          value: metric['value'] as double,
                          title: metric['title'] as String,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          showTitle: totalCost2 > 0,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch events if needed
                        },
                        longPressDuration: const Duration(milliseconds: 500),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend for Cost Breakdown Pie Charts
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: metrics1.map((metric) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: metric['color'] as Color,
                ),
                const SizedBox(width: 4),
                Text(
                  metric['title'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatValueWithThousandSeparator(dynamic value) {
    if (value is double) {
      if (value >= 1000000) {
        return NumberFormat.compact().format(value);
      }
      return NumberFormat('#,##0.00').format(value);
    } else if (value is int) {
      if (value >= 1000000) {
        return NumberFormat.compact().format(value);
      }
      return NumberFormat('#,##0').format(value);
    }
    return value.toString();
  }

  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results) {
    final csvRows = <String>[];

    // Inputs Section
    csvRows.add('"Inputs"');
    csvRows.add('"Category","Value"');
    inputs.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    // Results Section
    csvRows.add('');
    csvRows.add('"Results"');
    csvRows.add('"Category","Value"');
    results.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    // Cost Breakdown Section
    csvRows.add('');
    csvRows.add('"Cost Breakdown"');
    csvRows.add('"Category","Value"');
    final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
    final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
    final maintenance1 = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
    final maintenance2 = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
    final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
    final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
    final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
    final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
    final n1 = results[l10n.numberOfAerator1UnitsLabel] as int? ?? 0;
    final n2 = results[l10n.numberOfAerator2UnitsLabel] as int? ?? 0;

    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = (price1 / durability1) * n1;
    final capitalCost2 = (price2 / durability2) * n2;

    csvRows.add('"${l10n.aerator1} - ${l10n.energyCostLabel}","${_formatValue(energyCostTotal1)}"');
    csvRows.add('"${l10n.aerator1} - ${l10n.maintenanceCostLabel}","${_formatValue(maintenanceCost1)}"');
    csvRows.add('"${l10n.aerator1} - ${l10n.capitalCostLabel}","${_formatValue(capitalCost1)}"');
    csvRows.add('"${l10n.aerator2} - ${l10n.energyCostLabel}","${_formatValue(energyCostTotal2)}"');
    csvRows.add('"${l10n.aerator2} - ${l10n.maintenanceCostLabel}","${_formatValue(maintenanceCost2)}"');
    csvRows.add('"${l10n.aerator2} - ${l10n.capitalCostLabel}","${_formatValue(capitalCost2)}"');

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_data_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
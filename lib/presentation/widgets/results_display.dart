import 'dart:math'; // Import for max function used in charts

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

  @override
  Widget build(BuildContext context) {
    // Get l10n object from context
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
              style: const TextStyle(color: Colors.black54, fontSize: 16), // Adjusted color
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
          // Format costOfOpportunity for the message
          final formattedAmount = _formatValueWithThousandSeparator(costOfOpportunity.abs());
          if (totalCost1 > totalCost2) {
            recommendationMessage = l10n.recommendationChooseAerator2(formattedAmount);
          } else if (totalCost2 > totalCost1) {
            recommendationMessage = l10n.recommendationChooseAerator1(formattedAmount);
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
            // Check if key exists in l10n before using it for comparison
            // This assumes l10n keys match the keys in the results map
            if (key == l10n.totalOxygenDemandLabel || key.contains('Demand')) {
               groupedResults['Oxygen Demand']![key] = value;
            } else if (key.contains('OTR_T') ||
                key == l10n.numberOfAerator1UnitsLabel ||
                key == l10n.numberOfAerator2UnitsLabel) {
              groupedResults['Aerator Metrics']![key] = value;
            } else {
              // Put everything else in Financial Metrics
              groupedResults['Financial Metrics']![key] = value;
            }
          });
           // Ensure specific keys are in Financial Metrics if they exist
           const financialKeys = [
             'Coefficient of Profitability (k)', 'VPN (USD)', 'Payback (days)',
             'ROI (%)', 'TIR (%)', 'Cost of Opportunity (USD)',
             'Real Price of Losing Aerator (USD) (Aerator 1)', // Handle dynamic label if needed
             'Real Price of Losing Aerator (USD) (Aerator 2)',
             'Number of Units of Losing Aerator',
           ];
           results.forEach((key, value) {
             if (financialKeys.any((fk) => key.startsWith(fk.split('(')[0]))) { // Basic check for dynamic labels
               groupedResults['Financial Metrics']![key] = value;
               // Remove from other groups if accidentally added
               groupedResults['Oxygen Demand']!.remove(key);
               groupedResults['Aerator Metrics']!.remove(key);
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
                          child: const Text('Bar Chart'), // Consider localizing
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
                          child: const Text('Pie Chart'), // Consider localizing
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
                          child: SizeTransition( // Add SizeTransition for smoother height change
                             sizeFactor: animation,
                             axisAlignment: -1.0, // Align top
                             child: child
                          ),
                        );
                      },
                      child: _showBarChart
                          ? _buildAeratorComparisonBarChart(results, l10n, key: const ValueKey('barChart')) // Use ValueKey
                          : _buildAeratorComparisonPieChart(results, l10n, key: const ValueKey('pieChart')), // Use ValueKey
                    ),
                    const SizedBox(height: 16),
                    // Oxygen Demand Breakdown Pie Chart (only if data exists)
                    if (groupedResults['Oxygen Demand']!.isNotEmpty && groupedResults['Oxygen Demand']!.values.any((v) => v is double && v > 0)) ...[
                       _buildOxygenDemandPieChart(groupedResults['Oxygen Demand']!, l10n),
                       const SizedBox(height: 16),
                    ],
                    // Cost Breakdown Table for Aerator Comparison (only if data exists)
                    if (inputs != null && results.containsKey(l10n.totalAnnualCostAerator1Label)) ...[
                        _buildCostBreakdownTable(results, inputs, l10n),
                        const SizedBox(height: 16),
                        // Cost Breakdown Pie Chart
                        _buildCostBreakdownPieChart(results, inputs, l10n),
                        const SizedBox(height: 16),
                    ]
                  ],
                  // Recommendation Message for Aerator Comparison
                  if (recommendationMessage != null) ...[
                    Container( // Added container for styling
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        recommendationMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green, // Darker green might be better
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
                              group.key, // Consider localizing group keys if needed
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          ListView.separated( // Use ListView for consistency
                             shrinkWrap: true,
                             physics: const NeverScrollableScrollPhysics(),
                             itemCount: group.value.length,
                             itemBuilder: (context, index) {
                               final entry = group.value.entries.elementAt(index);
                               final isKeyMetric = entry.key == 'Coefficient of Profitability (k)' ||
                                    entry.key == 'Cost of Opportunity (USD)' ||
                                    entry.key.contains('Real Price of Losing Aerator');
                               return Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 4.0),
                                 child: Row(
                                   children: [
                                     Expanded(
                                       flex: 3,
                                       child: Text(
                                         entry.key,
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
                                               _formatValueWithThousandSeparator(entry.value),
                                               textAlign: TextAlign.end,
                                               style: const TextStyle(
                                                 fontWeight: FontWeight.bold,
                                                 color: Color(0xFF1E40AF),
                                               ),
                                                overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           if (isKeyMetric) ...[
                                             const SizedBox(width: 4),
                                             IconButton(
                                               icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)),
                                               padding: EdgeInsets.zero,
                                               constraints: const BoxConstraints(),
                                               onPressed: () {
                                                 FlutterClipboard.copy(_formatValue(entry.value)).then((_) {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     SnackBar(
                                                       // FIX: Pass the required 'value' argument
                                                       content: Text(l10n.valueCopied(value: entry.key)),
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
                          const SizedBox(height: 10), // Space after group
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
                         final isKeyMetric = (widget.tab == 'Aerator Performance' &&
                                 entry.key == 'SOTR (kg O₂/h)') ||
                             (widget.tab == 'Aerator Estimation' &&
                                 entry.key == l10n.numberOfAeratorsPerHectareLabel);
                          // Note: Key metrics for 'Aerator Comparison' handled above

                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4.0),
                           child: Row(
                             children: [
                               Expanded(
                                 flex: 3,
                                 child: Text(
                                   entry.key,
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
                                         _formatValueWithThousandSeparator(entry.value),
                                         textAlign: TextAlign.end,
                                         style: const TextStyle(
                                           fontWeight: FontWeight.bold,
                                           color: Color(0xFF1E40AF),
                                         ),
                                          overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                     if (isKeyMetric) ...[
                                       const SizedBox(width: 4),
                                       IconButton(
                                         icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                         onPressed: () {
                                           FlutterClipboard.copy(_formatValue(entry.value)).then((_) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 // FIX: Pass the required 'value' argument
                                                 content: Text(l10n.valueCopied(value: entry.key)),
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
                        // FIX: Pass context to _downloadAsCsv
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
    // Safely access results
    final tod = results[l10n.todLabel] as double? ?? 0.0;
    final otrT = results[l10n.otrTLabel] as double? ?? 0.0;
    final aerators = results[l10n.numberOfAeratorsPerHectareLabel] as double? ?? 0.0;

    final metrics = [
      if (tod >= 0) {'title': l10n.todLabelShort, 'value': tod},
      if (otrT >= 0) {'title': l10n.otrTLabelShort, 'value': otrT},
      if (aerators >= 0) {'title': l10n.aeratorsLabelShort, 'value': aerators},
    ];

     if (metrics.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No data for chart")));
    }

    final maxYValue = metrics.map((e) => e['value'] as double).reduce(max);
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0;

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
                   return Text(
                     value.toStringAsFixed(1), // Format left axis titles
                     style: const TextStyle(color: Colors.black54, fontSize: 12),
                   );
                }
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                     return Text(
                       metrics[value.toInt()]['title'] as String,
                       style: const TextStyle(color: Colors.black54, fontSize: 12),
                     );
                   }
                   return const SizedBox.shrink();
                }
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
             horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1,
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
    );
  }

  Widget _buildAeratorComparisonBarChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
     // Safely access results
    final cost1 = results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0;
    final cost2 = results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0;
    final opportunityCost = results['Cost of Opportunity (USD)'] as double? ?? 0.0;

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
      if (opportunityCost >= 0) { // Only show if positive
        'title': l10n.costOfOpportunityLabelShort,
        'value': opportunityCost,
        'tooltip': l10n.costOfOpportunityTooltip,
      },
    ];

     if (metrics.isEmpty) {
      return SizedBox(key: key, height: 200, child: const Center(child: Text("No data for chart")));
    }

    final maxYValue = metrics.map((e) => e['value'] as double).reduce(max);
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0;


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
              // showingTooltipIndicators: [0], // Consider removing if getTooltipItem is used
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50, // Increased reserved size for compact format
                getTitlesWidget: (value, meta) {
                   if (maxY == 1.0 && value == 0) return const SizedBox.shrink();
                   return Text(
                     NumberFormat.compact().format(value), // Compact format for large numbers
                     style: const TextStyle(color: Colors.black54, fontSize: 12),
                   );
                }
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                     return Text(
                       metrics[value.toInt()]['title'] as String,
                       style: const TextStyle(color: Colors.black54, fontSize: 12),
                     );
                   }
                   return const SizedBox.shrink();
                }
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
             horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1,
          ),
          barTouchData: BarTouchData( // Enable touch for tooltips
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              // FIX: Use getTooltipItem instead of tooltipBgColor
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 if (groupIndex < 0 || groupIndex >= metrics.length) {
                   return null; // Avoid index out of bounds
                 }
                 final metric = metrics[groupIndex];
                 String text = '${metric['title']}\n'
                               '${_formatValueWithThousandSeparator(rod.toY)}';
                 // Optionally add the full tooltip text from the metric map
                 // if (metric['tooltip'] != null) {
                 //   text += '\n${metric['tooltip']}';
                 // }

                 return BarTooltipItem(
                   text,
                   const TextStyle(color: Colors.white, fontSize: 12),
                    tooltipPadding: const EdgeInsets.all(8), // Add padding
                    tooltipBorder: BorderSide(color: Colors.grey[700]!), // Add border
                    // Set background color here
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                 );
              },
            ),
             handleBuiltInTouches: true, // Use built-in touch handling
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
    );
  }

  Widget _buildAeratorComparisonPieChart(Map<String, dynamic> results, AppLocalizations l10n, {Key? key}) {
    // Safely access results
    final cost1 = results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0;
    final cost2 = results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0;
    final opportunityCost = results['Cost of Opportunity (USD)'] as double? ?? 0.0;

    final metrics = [
      if (cost1 > 0) { // Only include positive values in pie chart
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': cost1,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
        'color': Colors.blue.shade700, // Use shades for better distinction
      },
      if (cost2 > 0) {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': cost2,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
        'color': Colors.green.shade700,
      },
      // Opportunity cost might not make sense in a pie chart showing total costs
      // Consider showing only cost1 and cost2 here.
      // if (opportunityCost > 0) {
      //   'title': l10n.costOfOpportunityLabelShort,
      //   'value': opportunityCost,
      //   'tooltip': l10n.costOfOpportunityTooltip,
      //   'color': Colors.orange.shade700,
      // },
    ];

    if (metrics.isEmpty) {
       return SizedBox(key: key, height: 200, child: const Center(child: Text("No data for chart")));
    }

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
                  // final index = entry.key; // Not needed here
                  final metric = entry.value;
                  final percentage = totalValue > 0 ? (metric['value'] as double) / totalValue * 100 : 0;
                  return PieChartSectionData(
                    color: metric['color'] as Color,
                    value: metric['value'] as double,
                    // Show percentage in title
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60, // Slightly larger radius
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    showTitle: totalValue > 0 && percentage > 5, // Show title only if percentage is significant
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData( // Add touch data for tooltips
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Optional: Handle touch events for interactivity
                  },
                  longPressDuration: const Duration(milliseconds: 500), // Optional
                   tooltipData: PieTouchTooltipData( // Define tooltip appearance
                     tooltipBgColor: Colors.black87,
                     getTooltipItems: (touchedSpots) {
                       return touchedSpots.map((touchedSpot) {
                         if (touchedSpot.touchedSectionIndex < 0 || touchedSpot.touchedSectionIndex >= metrics.length) {
                            return null;
                         }
                         final metric = metrics[touchedSpot.touchedSectionIndex];
                         return PieTooltipItem(
                           '${metric['title']}: ${_formatValueWithThousandSeparator(metric['value'])}',
                           const TextStyle(color: Colors.white),
                         );
                       }).whereType<PieTooltipItem>().toList(); // Filter out nulls
                     },
                   ),
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
            alignment: WrapAlignment.center, // Center legend items
            children: metrics.map((metric) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: metric['color'] as Color,
                      shape: BoxShape.circle, // Use circles for legend
                    ),
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


  Widget _buildOxygenDemandPieChart(Map<String, dynamic> oxygenDemandResults, AppLocalizations l10n) {
    // Safely access results, assuming keys might not always be present
    final shrimpDemand = oxygenDemandResults['Shrimp Demand (kg O₂/h for 1000 ha)'] as double? ?? 0.0;
    final waterDemand = (oxygenDemandResults['Water Demand (kg O₂/h/ha)'] as double? ?? 0.0) * 1000; // Convert to total
    final bottomDemand = (oxygenDemandResults['Bottom Demand (kg O₂/h/ha)'] as double? ?? 0.0) * 1000; // Convert to total

    final metrics = [
      if (shrimpDemand > 0) {'title': 'Shrimp', 'value': shrimpDemand, 'color': Colors.blue.shade700},
      if (waterDemand > 0) {'title': 'Water', 'value': waterDemand, 'color': Colors.green.shade700},
      if (bottomDemand > 0) {'title': 'Bottom', 'value': bottomDemand, 'color': Colors.orange.shade700},
    ];

     if (metrics.isEmpty) {
       return const SizedBox.shrink(); // Don't show if no data
    }

    final totalValue = metrics.map((e) => e['value'] as double).reduce((a, b) => a + b);

     if (totalValue <= 0) {
       return const SizedBox.shrink(); // Don't show if total is zero
     }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Oxygen Demand Breakdown (kg O₂/h for 1000 ha)", // Clarify units
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200, // Consistent height
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
                       tooltipData: PieTouchTooltipData(
                         tooltipBgColor: Colors.black87,
                         getTooltipItems: (touchedSpots) {
                           return touchedSpots.map((touchedSpot) {
                             if (touchedSpot.touchedSectionIndex < 0 || touchedSpot.touchedSectionIndex >= metrics.length) return null;
                             final metric = metrics[touchedSpot.touchedSectionIndex];
                             return PieTooltipItem(
                               '${metric['title']}: ${_formatValueWithThousandSeparator(metric['value'])} kg/h',
                               const TextStyle(color: Colors.white),
                             );
                           }).whereType<PieTooltipItem>().toList();
                         },
                       ),
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
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
                alignment: WrapAlignment.center,
                children: metrics.map((metric) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                         decoration: BoxDecoration(
                           color: metric['color'] as Color,
                           shape: BoxShape.circle,
                         ),
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
    // Extract input values safely
    final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
    final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
    final maintenance1 = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
    final maintenance2 = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
    final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
    final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
    final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
    final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
    // Extract results safely
    final n1 = results[l10n.numberOfAerator1UnitsLabel] is int ? results[l10n.numberOfAerator1UnitsLabel] as int : (results[l10n.numberOfAerator1UnitsLabel] as double? ?? 0.0).toInt();
    final n2 = results[l10n.numberOfAerator2UnitsLabel] is int ? results[l10n.numberOfAerator2UnitsLabel] as int : (results[l10n.numberOfAerator2UnitsLabel] as double? ?? 0.0).toInt();


    // Calculate cost components, handle division by zero for durability
    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = durability1 > 0 ? (price1 / durability1) * n1 : 0.0;
    final capitalCost2 = durability2 > 0 ? (price2 / durability2) * n2 : 0.0;

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
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5), // Lighter border
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.2), // Adjust widths
            2: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]), // Lighter header
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.costComponentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.aerator1, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right), // Align right
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.aerator2, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right), // Align right
                ),
              ],
            ),
            _buildCostTableRow(l10n.energyCostLabel, energyCostTotal1, energyCostTotal2),
            _buildCostTableRow(l10n.maintenanceCostLabel, maintenanceCost1, maintenanceCost2),
            _buildCostTableRow(l10n.capitalCostLabel, capitalCost1, capitalCost2),
             // Add Total Row
             TableRow(
               decoration: BoxDecoration(color: Colors.grey[200]), // Highlight total
               children: [
                 const Padding(
                   padding: EdgeInsets.all(8.0),
                   child: Text("Total Annual Cost", style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Text(
                     _formatValueWithThousandSeparator(energyCostTotal1 + maintenanceCost1 + capitalCost1),
                     textAlign: TextAlign.right,
                     style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Text(
                     _formatValueWithThousandSeparator(energyCostTotal2 + maintenanceCost2 + capitalCost2),
                     textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
               ],
             ),
          ],
        ),
      ],
    );
  }

  // Helper for table rows
  TableRow _buildCostTableRow(String label, double value1, double value2) {
     final color1 = value1.isNaN || value2.isNaN || value1 == value2 ? Colors.black : (value1 < value2 ? Colors.green : Colors.red);
     final color2 = value1.isNaN || value2.isNaN || value1 == value2 ? Colors.black : (value2 < value1 ? Colors.green : Colors.red);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _formatValueWithThousandSeparator(value1),
            textAlign: TextAlign.right,
             style: TextStyle(color: color1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _formatValueWithThousandSeparator(value2),
            textAlign: TextAlign.right,
             style: TextStyle(color: color2),
          ),
        ),
      ],
    );
  }


  Widget _buildCostBreakdownPieChart(Map<String, dynamic> results, Map<String, dynamic> inputs, AppLocalizations l10n) {
     // Extract values safely
    final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
    final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
    final maintenance1 = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
    final maintenance2 = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
    final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
    final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
    final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
    final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
    final n1 = results[l10n.numberOfAerator1UnitsLabel] is int ? results[l10n.numberOfAerator1UnitsLabel] as int : (results[l10n.numberOfAerator1UnitsLabel] as double? ?? 0.0).toInt();
    final n2 = results[l10n.numberOfAerator2UnitsLabel] is int ? results[l10n.numberOfAerator2UnitsLabel] as int : (results[l10n.numberOfAerator2UnitsLabel] as double? ?? 0.0).toInt();


    final energyCostTotal1 = energyCost1 * n1;
    final energyCostTotal2 = energyCost2 * n2;
    final maintenanceCost1 = maintenance1 * n1;
    final maintenanceCost2 = maintenance2 * n2;
    final capitalCost1 = durability1 > 0 ? (price1 / durability1) * n1 : 0.0;
    final capitalCost2 = durability2 > 0 ? (price2 / durability2) * n2 : 0.0;

    final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
    final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;

    final metrics1 = [
      if (energyCostTotal1 > 0) {'title': l10n.energyCostLabel, 'value': energyCostTotal1, 'color': Colors.blue.shade700},
      if (maintenanceCost1 > 0) {'title': l10n.maintenanceCostLabel, 'value': maintenanceCost1, 'color': Colors.green.shade700},
      if (capitalCost1 > 0) {'title': l10n.capitalCostLabel, 'value': capitalCost1, 'color': Colors.orange.shade700},
    ];

    final metrics2 = [
       if (energyCostTotal2 > 0) {'title': l10n.energyCostLabel, 'value': energyCostTotal2, 'color': Colors.blue.shade700},
       if (maintenanceCost2 > 0) {'title': l10n.maintenanceCostLabel, 'value': maintenanceCost2, 'color': Colors.green.shade700},
       if (capitalCost2 > 0) {'title': l10n.capitalCostLabel, 'value': capitalCost2, 'color': Colors.orange.shade700},
    ];

     if (metrics1.isEmpty && metrics2.isEmpty) {
       return const SizedBox.shrink(); // Don't show if no data for either
     }

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
          crossAxisAlignment: CrossAxisAlignment.start, // Align tops
          children: [
            // Pie Chart for Aerator 1
            if (metrics1.isNotEmpty && totalCost1 > 0)
              Expanded( // Use Expanded to allow charts to take space
                child: Column(
                  children: [
                    Text(l10n.aerator1, style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 150, // Fixed height
                      // width: 150, // Width is determined by Expanded
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
                          centerSpaceRadius: 30, // Smaller center space
                           pieTouchData: _buildPieTouchData(metrics1, l10n),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 0),
                      ),
                    ),
                  ],
                ),
              ),
            // Pie Chart for Aerator 2
             if (metrics2.isNotEmpty && totalCost2 > 0)
               Expanded(
                 child: Column(
                   children: [
                     Text(l10n.aerator2, style: const TextStyle(fontWeight: FontWeight.bold)),
                     SizedBox(
                       height: 150,
                       // width: 150,
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
                            pieTouchData: _buildPieTouchData(metrics2, l10n),
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
        // Legend for Cost Breakdown Pie Charts (use common metrics)
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
                   decoration: BoxDecoration(
                     color: metric['color'] as Color,
                     shape: BoxShape.circle,
                   ),
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

  // Helper for Pie Touch Data
  PieTouchData _buildPieTouchData(List<Map<String, dynamic>> metrics, AppLocalizations l10n) {
     return PieTouchData(
       enabled: true,
       tooltipData: PieTouchTooltipData(
         tooltipBgColor: Colors.black87,
         getTooltipItems: (touchedSpots) {
           return touchedSpots.map((touchedSpot) {
             if (touchedSpot.touchedSectionIndex < 0 || touchedSpot.touchedSectionIndex >= metrics.length) return null;
             final metric = metrics[touchedSpot.touchedSectionIndex];
             return PieTooltipItem(
               '${metric['title']}\n${_formatValueWithThousandSeparator(metric['value'])}', // Show title and value
               const TextStyle(color: Colors.white, fontSize: 12), // Smaller font
               textAlign: TextAlign.center, // Center align text
             );
           }).whereType<PieTooltipItem>().toList();
         },
       ),
       touchCallback: (FlTouchEvent event, pieTouchResponse) {
         // Optional: Handle touch events if needed, e.g., for highlighting
       },
     );
  }


  // --- Helper Methods ---

  String _formatValue(dynamic value) {
    if (value is double) {
      if (value.isNaN || value.isInfinite) return "N/A";
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatValueWithThousandSeparator(dynamic value) {
     if (value is double) {
      if (value.isNaN || value.isInfinite) return "N/A";
      if (value.abs() >= 1000000) {
        return NumberFormat.compact().format(value);
      }
      // Use currency format for costs
      return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(value);
      // return NumberFormat('#,##0.00').format(value); // Original formatting
    } else if (value is int) {
       if (value.abs() >= 1000000) {
        return NumberFormat.compact().format(value);
      }
       // Use currency format for costs if applicable (e.g., number of units might not be currency)
       // Check the context where this is called if needed. For now, assume non-currency for int.
      return NumberFormat('#,##0').format(value);
    }
    return value.toString();
  }

  // FIX: Modify method signature to accept BuildContext
  void _downloadAsCsv(BuildContext context, Map<String, dynamic> inputs, Map<String, dynamic> results) {
     // FIX: Get l10n object using context
    final l10n = AppLocalizations.of(context)!;
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

    // Cost Breakdown Section (Only for Aerator Comparison Tab)
    if (widget.tab == 'Aerator Comparison') {
        csvRows.add('');
        csvRows.add('"Cost Breakdown (Annual, USD)"'); // Add units to header
        csvRows.add('"Category","Aerator 1","Aerator 2"'); // Change header structure

        // Extract values safely
        final energyCost1 = inputs['Annual Energy Cost Aerator 1 (USD/year per aerator)'] as double? ?? 0.0;
        final energyCost2 = inputs['Annual Energy Cost Aerator 2 (USD/year per aerator)'] as double? ?? 0.0;
        final maintenance1Input = inputs[l10n.maintenanceCostAerator1Label] as double? ?? 0.0;
        final maintenance2Input = inputs[l10n.maintenanceCostAerator2Label] as double? ?? 0.0;
        final price1 = inputs[l10n.priceAerator1Label] as double? ?? 0.0;
        final price2 = inputs[l10n.priceAerator2Label] as double? ?? 0.0;
        final durability1 = inputs[l10n.durabilityAerator1Label] as double? ?? 1.0;
        final durability2 = inputs[l10n.durabilityAerator2Label] as double? ?? 1.0;
        final n1 = results[l10n.numberOfAerator1UnitsLabel] is int ? results[l10n.numberOfAerator1UnitsLabel] as int : (results[l10n.numberOfAerator1UnitsLabel] as double? ?? 0.0).toInt();
        final n2 = results[l10n.numberOfAerator2UnitsLabel] is int ? results[l10n.numberOfAerator2UnitsLabel] as int : (results[l10n.numberOfAerator2UnitsLabel] as double? ?? 0.0).toInt();


        final energyCostTotal1 = energyCost1 * n1;
        final energyCostTotal2 = energyCost2 * n2;
        final maintenanceCost1 = maintenance1Input * n1;
        final maintenanceCost2 = maintenance2Input * n2;
        final capitalCost1 = durability1 > 0 ? (price1 / durability1) * n1 : 0.0;
        final capitalCost2 = durability2 > 0 ? (price2 / durability2) * n2 : 0.0;
        final totalCost1 = energyCostTotal1 + maintenanceCost1 + capitalCost1;
        final totalCost2 = energyCostTotal2 + maintenanceCost2 + capitalCost2;


        // Add rows for each cost component
        csvRows.add('"${l10n.energyCostLabel}","${_formatValue(energyCostTotal1)}","${_formatValue(energyCostTotal2)}"');
        csvRows.add('"${l10n.maintenanceCostLabel}","${_formatValue(maintenanceCost1)}","${_formatValue(maintenanceCost2)}"');
        csvRows.add('"${l10n.capitalCostLabel}","${_formatValue(capitalCost1)}","${_formatValue(capitalCost2)}"');
        csvRows.add('"Total Annual Cost","${_formatValue(totalCost1)}","${_formatValue(totalCost2)}"'); // Add total row
    }


    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv;charset=utf-8;'); // Ensure UTF-8
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_data_${widget.tab.replaceAll(' ', '_')}_${DateTime.now().toIso8601String()}.csv') // Use tab name in filename
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

// Helper function needed if using .reduce(max)
// double max(double a, double b) => a > b ? a : b; // Already imported dart:math

import 'dart:math'; // Import needed for reduce(max)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../core/services/app_state.dart';

class OxygenDemandResultsDisplay extends StatelessWidget {
  const OxygenDemandResultsDisplay({super.key});

  // Helper method to safely get localized string based on string key
  // Maintain this map consistent with keys used in OxygenDemandAndEstimationForm
  String _getL10nString(AppLocalizations l10n, String key, {String defaultValue = ''}) {
    switch (key) {
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
      // Add other keys if necessary
      default:
        debugPrint("Warning: Missing localization mapping for key '$key' in OxygenDemandResultsDisplay");
        return key; // Return the key itself if no mapping found
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get l10n object from context *once*
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use the consistent key used in the form
        final results = appState.getResults('Oxygen Demand and Estimation');
        final inputs = appState.getInputs('Oxygen Demand and Estimation');

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

        // Safely get the value using the string key
        // Check if the key exists and the value is a number
        final totalOxygenDemandValue = results['totalOxygenDemandLabel'];
        final totalOxygenDemand = totalOxygenDemandValue is num
            ? totalOxygenDemandValue.toDouble()
            : 0.0;

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
                    l10n.oxygenDemandResults,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add a bar chart for visualization
                  _buildOxygenDemandChart(results, l10n),
                  const SizedBox(height: 16),
                  // Display results using a ListView
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final entry = results.entries.elementAt(index);
                      // Get the localized label using the helper function
                      final displayLabel = _getL10nString(l10n, entry.key, defaultValue: entry.key);
                      // Check if this is the total demand key for the copy button
                      final isTotalDemandKey = entry.key == 'totalOxygenDemandLabel';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                displayLabel, // Display localized label
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
                                  // Show copy button only for the total demand key
                                  if (isTotalDemandKey) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        // Use the correctly retrieved totalOxygenDemand
                                        final formattedValue = _formatValue(totalOxygenDemand);
                                        FlutterClipboard.copy(formattedValue).then((_) {
                                          // FIX: Use positional argument for valueCopied
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.valueCopied(formattedValue), // Pass value positionally
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
                    },
                    separatorBuilder: (context, index) => const Divider(height: 1),
                  ),
                  const SizedBox(height: 16),
                  if (inputs != null)
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        // Pass l10n object to _downloadAsCsv
                        onPressed: () => _downloadAsCsv(inputs, results, l10n),
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

  // Helper method to build the chart
  Widget _buildOxygenDemandChart(Map<String, dynamic> results, AppLocalizations l10n) {
    // Safely access results using string keys and check types
    final shrimpDemandValue = results['oxygenDemandFromShrimpLabel'];
    final shrimpDemand = shrimpDemandValue is num ? shrimpDemandValue.toDouble() : 0.0;

    final envDemandValue = results['environmentalOxygenDemandLabel'];
    final envDemand = envDemandValue is num ? envDemandValue.toDouble() : 0.0;

    final totalDemandValue = results['totalOxygenDemandLabel'];
    final totalDemand = totalDemandValue is num ? totalDemandValue.toDouble() : 0.0;

    // Use localized short labels for chart titles
    final metrics = [
      if (shrimpDemand >= 0) {'title': l10n.oxygenDemandFromShrimpLabelShort, 'value': shrimpDemand},
      if (envDemand >= 0) {'title': l10n.environmentalOxygenDemandLabelShort, 'value': envDemand},
      if (totalDemand >= 0) {'title': l10n.totalOxygenDemandLabelShort, 'value': totalDemand},
    ];

    if (metrics.isEmpty) {
      return SizedBox(height: 200, child: Center(child: Text(l10n.noDataForChart))); // Localized
    }

    // Calculate maxY safely
    final maxYValue = metrics.map((e) => e['value'] as double).fold(0.0, max); // Use fold for safety
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0;

    // Calculate interval safely
    final double interval = maxY / 5 > 0 ? maxY / 5 : 1;

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
                   // Use compact format for potentially large numbers
                   return Text(
                     NumberFormat.compact().format(value),
                     style: const TextStyle(color: Colors.black54, fontSize: 12),
                   );
                }
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
          gridData: FlGridData( // Removed const
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: interval, // Use calculated interval
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
    );
  }

  // Helper method for formatting values
  String _formatValue(dynamic value) {
    if (value is double) {
      if (value.isNaN || value.isInfinite) return "N/A";
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    }
    return value.toString(); // Handle other types
  }

  // Helper method for formatting values with separators
  String _formatValueWithThousandSeparator(dynamic value) {
     if (value is double) {
        if (value.isNaN || value.isInfinite) return "N/A";
        if (value.abs() >= 1e6) { // Compact for millions or more
          return NumberFormat.compact().format(value);
        }
        return NumberFormat('#,##0.00').format(value); // Standard format
     } else if (value is int) {
        if (value.abs() >= 1e6) {
          return NumberFormat.compact().format(value);
        }
        return NumberFormat('#,##0').format(value); // Format integers with separators
     }
     return value.toString(); // Fallback
  }

  // Helper method for CSV download
  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results, AppLocalizations l10n) {
    final csvRows = <String>[];

    // --- Inputs Section ---
    csvRows.add('"Inputs"');
    csvRows.add('"Category","Value"');
    inputs.forEach((key, value) {
      // Get localized label using the helper
      final displayKey = _getL10nString(l10n, key, defaultValue: key);
      final escapedKey = displayKey.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    // --- Results Section ---
    csvRows.add('');
    csvRows.add('"Results"');
    csvRows.add('"Category","Value"');
    results.forEach((key, value) {
      // Get localized label using the helper
      final displayKey = _getL10nString(l10n, key, defaultValue: key);
      final escapedKey = displayKey.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    // --- CSV Generation and Download ---
    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'aerasync_oxygen_demand_$timestamp.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

// Helper function needed if using .reduce(max) or .fold(0.0, max)
// Already imported dart:math
// double max(double a, double b) => a > b ? a : b;

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

  @override
  Widget build(BuildContext context) {
    // Get l10n object from context
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Updated key to match the merged form
        final results = appState.getResults('Oxygen Demand and Estimation');
        final inputs = appState.getInputs('Oxygen Demand and Estimation');

        if (results == null || results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.enterValuesToCalculate,
              // Consider using Theme.of(context).textTheme style
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Safely get the value, providing a default if null or wrong type
        final totalOxygenDemand = results[l10n.totalOxygenDemandLabel] is double
            ? results[l10n.totalOxygenDemandLabel] as double
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
                  // Display results using a ListView for better structure if many items
                  ListView.separated(
                    shrinkWrap: true, // Important inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final entry = results.entries.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced padding
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, // Adjust flex for better spacing
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 2, // Adjust flex for better spacing
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible( // Allow text to wrap if needed
                                    child: Text(
                                      _formatValueWithThousandSeparator(entry.value),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                      overflow: TextOverflow.ellipsis, // Prevent overflow
                                    ),
                                  ),
                                  // Only show copy button for the specific key
                                  if (entry.key == l10n.totalOxygenDemandLabel) ...[
                                    const SizedBox(width: 4), // Reduced spacing
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1E40AF)), // Smaller icon
                                      padding: EdgeInsets.zero, // Remove default padding
                                      constraints: const BoxConstraints(), // Remove constraints
                                      onPressed: () {
                                        // Use the correctly retrieved totalOxygenDemand
                                        FlutterClipboard.copy(_formatValue(totalOxygenDemand)).then((value) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                // FIX: Pass the required 'value' argument
                                                l10n.valueCopied(value: l10n.totalOxygenDemandLabel),
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
                    separatorBuilder: (context, index) => const Divider(height: 1), // Add dividers
                  ),
                  const SizedBox(height: 16),
                  if (inputs != null) // Ensure inputs are not null before enabling button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        // FIX: Pass l10n object to _downloadAsCsv
                        onPressed: () => _downloadAsCsv(inputs, results, l10n),
                        icon: const Icon(Icons.download), // Standard size is fine
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
    // Safely access results with default values
    final shrimpDemand = results[l10n.oxygenDemandFromShrimpLabel] is double
        ? results[l10n.oxygenDemandFromShrimpLabel] as double
        : 0.0;
    final envDemand = results[l10n.environmentalOxygenDemandLabel] is double
        ? results[l10n.environmentalOxygenDemandLabel] as double
        : 0.0;
    final totalDemand = results[l10n.totalOxygenDemandLabel] is double
        ? results[l10n.totalOxygenDemandLabel] as double
        : 0.0;

    // Ensure metrics list only contains valid data
    final metrics = [
      if (shrimpDemand >= 0) {'title': l10n.oxygenDemandFromShrimpLabelShort, 'value': shrimpDemand},
      if (envDemand >= 0) {'title': l10n.environmentalOxygenDemandLabelShort, 'value': envDemand},
      if (totalDemand >= 0) {'title': l10n.totalOxygenDemandLabelShort, 'value': totalDemand},
    ];

    // Handle case where there are no valid metrics to display
    if (metrics.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No data for chart")));
    }

    // Calculate maxY safely
    final maxYValue = metrics.map((e) => e['value'] as double).reduce(max);
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0; // Avoid maxY being 0

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
                  // Avoid showing 0.0 if maxY is 1.0 due to no data
                   if (maxY == 1.0 && value == 0) return const SizedBox.shrink();
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
                   // Check bounds before accessing metrics list
                   if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                     return Text(
                       metrics[value.toInt()]['title'] as String,
                       style: const TextStyle(color: Colors.black54, fontSize: 12),
                     );
                   }
                   return const SizedBox.shrink(); // Return empty for invalid index
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1, // Dynamic interval
          ),
          barTouchData: BarTouchData(enabled: false), // Keep disabled for simplicity
        ),
        swapAnimationDuration: const Duration(milliseconds: 0), // Keep disabled
      ),
    );
  }

  // Helper method for formatting values (remains the same)
  String _formatValue(dynamic value) {
    if (value is double) {
      // Handle potential NaN or Infinity
      if (value.isNaN || value.isInfinite) return "N/A";
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  // Helper method for formatting values with separators (remains the same)
  String _formatValueWithThousandSeparator(dynamic value) {
     if (value is double) {
      if (value.isNaN || value.isInfinite) return "N/A";
      if (value.abs() >= 1000000) {
        return NumberFormat.compact().format(value);
      }
      return NumberFormat('#,##0.00').format(value);
    } else if (value is int) {
       if (value.abs() >= 1000000) {
        return NumberFormat.compact().format(value);
      }
      return NumberFormat('#,##0').format(value);
    }
    return value.toString();
  }

  // FIX: Modify method signature to accept l10n
  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results, AppLocalizations l10n) {
    final csvRows = <String>[];

    // Use l10n for headers if desired, e.g., csvRows.add('"${l10n.inputsCategory}"');
    // Inputs Section
    csvRows.add('"Inputs"');
    csvRows.add('"Category","Value"');
    inputs.forEach((key, value) {
      // Escape quotes within key and value
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    // Results Section
    csvRows.add(''); // Add empty row for spacing
    csvRows.add('"Results"');
    csvRows.add('"Category","Value"');
    results.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    final csvContent = csvRows.join('\n');
    // Use universal_html for web compatibility
    final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element and trigger download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_oxygen_demand_${DateTime.now().toIso8601String()}.csv')
      ..click();

    // Release the object URL
    html.Url.revokeObjectUrl(url);
  }
}

// Helper function to find max value in a list (needed for maxY calculation)
double max(double a, double b) => a > b ? a : b;

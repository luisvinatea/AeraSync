import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:AeraSync/generated/l10n.dart';
import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../core/services/app_state.dart';

class OxygenDemandResultsDisplay extends StatelessWidget {
  const OxygenDemandResultsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final totalOxygenDemand = results[l10n.totalOxygenDemandLabel] as double;

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
                  ...results.entries.map((entry) {
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
                                if (entry.key == l10n.totalOxygenDemandLabel) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Color(0xFF1E40AF)),
                                    onPressed: () {
                                      FlutterClipboard.copy(_formatValue(totalOxygenDemand)).then((value) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
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
                  }),
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

  Widget _buildOxygenDemandChart(Map<String, dynamic> results, AppLocalizations l10n) {
    final metrics = [
      {
        'title': l10n.oxygenDemandFromShrimpLabelShort,
        'value': results[l10n.oxygenDemandFromShrimpLabel] as double? ?? 0.0,
      },
      {
        'title': l10n.environmentalOxygenDemandLabelShort,
        'value': results[l10n.environmentalOxygenDemandLabel] as double? ?? 0.0,
      },
      {
        'title': l10n.totalOxygenDemandLabelShort,
        'value': results[l10n.totalOxygenDemandLabel] as double? ?? 0.0,
      },
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
                  NumberFormat.compact().format(value),
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
          barTouchData: BarTouchData(enabled: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 0),
      ),
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

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_oxygen_demand_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
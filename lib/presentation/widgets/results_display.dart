import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:AeraSync/generated/l10n.dart';
import 'package:clipboard/clipboard.dart';
import '../../core/services/app_state.dart';

class ResultsDisplay extends StatelessWidget {
  final String tab;

  const ResultsDisplay({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults(tab);
        final inputs = appState.getInputs(tab);

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
        if (tab == 'Aerator Comparison') {
          final totalCost1 = results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0;
          final totalCost2 = results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0;
          final costOfOpportunity = results['Cost of Opportunity (USD)'] as double? ?? 0.0;
          if (totalCost1 > totalCost2) {
            recommendationMessage = l10n.recommendationChooseAerator2(
                _formatValue(costOfOpportunity));
          } else if (totalCost2 > totalCost1) {
            recommendationMessage = l10n.recommendationChooseAerator1(
                _formatValue(costOfOpportunity));
          } else {
            recommendationMessage = l10n.recommendationEqualCosts;
          }
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
                  // Bar Chart for Aerator Estimation and Aerator Comparison
                  if (tab == 'Aerator Estimation') ...[
                    _buildAeratorEstimationChart(results, l10n),
                    const SizedBox(height: 16),
                  ],
                  if (tab == 'Aerator Comparison') ...[
                    _buildAeratorComparisonChart(results, l10n),
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
                  // List of all results
                  ...results.entries.map((entry) {
                    final isKeyMetric = (tab == 'Aerator Performance' &&
                            entry.key == 'SOTR (kg O₂/h)') ||
                        (tab == 'Aerator Estimation' &&
                            entry.key == l10n.numberOfAeratorsPerHectareLabel) ||
                        (tab == 'Aerator Comparison' &&
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
                                  _formatValue(entry.value),
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
                                              l10n.valueCopied(entry.key),
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

  Widget _buildAeratorComparisonChart(Map<String, dynamic> results, AppLocalizations l10n) {
    final metrics = [
      {
        'title': l10n.totalAnnualCostAerator1LabelShort,
        'value': results[l10n.totalAnnualCostAerator1Label] as double? ?? 0.0,
      },
      {
        'title': l10n.totalAnnualCostAerator2LabelShort,
        'value': results[l10n.totalAnnualCostAerator2Label] as double? ?? 0.0,
      },
      {
        'title': l10n.costOfOpportunityLabelShort,
        'value': results['Cost of Opportunity (USD)'] as double? ?? 0.0,
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
                  value.toStringAsFixed(0), // Use 0 decimals for large financial values
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

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results) {
    final combinedData = <String, dynamic>{};
    inputs.forEach((key, value) => combinedData['Input: $key'] = value);
    results.forEach((key, value) => combinedData['Result: $key'] = value);

    final csvRows = <String>['"Category","Value"'];
    combinedData.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_data_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
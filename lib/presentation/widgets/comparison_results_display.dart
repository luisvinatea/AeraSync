// /home/luisvinatea/Dev/Repos/AeraSync/AeraSync/lib/presentation/widgets/comparison_results_display.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/services/app_state.dart';

class ComparisonResultsDisplay extends StatelessWidget {
  const ComparisonResultsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults('Aerator Comparison');
        final inputs = appState.getInputs('Aerator Comparison');

        if (results == null || results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Enter values and click Calculate to see results',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final n1 = results['Number of Aerator 1 Units'] as double;
        final n2 = results['Number of Aerator 2 Units'] as double;
        final totalCost1 = results['Total Annual Cost Aerator 1 (USD/year)'] as double;
        final totalCost2 = results['Total Annual Cost Aerator 2 (USD/year)'] as double;
        final p2Equilibrium = results['Equilibrium Price P₂ (USD)'] as double;
        final price2 = results['Actual Price P₂ (USD)'] as double;

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
                  const Text(
                    'Comparison Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Equilibrium Price (P₂): \$${p2Equilibrium.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actual Price (P₂): \$${price2.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p2Equilibrium > price2
                        ? 'Aerator 2 is more cost-effective at the current price.'
                        : 'Aerator 1 may be more cost-effective at the current price.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Number of Aerators Needed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (n1 > n2 ? n1 : n2) * 1.2,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: n1,
                                color: const Color(0xFF1E40AF),
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: n2,
                                color: Colors.green,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Aerator 1',
                                        style: TextStyle(color: Colors.black54, fontSize: 12));
                                  case 1:
                                    return const Text('Aerator 2',
                                        style: TextStyle(color: Colors.black54, fontSize: 12));
                                  default:
                                    return const Text('');
                                }
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Total Annual Cost (USD/year)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (totalCost1 > totalCost2 ? totalCost1 : totalCost2) * 1.2,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: totalCost1,
                                color: const Color(0xFF1E40AF),
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: totalCost2,
                                color: Colors.green,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  (value / 1000).toStringAsFixed(0) + 'k',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Aerator 1',
                                        style: TextStyle(color: Colors.black54, fontSize: 12));
                                  case 1:
                                    return const Text('Aerator 2',
                                        style: TextStyle(color: Colors.black54, fontSize: 12));
                                  default:
                                    return const Text('');
                                }
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadAsCsv(inputs!, results),
                      icon: const Icon(Icons.download, size: 32),
                      label: const Text('Download as CSV (only values)'),
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

    html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_comparison_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
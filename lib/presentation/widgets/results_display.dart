import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/services/app_state.dart';

class ResultsDisplay extends StatelessWidget {
  final String tab;

  const ResultsDisplay({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults(tab);
        final inputs = appState.getInputs(tab);

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
                    'Performance Metrics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bar Chart for key metrics
                  if (tab == 'Aerator Performance') ...[
                    _buildAeratorPerformanceChart(results),
                    const SizedBox(height: 16),
                  ],
                  if (tab == 'Aerator Estimation') ...[
                    _buildAeratorEstimationChart(results),
                    const SizedBox(height: 16),
                  ],
                  // List of all results
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
                            child: Text(
                              _formatValue(entry.value),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
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

  Widget _buildAeratorPerformanceChart(Map<String, dynamic> results) {
    // Select key metrics for visualization
    final metrics = [
      {'title': 'SOTR', 'value': results['SOTR (kg O₂/h)'] as double? ?? 0.0},
      {'title': 'SAE', 'value': results['SAE (kg O₂/kWh)'] as double? ?? 0.0},
      {'title': 'KLa', 'value': results['KLa (h⁻¹)'] as double? ?? 0.0},
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: metrics.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
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
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    metrics[value.toInt()]['title'] as String,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: false,  // Updated to use 'show'
          ),
          gridData: const FlGridData(
            drawHorizontalLine: true,  // Updated to use 'drawHorizontalLine'
            drawVerticalLine: false,  // Updated to use 'drawVerticalLine'
          ),
        ),
      ),
    );
  }

  Widget _buildAeratorEstimationChart(Map<String, dynamic> results) {
    // Select key metrics for visualization
    final metrics = [
      {'title': 'TOD', 'value': results['TOD (kg O₂/h)'] as double? ?? 0.0},
      {'title': 'OTRt', 'value': results['OTRt (kg O₂/h)'] as double? ?? 0.0},
      {'title': 'Aerators', 'value': results['Number of Aerators per Hectare'] as double? ?? 0.0},
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: metrics.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
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
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    metrics[value.toInt()]['title'] as String,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: false,  // Updated to use 'show'
          ),
          gridData: const FlGridData(
            drawHorizontalLine: true,  // Updated to use 'drawHorizontalLine'
            drawVerticalLine: false,  // Updated to use 'drawVerticalLine'
          ),
        ),
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

    html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_data_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
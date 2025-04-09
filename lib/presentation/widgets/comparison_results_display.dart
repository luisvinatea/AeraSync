import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:AeraSync/generated/l10n.dart';
import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../core/services/app_state.dart';

class ComparisonResultsDisplay extends StatefulWidget {
  const ComparisonResultsDisplay({super.key});

  @override
  _ComparisonResultsDisplayState createState() => _ComparisonResultsDisplayState();
}

class _ComparisonResultsDisplayState extends State<ComparisonResultsDisplay> {
  bool _showBarChart = true; // State to toggle between bar chart and pie chart

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults('Aerator Comparison');
        final inputs = appState.getInputs('Aerator Comparison');

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

        final n1 = results[l10n.numberOfAerator1UnitsLabel] as double;
        final n2 = results[l10n.numberOfAerator2UnitsLabel] as double;
        final totalCost1 = results[l10n.totalAnnualCostAerator1Label] as double;
        final totalCost2 = results[l10n.totalAnnualCostAerator2Label] as double;
        final p2Equilibrium = results[l10n.equilibriumPriceP2Label] as double;
        final price2 = results[l10n.actualPriceP2Label] as double;

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
                    l10n.comparisonResults,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.equilibriumPriceP2Label}: \$${NumberFormat('#,##0.00').format(p2Equilibrium)}',
                        style: const TextStyle(fontSize: 18, color: Color(0xFF1E40AF)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF1E40AF)),
                        onPressed: () {
                          FlutterClipboard.copy(p2Equilibrium.toStringAsFixed(2)).then((value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.valueCopied(value: l10n.equilibriumPriceP2Label)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          });
                        },
                        tooltip: l10n.copyToClipboardTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.actualPriceP2Label}: \$${NumberFormat('#,##0.00').format(price2)}',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p2Equilibrium > price2
                        ? l10n.aerator2MoreCostEffective
                        : l10n.aerator1MoreCostEffective,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.numberOfAeratorsNeeded,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        child: Text(l10n.barChartLabel),
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
                        child: Text(l10n.pieChartLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _showBarChart
                        ? _buildAeratorCountBarChart(n1, n2, l10n, key: const Key('barChart1'))
                        : _buildAeratorCountPieChart(n1, n2, l10n, key: const Key('pieChart1')),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.totalAnnualCostLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _showBarChart
                        ? _buildTotalCostBarChart(totalCost1, totalCost2, l10n, key: const Key('barChart2'))
                        : _buildTotalCostPieChart(totalCost1, totalCost2, l10n, key: const Key('pieChart2')),
                  ),
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

  Widget _buildAeratorCountBarChart(double n1, double n2, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.aerator1,
        'value': n1,
        'tooltip': l10n.numberOfAerator1UnitsTooltip,
        'color': const Color(0xFF1E40AF),
      },
      {
        'title': l10n.aerator2,
        'value': n2,
        'tooltip': l10n.numberOfAerator2UnitsTooltip,
        'color': Colors.green,
      },
    ];

    final maxY = (n1 > n2 ? n1 : n2) * 1.2;

    return SizedBox(
      key: key,
      height: 200,
      child: Column(
        children: [
          Expanded(
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
                        color: metric['color'] as Color,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat('#,##0').format(value),
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
                        NumberFormat('#,##0.00').format(rod.toY),
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
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildAeratorCountPieChart(double n1, double n2, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.aerator1,
        'value': n1,
        'tooltip': l10n.numberOfAerator1UnitsTooltip,
        'color': const Color(0xFF1E40AF),
      },
      {
        'title': l10n.aerator2,
        'value': n2,
        'tooltip': l10n.numberOfAerator2UnitsTooltip,
        'color': Colors.green,
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
                  final metric = entry.value;
                  final value = metric['value'] as double;
                  final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
                  return PieChartSectionData(
                    color: metric['color'] as Color,
                    value: value,
                    title: totalValue > 0 ? '$percentage%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    showTitle: totalValue > 0,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  longPressDuration: const Duration(milliseconds: 500),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildTotalCostBarChart(double totalCost1, double totalCost2, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.aerator1,
        'value': totalCost1,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
        'color': const Color(0xFF1E40AF),
      },
      {
        'title': l10n.aerator2,
        'value': totalCost2,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
        'color': Colors.green,
      },
    ];

    final maxY = (totalCost1 > totalCost2 ? totalCost1 : totalCost2) * 1.2;

    return SizedBox(
      key: key,
      height: 200,
      child: Column(
        children: [
          Expanded(
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
                        color: metric['color'] as Color,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
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
                        NumberFormat('#,##0.00').format(rod.toY),
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
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildTotalCostPieChart(double totalCost1, double totalCost2, AppLocalizations l10n, {Key? key}) {
    final metrics = [
      {
        'title': l10n.aerator1,
        'value': totalCost1,
        'tooltip': l10n.totalAnnualCostAerator1Tooltip,
        'color': const Color(0xFF1E40AF),
      },
      {
        'title': l10n.aerator2,
        'value': totalCost2,
        'tooltip': l10n.totalAnnualCostAerator2Tooltip,
        'color': Colors.green,
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
                  final metric = entry.value;
                  final value = metric['value'] as double;
                  final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
                  return PieChartSectionData(
                    color: metric['color'] as Color,
                    value: value,
                    title: totalValue > 0 ? '$percentage%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    showTitle: totalValue > 0,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  longPressDuration: const Duration(milliseconds: 500),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 0),
            ),
          ),
          const SizedBox(height: 8),
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

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatValueWithThousandSeparator(dynamic value) {
    if (value is double) {
      return NumberFormat('#,##0.00').format(value);
    } else if (value is int) {
      return NumberFormat('#,##0').format(value);
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
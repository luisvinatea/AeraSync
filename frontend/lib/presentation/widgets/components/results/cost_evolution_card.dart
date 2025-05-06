import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'aerator_result.dart';
import '../../../../core/theme/app_theme.dart';

class CostEvolutionCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String? winnerLabel;
  final Map<String, dynamic>? surveyData;

  const CostEvolutionCard({
    super.key,
    required this.l10n,
    required this.results,
    required this.winnerLabel,
    required this.surveyData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.costEvolutionVisualization,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Cumulative cost difference (including initial cost) vs. recommended aerator over time',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: _getAreaChartData(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: _calculateYAxisInterval(),
                        getTitlesWidget: (value, meta) {
                          if (value % _calculateYAxisInterval() != 0) {
                            return const SizedBox.shrink();
                          }
                          final formattedValue = value >= 1_000_000
                              ? '\$${(value / 1_000_000).toStringAsFixed(1)}M'
                              : value >= 1_000
                                  ? '\$${(value / 1_000).toStringAsFixed(0)}K'
                                  : '\$${value.toInt()}';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(),
                      left: BorderSide(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateYAxisInterval(),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.red,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendForCostEvolution(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendForCostEvolution(BuildContext context) {
    if (winnerLabel == null) {
      return const SizedBox.shrink();
    }

    final winnerAerator = results.firstWhere(
      (result) => result.name == winnerLabel,
      orElse: () => results.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.withAlpha(51), Colors.blue],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Cumulative cost difference vs ${winnerAerator.name}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateYAxisInterval() {
    final maxDifference = _getMaxCostDifference();
    if (maxDifference <= 5000) return 1000;
    if (maxDifference <= 20000) return 5000;
    if (maxDifference <= 100000) return 20000;
    if (maxDifference <= 1000000) return 200000;
    return maxDifference / 5;
  }

  double _getMaxCostDifference() {
    if (winnerLabel == null || results.isEmpty) {
      return 10000;
    }

    final winnerAerator = results.firstWhere(
      (result) => result.name == winnerLabel,
      orElse: () => results.first,
    );

    final horizon = surveyData?['financial']?['horizon'] as int? ?? 10;
    double maxDiff = 0;
    double minDiff = 0;

    for (var result in results) {
      if (result.name != winnerLabel) {
        double cumulativeDiff =
            result.totalInitialCost - winnerAerator.totalInitialCost;
        if (cumulativeDiff > maxDiff) maxDiff = cumulativeDiff;
        if (cumulativeDiff < minDiff) minDiff = cumulativeDiff;

        for (var year = 1; year <= horizon; year++) {
          cumulativeDiff +=
              result.totalAnnualCost - winnerAerator.totalAnnualCost;
          if (cumulativeDiff > maxDiff) maxDiff = cumulativeDiff;
          if (cumulativeDiff < minDiff) minDiff = cumulativeDiff;
        }
      }
    }

    return (maxDiff.abs() > minDiff.abs()) ? maxDiff : minDiff.abs();
  }

  List<LineChartBarData> _getAreaChartData() {
    final List<LineChartBarData> barData = [];

    if (winnerLabel == null || results.isEmpty) {
      return barData;
    }

    final winnerAerator = results.firstWhere(
      (result) => result.name == winnerLabel,
      orElse: () => results.first,
    );

    final horizon = surveyData?['financial']?['horizon'] as int? ?? 10;

    // Create a different colored line for each aerator
    int colorIndex = 0;

    for (var result in results) {
      if (result.name != winnerLabel) {
        final spots = <FlSpot>[];
        double cumulativeDiff =
            result.totalInitialCost - winnerAerator.totalInitialCost;
        spots.add(FlSpot(0, cumulativeDiff));

        for (var year = 1; year <= horizon; year++) {
          cumulativeDiff +=
              result.totalAnnualCost - winnerAerator.totalAnnualCost;
          spots.add(FlSpot(year.toDouble(), cumulativeDiff));
        }

        barData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color:
                AppTheme.chartColors[colorIndex % AppTheme.chartColors.length],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme
                  .chartColors[colorIndex % AppTheme.chartColors.length]
                  .withAlpha(76),
              applyCutOffY: false,
            ),
          ),
        );

        colorIndex++;
      }
    }

    return barData;
  }
}

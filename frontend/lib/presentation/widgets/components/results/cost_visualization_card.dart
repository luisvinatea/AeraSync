import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/formatting_utils.dart';
import 'aerator_result.dart';
import '../../../../core/theme/app_theme.dart';

class CostVisualizationCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String winnerLabel;

  const CostVisualizationCard({
    super.key,
    required this.l10n,
    required this.results,
    required this.winnerLabel,
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
              l10n.costBreakdownVisualization,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyHeadings,
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              l10n.annualCostComposition,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyBody,
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            SizedBox(
              height: 450,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 24.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxCost() * 1.3,
                    barGroups: _getBarGroups(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < results.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  results[value.toInt()].name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 40,
                        ),
                      ),
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
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateYAxisInterval(),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(),
                        left: BorderSide(),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white.withAlpha(204),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final result = results[groupIndex];
                          String component = '';
                          double value = 0.0;

                          if (rodIndex < 0 ||
                              rodIndex >= rod.rodStackItems.length) {
                            return null;
                          }

                          switch (rodIndex) {
                            case 0:
                              component = l10n.annualEnergyCostLabel;
                              value = result.annualEnergyCost;
                              break;
                            case 1:
                              component = l10n.annualMaintenanceCostLabel;
                              value = result.annualMaintenanceCost;
                              break;
                            case 2:
                              component = l10n.annualReplacementCostLabel;
                              value = result.annualReplacementCost;
                              break;
                            default:
                              return null;
                          }

                          return BarTooltipItem(
                            '$component\n${FormattingUtils.formatCurrencyK(value)}',
                            const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      touchCallback:
                          (FlTouchEvent event, BarTouchResponse? response) {
                        // Touch callback can be implemented if needed
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppTheme.chartColors[0], l10n.annualEnergyCostLabel),
        const SizedBox(width: 16),
        _legendItem(AppTheme.chartColors[1], l10n.annualMaintenanceCostLabel),
        const SizedBox(width: 16),
        _legendItem(AppTheme.chartColors[2], l10n.annualReplacementCostLabel),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  double _getMaxCost() {
    double maxCost = 0;
    for (final result in results) {
      final totalCost = result.annualEnergyCost +
          result.annualMaintenanceCost +
          result.annualReplacementCost;
      if (totalCost > maxCost) {
        maxCost = totalCost;
      }
    }
    return maxCost;
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(results.length, (index) {
      final result = results[index];
      final isWinner = result.name == winnerLabel;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: result.annualEnergyCost +
                result.annualMaintenanceCost +
                result.annualReplacementCost,
            width: 60,
            borderRadius: BorderRadius.zero,
            rodStackItems: [
              BarChartRodStackItem(
                  0, result.annualEnergyCost, AppTheme.chartColors[0]),
              BarChartRodStackItem(
                  result.annualEnergyCost,
                  result.annualEnergyCost + result.annualMaintenanceCost,
                  AppTheme.chartColors[1]),
              BarChartRodStackItem(
                  result.annualEnergyCost + result.annualMaintenanceCost,
                  result.annualEnergyCost +
                      result.annualMaintenanceCost +
                      result.annualReplacementCost,
                  AppTheme.chartColors[2]),
            ],
            borderSide: isWinner
                ? BorderSide(color: AppTheme.success, width: 2)
                : BorderSide.none,
          ),
        ],
      );
    });
  }

  double _calculateYAxisInterval() {
    final maxCost = _getMaxCost();
    if (maxCost <= 100) return 20;
    if (maxCost <= 500) return 100;
    if (maxCost <= 1000) return 200;
    if (maxCost <= 5000) return 1000;
    if (maxCost <= 10000) return 2000;
    if (maxCost <= 50000) return 10000;
    if (maxCost <= 100000) return 20000;
    return maxCost / 5;
  }
}

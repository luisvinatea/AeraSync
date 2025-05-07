import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'aerator_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../utils/formatting_utils.dart';

class AeratorComparisonCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String winnerLabel;

  const AeratorComparisonCard({
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
              l10n.aeratorComparisonResults,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final isWinner = result.name == winnerLabel;
                return _buildComparisonCard(context, result, isWinner);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
      BuildContext context, AeratorResult result, bool isWinner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: AppTheme.elevationSmall,
      color: isWinner ? Colors.green.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        side: isWinner
            ? BorderSide(color: Colors.green.shade700, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color:
                          isWinner ? Colors.green.shade800 : AppTheme.textDark,
                    ),
                  ),
                ),
                if (isWinner) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          l10n.recommended,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricItem(
                  l10n.unitsNeeded,
                  '${result.numAerators}',
                  Icons.format_list_numbered,
                ),
                _buildMetricItem(
                  l10n.aeratorsPerHaLabel,
                  result.aeratorsPerHa.toStringAsFixed(2),
                  Icons.landscape,
                ),
                _buildMetricItem(
                  l10n.horsepowerPerHaLabel,
                  '${result.hpPerHa.toStringAsFixed(2)} HP/ha',
                  Icons.electric_bolt,
                ),
                _buildMetricItem(
                  l10n.initialCostLabel,
                  FormattingUtils.formatCurrencyK(result.totalInitialCost),
                  Icons.attach_money,
                ),
                _buildMetricItem(
                  l10n.annualCostLabel,
                  FormattingUtils.formatCurrencyK(result.totalAnnualCost),
                  Icons.calendar_today,
                ),
                _buildMetricItem(
                  l10n.costRevenueRatioLabel,
                  '${result.costPercentRevenue.toStringAsFixed(2)}%',
                  Icons.pie_chart,
                ),
                _buildMetricItem(
                  l10n.npvSavingsLabel,
                  FormattingUtils.formatCurrencyK(result.npvSavings),
                  Icons.savings,
                ),
                _buildMetricItem(
                  l10n.paybackPeriod,
                  FormattingUtils.formatPaybackPeriod(result.paybackYears, l10n,
                      isWinner: isWinner),
                  Icons.timelapse,
                ),
                _buildMetricItem(
                  l10n.roiLabel,
                  FormattingUtils.formatROI(result.roiPercent, l10n,
                      isWinner: isWinner),
                  Icons.trending_up,
                ),
                _buildMetricItem(
                  l10n.profitabilityIndexLabel,
                  FormattingUtils.formatProfitabilityK(result.profitabilityK),
                  Icons.auto_graph,
                ),
                _buildMetricItem(
                  l10n.saeLabel,
                  '${result.sae.toStringAsFixed(2)} kg O₂/kWh',
                  Icons.bolt,
                ),
                _buildMetricItem(
                  l10n.costPerKgO2Label,
                  '\$${result.costPerKgO2.toStringAsFixed(3)}/kg O₂',
                  Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 155,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

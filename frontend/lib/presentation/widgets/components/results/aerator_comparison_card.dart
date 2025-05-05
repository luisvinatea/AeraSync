import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/formatting_utils.dart';
import 'aerator_result.dart';

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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.aeratorComparisonResultsDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aeratorComparisonResults,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ...results
                  .map((result) => _buildDetailedResultCard(context, result)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedResultCard(BuildContext context, AeratorResult result) {
    final isWinner = result.name == winnerLabel;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isWinner ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isWinner)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.recommended,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(),
            _detailRow(l10n.unitsNeeded, result.numAerators.toString()),
            _detailRow(l10n.aeratorsPerHaLabel,
                result.aeratorsPerHa.toStringAsFixed(2)),
            _detailRow(l10n.horsepowerPerHaLabel,
                '${result.hpPerHa.toStringAsFixed(2)} hp/ha'),
            _detailRow(l10n.initialCostLabel,
                FormattingUtils.formatCurrencyK(result.totalInitialCost)),
            _detailRow(l10n.annualCostLabel,
                FormattingUtils.formatCurrencyK(result.totalAnnualCost)),
            _detailRow(l10n.costPercentRevenueLabel,
                '${result.costPercentRevenue.toStringAsFixed(2)}%'),
            _detailRow(l10n.annualEnergyCostLabel,
                FormattingUtils.formatCurrencyK(result.annualEnergyCost)),
            _detailRow(l10n.annualMaintenanceCostLabel,
                FormattingUtils.formatCurrencyK(result.annualMaintenanceCost)),
            _detailRow(l10n.annualReplacementCostLabel,
                FormattingUtils.formatCurrencyK(result.annualReplacementCost)),
            if (result.opportunityCost > 0)
              _detailRow(l10n.opportunityCostLabel,
                  FormattingUtils.formatCurrencyK(result.opportunityCost)),
            const Divider(),
            _detailRow(
              l10n.npvSavingsLabel,
              FormattingUtils.formatCurrencyK(result.npvSavings),
            ),
            _detailRow(
                l10n.paybackPeriod,
                FormattingUtils.formatPaybackPeriod(result.paybackYears, l10n,
                    isWinner: isWinner)),
            _detailRow(
                l10n.roiLabel,
                FormattingUtils.formatROI(result.roiPercent, l10n,
                    isWinner: isWinner)),
            _detailRow(
                l10n.irrLabel,
                result.irr <= -100
                    ? l10n.notApplicable
                    : '${result.irr.toStringAsFixed(2)}%'),
            _detailRow(l10n.profitabilityIndexLabel,
                FormattingUtils.formatProfitabilityK(result.profitabilityK)),
            _detailRow(
              l10n.saeLabel,
              '${result.sae.toStringAsFixed(2)} kg O₂/kWh',
              useSubscript: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool useSubscript = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          useSubscript
              ? Builder(
                  builder: (context) => RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: ''),
                        ...FormattingUtils.parseSaeText(value, context),
                      ],
                    ),
                  ),
                )
              : Text(value),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'aerator_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../utils/formatting_utils.dart';

class EnhancedSummaryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final double tod;
  final String winnerLabel;
  final double annualRevenue;
  final Map<String, dynamic>? surveyData;
  final List<AeratorResult> results;

  const EnhancedSummaryCard({
    super.key,
    required this.l10n,
    required this.tod,
    required this.winnerLabel,
    required this.annualRevenue,
    required this.surveyData,
    required this.results,
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
        child: Semantics(
          label: l10n.summaryMetricsDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.summaryMetrics,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyHeadings,
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: AppTheme.paddingSmall),
              // Enhanced styling for total oxygen demand with proper subscript
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: '${l10n.totalDemandLabel}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(text: '${tod.toStringAsFixed(2)} kg '),
                    TextSpan(
                      text: 'O',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.bottom,
                      baseline: TextBaseline.alphabetic,
                      child: Transform.translate(
                        offset: const Offset(0, 2),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 10,
                            height: 0.7,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '/h'),
                  ],
                ),
              ),
              Text(
                '${l10n.annualRevenueLabel}: ${FormattingUtils.formatCurrencyK(annualRevenue)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.recommendedAerator}: $winnerLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
              ),
              const Divider(),
              Text(
                l10n.surveyInputs,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (surveyData != null) ...[
                _buildSurveyInputs(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(l10n.farmAreaLabel,
            surveyData?['farm']?['farm_area_ha']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.shrimpPriceLabel,
            surveyData?['farm']?['shrimp_price']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.cultureDaysLabel,
            surveyData?['farm']?['culture_days']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.shrimpDensityLabel,
            surveyData?['farm']?['shrimp_density_kg_m3']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.pondDepthLabel,
            surveyData?['farm']?['pond_depth_m']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.energyCostLabel,
            surveyData?['financial']?['energy_cost']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.hoursPerNightLabel,
            surveyData?['financial']?['hours_per_night']?.toString() ?? 'N/A'),
        _buildDetailRow(
            l10n.discountRateLabel,
            surveyData?['financial']?['discount_rate'] != null
                ? '${((surveyData!['financial']['discount_rate'] as num) * 100).toStringAsFixed(1)}%'
                : 'N/A'),
        _buildDetailRow(
            l10n.inflationRateLabel,
            surveyData?['financial']?['inflation_rate'] != null
                ? '${((surveyData!['financial']['inflation_rate'] as num) * 100).toStringAsFixed(1)}%'
                : 'N/A'),
        _buildDetailRow(l10n.analysisHorizonLabel,
            surveyData?['financial']?['horizon']?.toString() ?? 'N/A'),
        _buildDetailRow(
            l10n.safetyMarginLabel,
            surveyData?['financial']?['safety_margin'] != null
                ? '${((surveyData!['financial']['safety_margin'] as num) * 100).toStringAsFixed(1)}%'
                : 'N/A'),
        _buildDetailRow(l10n.temperatureLabel,
            surveyData?['financial']?['temperature']?.toString() ?? 'N/A'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: AppTheme.fontSizeMedium,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

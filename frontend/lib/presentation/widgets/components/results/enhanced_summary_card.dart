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
        // Farm specifications section
        _buildSectionHeader(context, l10n.farmSpecs),
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
        _buildDetailRow(l10n.temperatureLabel,
            surveyData?['financial']?['temperature']?.toString() ?? 'N/A'),

        const SizedBox(height: 16),

        // Aerator 1 specifications
        _buildSectionHeader(context, "${l10n.aeratorLabel} 1"),
        _buildDetailRow(l10n.nameLabel,
            surveyData?['aerator1']?['name']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.powerLabel,
            '${surveyData?['aerator1']?['power_hp']?.toString() ?? 'N/A'} HP'),
        _buildDetailRow(l10n.sotrLabel,
            '${surveyData?['aerator1']?['sotr']?.toString() ?? 'N/A'} kg O₂/h'),
        _buildDetailRow(l10n.costLabel,
            '\$${surveyData?['aerator1']?['cost']?.toString() ?? 'N/A'}'),
        _buildDetailRow(l10n.durabilityLabel,
            '${surveyData?['aerator1']?['durability']?.toString() ?? 'N/A'} ${l10n.years}'),
        _buildDetailRow(l10n.maintenanceLabel,
            '\$${surveyData?['aerator1']?['maintenance']?.toString() ?? 'N/A'}/${l10n.year}'),

        const SizedBox(height: 16),

        // Aerator 2 specifications
        _buildSectionHeader(context, "${l10n.aeratorLabel} 2"),
        _buildDetailRow(l10n.nameLabel,
            surveyData?['aerator2']?['name']?.toString() ?? 'N/A'),
        _buildDetailRow(l10n.powerLabel,
            '${surveyData?['aerator2']?['power_hp']?.toString() ?? 'N/A'} HP'),
        _buildDetailRow(l10n.sotrLabel,
            '${surveyData?['aerator2']?['sotr']?.toString() ?? 'N/A'} kg O₂/h'),
        _buildDetailRow(l10n.costLabel,
            '\$${surveyData?['aerator2']?['cost']?.toString() ?? 'N/A'}'),
        _buildDetailRow(l10n.durabilityLabel,
            '${surveyData?['aerator2']?['durability']?.toString() ?? 'N/A'} ${l10n.years}'),
        _buildDetailRow(l10n.maintenanceLabel,
            '\$${surveyData?['aerator2']?['maintenance']?.toString() ?? 'N/A'}/${l10n.year}'),

        const SizedBox(height: 16),

        // Financial aspects section
        _buildSectionHeader(context, l10n.financialAspects),
        _buildDetailRow(l10n.energyCostLabel,
            '\$${surveyData?['financial']?['energy_cost']?.toString() ?? 'N/A'}/kWh'),
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
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
      ),
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

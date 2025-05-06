import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'survey_form_field.dart';

class FinancialDetailsFormSection extends StatelessWidget {
  // Financial inputs
  final TextEditingController energyCostController;
  final TextEditingController hoursPerNightController;
  final TextEditingController discountRateController;
  final TextEditingController inflationRateController;
  final TextEditingController horizonController;
  final TextEditingController safetyMarginController;

  const FinancialDetailsFormSection({
    super.key,
    required this.energyCostController,
    required this.hoursPerNightController,
    required this.discountRateController,
    required this.inflationRateController,
    required this.horizonController,
    required this.safetyMarginController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - First half of financial inputs
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurveyFormField(
                controller: energyCostController,
                label: l10n.energyCostLabel,
                suffix: 'USD/kWh',
                min: 0.0,
                max: 2.0,
                hint: '0.05',
                isNumeric: true,
              ),
              SurveyFormField(
                controller: hoursPerNightController,
                label: l10n.hoursPerNightLabel,
                suffix: 'hours',
                min: 1,
                max: 24,
                hint: '8',
                isNumeric: true,
                step: 1.0,
                decimals: 0,
              ),
              SurveyFormField(
                controller: discountRateController,
                label: l10n.discountRateLabel,
                suffix: '%',
                min: 0.0,
                max: 100.0,
                hint: '10.0',
                isNumeric: true,
              ),
            ],
          ),
        ),

        // Right column - Second half of financial inputs
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurveyFormField(
                controller: inflationRateController,
                label: l10n.inflationRateLabel,
                suffix: '%',
                min: 0.0,
                max: 100.0,
                hint: '3.0',
                isNumeric: true,
              ),
              SurveyFormField(
                controller: horizonController,
                label: l10n.analysisHorizonLabel,
                suffix: 'years',
                min: 1,
                max: 50,
                hint: '9',
                isNumeric: true,
                step: 1.0,
                decimals: 0,
              ),
              SurveyFormField(
                controller: safetyMarginController,
                label: l10n.safetyMarginLabel,
                suffix: '%',
                required: false,
                min: 0.0,
                max: 100.0,
                hint: '0',
                isNumeric: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

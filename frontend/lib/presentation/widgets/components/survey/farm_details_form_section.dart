import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'survey_form_field.dart';

class FarmDetailsFormSection extends StatelessWidget {
  // Farm inputs
  final TextEditingController todController;
  final TextEditingController farmAreaController;
  final TextEditingController shrimpPriceController;
  final TextEditingController cultureDaysController;
  final TextEditingController shrimpDensityController;
  final TextEditingController pondDepthController;
  final TextEditingController? temperatureController;

  // Financial inputs - removed from this component
  final TextEditingController? energyCostController;
  final TextEditingController? hoursPerNightController;
  final TextEditingController? discountRateController;
  final TextEditingController? inflationRateController;
  final TextEditingController? horizonController;
  final TextEditingController? safetyMarginController;

  const FarmDetailsFormSection({
    super.key,
    required this.todController,
    required this.farmAreaController,
    required this.shrimpPriceController,
    required this.cultureDaysController,
    required this.shrimpDensityController,
    required this.pondDepthController,
    this.temperatureController,
    // Make financial controllers optional since they're not used in this view anymore
    this.energyCostController,
    this.hoursPerNightController,
    this.discountRateController,
    this.inflationRateController,
    this.horizonController,
    this.safetyMarginController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - First half of farm inputs
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurveyFormField(
                controller: todController,
                label: l10n.totalOxygenDemand,
                suffix: 'kg O₂/h',
                min: 0,
                max: 100000.0,
                hint: '5000',
                isNumeric: true,
                step: 1,
                decimals: 0,
              ),
              SurveyFormField(
                controller: farmAreaController,
                label: l10n.farmAreaLabel,
                suffix: 'ha',
                min: 0.1,
                max: 10000.0,
                hint: '1000',
                isNumeric: true,
                step: 10,
                decimals: 0,
              ),
              SurveyFormField(
                controller: shrimpPriceController,
                label: l10n.shrimpPriceLabel,
                suffix: 'USD/kg',
                min: 0.1,
                max: 100.0,
                hint: '5.0',
                isNumeric: true,
              ),
            ],
          ),
        ),

        // Right column - Second half of farm inputs
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurveyFormField(
                controller: cultureDaysController,
                label: l10n.cultureDaysLabel,
                suffix: 'days',
                min: 30,
                max: 365,
                hint: '120',
                isNumeric: true,
                step: 1.0,
                decimals: 0,
              ),
              SurveyFormField(
                controller: shrimpDensityController,
                label: l10n.shrimpDensityLabel,
                suffix: 'kg/m³',
                min: 0.1,
                max: 10.0,
                hint: '0.33',
                isNumeric: true,
              ),
              SurveyFormField(
                controller: pondDepthController,
                label: l10n.pondDepthLabel,
                suffix: 'm',
                min: 0.1,
                max: 5.0,
                hint: '1.0',
                isNumeric: true,
              ),
              if (temperatureController != null)
                SurveyFormField(
                  controller: temperatureController!,
                  label: l10n.temperatureLabel,
                  suffix: '°C',
                  min: 0.0,
                  max: 50.0,
                  hint: '31.5',
                  isNumeric: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

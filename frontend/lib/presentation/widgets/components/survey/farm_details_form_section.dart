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

  // Financial inputs
  final TextEditingController energyCostController;
  final TextEditingController hoursPerNightController;
  final TextEditingController discountRateController;
  final TextEditingController inflationRateController;
  final TextEditingController horizonController;
  final TextEditingController safetyMarginController;
  final TextEditingController temperatureController;

  const FarmDetailsFormSection({
    super.key,
    required this.todController,
    required this.farmAreaController,
    required this.shrimpPriceController,
    required this.cultureDaysController,
    required this.shrimpDensityController,
    required this.pondDepthController,
    required this.energyCostController,
    required this.hoursPerNightController,
    required this.discountRateController,
    required this.inflationRateController,
    required this.horizonController,
    required this.safetyMarginController,
    required this.temperatureController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Farm details
        SurveyFormField(
          controller: todController,
          label: l10n.totalOxygenDemand,
          suffix: 'kg O₂/h',
          min: 0.1,
          hint: '5443.76',
        ),
        SurveyFormField(
          controller: farmAreaController,
          label: l10n.farmAreaLabel,
          suffix: 'ha',
          min: 0.1,
          max: 10000.0,
          hint: '1000',
        ),
        SurveyFormField(
          controller: shrimpPriceController,
          label: l10n.shrimpPriceLabel,
          suffix: 'USD/kg',
          min: 0.1,
          max: 100.0,
          hint: '5.0',
        ),
        SurveyFormField(
          controller: cultureDaysController,
          label: l10n.cultureDaysLabel,
          suffix: 'days',
          min: 30,
          max: 365,
          hint: '120',
        ),
        SurveyFormField(
          controller: shrimpDensityController,
          label: l10n.shrimpDensityLabel,
          suffix: 'kg/m³',
          min: 0.1,
          max: 10.0,
          hint: '0.33',
        ),
        SurveyFormField(
          controller: pondDepthController,
          label: l10n.pondDepthLabel,
          suffix: 'm',
          min: 0.1,
          max: 5.0,
          hint: '1.0',
        ),

        // Financial details
        SurveyFormField(
          controller: energyCostController,
          label: l10n.energyCostLabel,
          suffix: 'USD/kWh',
          min: 0.0,
          max: 2.0,
          hint: '0.05',
        ),
        SurveyFormField(
          controller: hoursPerNightController,
          label: l10n.hoursPerNightLabel,
          suffix: 'hours',
          min: 1,
          max: 24,
          hint: '8',
        ),
        SurveyFormField(
          controller: discountRateController,
          label: l10n.discountRateLabel,
          suffix: '%',
          min: 0.0,
          max: 100.0,
          hint: '10.0',
        ),
        SurveyFormField(
          controller: inflationRateController,
          label: l10n.inflationRateLabel,
          suffix: '%',
          min: 0.0,
          max: 100.0,
          hint: '3.0',
        ),
        SurveyFormField(
          controller: horizonController,
          label: l10n.analysisHorizonLabel,
          suffix: 'years',
          min: 1,
          max: 50,
          hint: '9',
        ),
        SurveyFormField(
          controller: safetyMarginController,
          label: l10n.safetyMarginLabel,
          suffix: '%',
          required: false,
          min: 0.0,
          max: 100.0,
          hint: '0',
        ),
        SurveyFormField(
          controller: temperatureController,
          label: l10n.temperatureLabel,
          suffix: '°C',
          min: 0.0,
          max: 50.0,
          hint: '31.5',
        ),
      ],
    );
  }
}

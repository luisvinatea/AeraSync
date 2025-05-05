import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'survey_form_field.dart';

class AeratorFormSection extends StatelessWidget {
  final String aeratorNumber;
  final TextEditingController nameController;
  final TextEditingController powerController;
  final TextEditingController sotrController;
  final TextEditingController costController;
  final TextEditingController durabilityController;
  final TextEditingController maintenanceController;

  const AeratorFormSection({
    super.key,
    required this.aeratorNumber,
    required this.nameController,
    required this.powerController,
    required this.sotrController,
    required this.costController,
    required this.durabilityController,
    required this.maintenanceController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "${l10n.aeratorLabel} $aeratorNumber",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SurveyFormField(
          controller: nameController,
          label: l10n.nameLabel,
          isNumeric: false,
        ),
        SurveyFormField(
          controller: powerController,
          label: l10n.horsepowerLabel,
          suffix: 'hp',
          min: 0.1,
          max: 100,
          hint: '3.0',
        ),
        SurveyFormField(
          controller: sotrController,
          label: l10n.sotrLabel,
          suffix: 'kg O₂/h',
          min: 0.1,
          max: 100,
          hint: '1.4',
        ),
        SurveyFormField(
          controller: costController,
          label: l10n.priceLabel,
          suffix: 'USD',
          min: 0,
          max: 50000,
          hint: '500',
        ),
        SurveyFormField(
          controller: durabilityController,
          label: l10n.durabilityLabel,
          suffix: 'years',
          min: 0.1,
          max: 50,
          hint: '2',
        ),
        SurveyFormField(
          controller: maintenanceController,
          label: l10n.maintenanceCostLabel,
          suffix: 'USD/year',
          min: 0,
          max: 10000,
          hint: '65',
        ),
      ],
    );
  }
}

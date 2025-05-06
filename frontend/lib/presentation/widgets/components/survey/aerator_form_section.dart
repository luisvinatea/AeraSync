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

  // Fix the scrollKey parameter by adding a default value
  final Key? scrollKey;

  const AeratorFormSection({
    super.key,
    this.scrollKey,
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

    return Container(
      key: scrollKey,
      margin: EdgeInsets.only(left: aeratorNumber == "2" ? 16.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              "${l10n.aeratorLabel} $aeratorNumber",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 62, 132, 238),
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
              label: l10n.powerLabel,
              suffix: 'HP',
              min: 1,
              max: 100,
              hint: '3.0',
              isNumeric: true,
              step: 0.5,
              decimals: 1),
          SurveyFormField(
            controller: sotrController,
            label: l10n.sotrLabel,
            suffix: 'kg O₂/h',
            min: 0.1,
            max: 100,
            hint: '10.0',
            isNumeric: true,
            step: 0.1,
            decimals: 1,
          ),
          SurveyFormField(
            controller: costController,
            label: l10n.costLabel,
            suffix: 'USD',
            min: 0.1,
            max: 100000,
            hint: '500',
            isNumeric: true,
            step: 1.0,
            decimals: 0,
          ),
          SurveyFormField(
            controller: durabilityController,
            label: l10n.durabilityLabel,
            suffix: 'years',
            min: 0.1,
            max: 50,
            hint: '2',
            isNumeric: true,
            step: 1.0,
            decimals: 0,
          ),
          SurveyFormField(
            controller: maintenanceController,
            label: l10n.maintenanceLabel,
            suffix: 'USD/year',
            min: 0.0,
            max: 10000,
            hint: '50',
            isNumeric: true,
            step: 1.0,
            decimals: 0,
          ),
        ],
      ),
    );
  }
}

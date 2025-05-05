import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SurveyFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool required;
  final double? min;
  final double? max;
  final String? hint;
  final bool isNumeric;

  const SurveyFormField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.required = true,
    this.min,
    this.max,
    this.hint,
    this.isNumeric = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label + (required ? '' : ' (${l10n.optionalField})'),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: Colors.white),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.blue.shade900.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }

                if (isNumeric) {
                  final numValue = double.tryParse(value);
                  if (numValue == null) {
                    return l10n.invalidNumber;
                  }
                  if (min != null && numValue < min!) {
                    return l10n.minimumValueError('$min');
                  }
                  if (max != null && numValue > max!) {
                    return l10n.rangeError('$min', '$max');
                  }
                }
                return null;
              }
            : null,
      ),
    );
  }
}

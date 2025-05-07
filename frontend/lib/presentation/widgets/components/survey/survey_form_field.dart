import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class SurveyFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool required;
  final double? min;
  final double? max;
  final String? hint;
  final bool isNumeric;
  final double step;
  final int decimals;

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
    this.step = 0.1,
    this.decimals = 2,
  });

  @override
  State<SurveyFormField> createState() => _SurveyFormFieldState();
}

class _SurveyFormFieldState extends State<SurveyFormField> {
  double currentValue = 0;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    currentValue = double.tryParse(widget.controller.text) ?? widget.min ?? 0;
    widget.controller.addListener(() {
      final value = double.tryParse(widget.controller.text);
      if (value != null && value != currentValue && _isMounted) {
        if (mounted) {
          setState(() {
            currentValue = value;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: widget.isNumeric && widget.min != null && widget.max != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: widget.controller,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: widget.isNumeric
                        ? AppTheme.fontFamilyNumbers
                        : AppTheme.fontFamilyBody,
                  ),
                  cursorColor: AppTheme.textPrimary,
                  decoration: InputDecoration(
                    labelText: widget.label +
                        (widget.required ? '' : ' (${l10n.optionalField})'),
                    labelStyle: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    suffixText: widget.suffix,
                    suffixStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold),
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppTheme.inputBackground,
                    errorStyle: TextStyle(
                        color: AppTheme.error,
                        fontSize: AppTheme.fontSizeSmall),
                    errorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide: BorderSide(color: AppTheme.error, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide: BorderSide(color: AppTheme.error, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingLarge,
                        vertical: AppTheme.paddingMedium),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide:
                          BorderSide(color: AppTheme.inputBorder, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide:
                          BorderSide(color: AppTheme.inputBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide:
                          BorderSide(color: AppTheme.inputFocused, width: 2),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: widget.required
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.requiredField;
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null) return l10n.invalidNumber;
                          if (widget.min != null && numValue < widget.min!) {
                            return l10n.minimumValueError('${widget.min}');
                          }
                          if (widget.max != null && numValue > widget.max!) {
                            return l10n.rangeError(
                                '${widget.min}', '${widget.max}');
                          }
                          return null;
                        }
                      : null,
                ),
                Slider(
                  value: currentValue.clamp(widget.min!, widget.max!),
                  min: widget.min!,
                  max: widget.max!,
                  divisions:
                      ((widget.max! - widget.min!) / widget.step).round(),
                  activeColor: AppTheme.sliderActive,
                  inactiveColor: AppTheme.sliderInactive,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        currentValue = value;
                        widget.controller.text =
                            value.toStringAsFixed(widget.decimals);
                      });
                    }
                  },
                ),
              ],
            )
          : TextFormField(
              controller: widget.controller,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: widget.isNumeric
                    ? AppTheme.fontFamilyNumbers
                    : AppTheme.fontFamilyBody,
              ),
              cursorColor: AppTheme.textPrimary,
              decoration: InputDecoration(
                labelText: widget.label +
                    (widget.required ? '' : ' (${l10n.optionalField})'),
                labelStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                suffixText: widget.suffix,
                suffixStyle: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                hintText: widget.hint,
                hintStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppTheme.inputBackground,
                errorStyle: TextStyle(
                    color: AppTheme.error, fontSize: AppTheme.fontSizeSmall),
                errorBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.error, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.error, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingLarge,
                    vertical: AppTheme.paddingMedium),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.inputBorder, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.inputBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide:
                      BorderSide(color: AppTheme.inputFocused, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
    );
  }
}

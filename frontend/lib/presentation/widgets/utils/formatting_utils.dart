import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Utility class for formatting values consistently across the app
class FormattingUtils {
  /// Format currency value with K/M suffix for better readability
  static String formatCurrencyK(double value) {
    if (value >= 1_000_000) {
      return '\$${(value / 1_000_000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(2)}K';
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Format payback period based on years value
  static String formatPaybackPeriod(double paybackYears, AppLocalizations l10n,
      {bool isWinner = false}) {
    if (paybackYears < 0 ||
        paybackYears == double.infinity ||
        paybackYears > 100) {
      if (isWinner) {
        return '< 1 ${l10n.year}';
      }
      return l10n.notApplicable;
    }

    if (paybackYears < 0.0822) {
      final days = (paybackYears * 365).round();
      return '$days ${l10n.days}';
    }

    if (paybackYears < 1) {
      final months = (paybackYears * 12).round();
      return '$months ${l10n.months}';
    }

    return '${paybackYears.toStringAsFixed(1)} ${l10n.years}';
  }

  /// Format ROI percentage with proper suffixes
  static String formatROI(double roi, AppLocalizations l10n,
      {bool isWinner = false}) {
    if (roi <= 0 && !isWinner) {
      return l10n.notApplicable;
    }

    if (roi >= 1000) {
      if (roi >= 1000000) {
        return '${(roi / 1000000).toStringAsFixed(2)}M%';
      }
      return '${(roi / 1000).toStringAsFixed(2)}K%';
    }

    return '${roi.toStringAsFixed(2)}%';
  }

  /// Format profitability index with K/M suffix
  static String formatProfitabilityK(double k) {
    if (k >= 1_000_000) return '${(k / 1_000_000).toStringAsFixed(2)}M';
    if (k >= 1000) return '${(k / 1000).toStringAsFixed(2)}K';
    return k.toStringAsFixed(2);
  }

  /// Parse and format text containing O₂ subscripts
  static List<InlineSpan> parseSaeText(String text, BuildContext context) {
    final List<InlineSpan> spans = [];
    // Match typical scientific notation with subscripts like O₂ or kg O₂/kWh
    final RegExp pattern = RegExp(r'O2|O₂');

    // Split text at each occurrence of oxygen notation
    final parts = text.split(pattern);

    for (int i = 0; i < parts.length; i++) {
      // Add the text before O2
      spans.add(TextSpan(text: parts[i]));

      // Add O2 with proper subscript (except after the last part)
      if (i < parts.length - 1) {
        spans.add(TextSpan(text: 'O'));
        spans.add(
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
        );
      }
    }

    return spans;
  }

  /// Helper method to create a TextStyle with proper font fallbacks for subscript characters
  static TextStyle getSubscriptTextStyle(BuildContext context,
      {TextStyle? baseStyle}) {
    // Add specific fonts that support Unicode subscripts
    final fallbackFonts = [
      'Noto Sans',
      'Noto Serif',
      'Roboto',
      'DejaVu Sans',
      'Arial Unicode MS',
      'Symbola'
    ];
    return (baseStyle ?? Theme.of(context).textTheme.bodyMedium!).copyWith(
      fontFamilyFallback: fallbackFonts,
      fontFeatures: const [FontFeature.subscripts()],
    );
  }
}

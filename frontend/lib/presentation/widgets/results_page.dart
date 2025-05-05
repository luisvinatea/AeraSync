import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/app_state.dart';
import 'dart:typed_data';

/// Helper method to create a TextStyle with proper font fallbacks for subscript characters
TextStyle getSubscriptTextStyle(BuildContext context, {TextStyle? baseStyle}) {
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

class AeratorResult {
  final String name;
  final int numAerators;
  final double totalPowerHp;
  final double totalInitialCost;
  final double annualEnergyCost;
  final double annualMaintenanceCost;
  final double annualReplacementCost;
  final double totalAnnualCost;
  final double costPercentRevenue;
  final double npvSavings;
  final double paybackYears;
  final double roiPercent;
  final double irr;
  final double profitabilityK;
  final double aeratorsPerHa;
  final double hpPerHa;
  final double sae;
  final double opportunityCost;

  AeratorResult({
    required this.name,
    required this.numAerators,
    required this.totalPowerHp,
    required this.totalInitialCost,
    required this.annualEnergyCost,
    required this.annualMaintenanceCost,
    required this.annualReplacementCost,
    required this.totalAnnualCost,
    required this.costPercentRevenue,
    required this.npvSavings,
    required this.paybackYears,
    required this.roiPercent,
    required this.irr,
    required this.profitabilityK,
    required this.aeratorsPerHa,
    required this.hpPerHa,
    required this.sae,
    required this.opportunityCost,
  });

  factory AeratorResult.fromJson(Map<String, dynamic> json) {
    return AeratorResult(
      name: json['name'] ?? 'Unknown',
      numAerators: json['num_aerators'] is int
          ? json['num_aerators']
          : (json['num_aerators'] as num?)?.toInt() ?? 0,
      totalPowerHp: (json['total_power_hp'] as num?)?.toDouble() ?? 0.0,
      totalInitialCost: (json['total_initial_cost'] as num?)?.toDouble() ?? 0.0,
      annualEnergyCost: (json['annual_energy_cost'] as num?)?.toDouble() ?? 0.0,
      annualMaintenanceCost:
          (json['annual_maintenance_cost'] as num?)?.toDouble() ?? 0.0,
      annualReplacementCost:
          (json['annual_replacement_cost'] as num?)?.toDouble() ?? 0.0,
      totalAnnualCost: (json['total_annual_cost'] as num?)?.toDouble() ?? 0.0,
      costPercentRevenue:
          (json['cost_percent_revenue'] as num?)?.toDouble() ?? 0.0,
      npvSavings: (json['npv_savings'] as num?)?.toDouble() ?? 0.0,
      paybackYears:
          (json['payback_years'] as num?)?.toDouble() ?? double.infinity,
      roiPercent: (json['roi_percent'] as num?)?.toDouble() ?? 0.0,
      irr: (json['irr'] as num?)?.toDouble() ?? -100.0,
      profitabilityK: (json['profitability_k'] as num?)?.toDouble() ?? 0.0,
      aeratorsPerHa: (json['aerators_per_ha'] as num?)?.toDouble() ?? 0.0,
      hpPerHa: (json['hp_per_ha'] as num?)?.toDouble() ?? 0.0,
      sae: (json['sae'] as num?)?.toDouble() ?? 0.0,
      opportunityCost: (json['opportunity_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String formatCurrencyK(double value) {
    if (value >= 1_000_000) {
      return '\$${(value / 1_000_000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(2)}K';
    return '\$${value.toStringAsFixed(2)}';
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  static String formatCurrencyK(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  Future<Uint8List> _generatePdf(
      AppLocalizations l10n,
      List<AeratorResult> results,
      String winnerLabel,
      double tod,
      double annualRevenue,
      Map<String, dynamic>? surveyData) async {
    final pdf = pw.Document();

    // Load fonts first before using them
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final notoSansFont = await PdfGoogleFonts.notoSansRegular();
    final notoSerifFont = await PdfGoogleFonts.notoSerifRegular();
    final notoSerifBlackFont = await PdfGoogleFonts.notoSerifBlack();

    // Create a theme for consistent styling
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );

    // Prepare all survey input table rows
    final surveyInputRows = <pw.TableRow>[];

    if (surveyData != null) {
      // Farm data
      surveyInputRows.add(_createPdfTableRow(l10n.farmAreaLabel,
          surveyData['farm']?['farm_area_ha']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.shrimpPriceLabel,
          surveyData['farm']?['shrimp_price']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.cultureDaysLabel,
          surveyData['farm']?['culture_days']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.shrimpDensityLabel,
          surveyData['farm']?['shrimp_density_kg_m3']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.pondDepthLabel,
          surveyData['farm']?['pond_depth_m']?.toString() ?? 'N/A'));

      // Financial data
      surveyInputRows.add(_createPdfTableRow(l10n.energyCostLabel,
          surveyData['financial']?['energy_cost']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.hoursPerNightLabel,
          surveyData['financial']?['hours_per_night']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(
          l10n.discountRateLabel,
          surveyData['financial']?['discount_rate'] != null
              ? '${((surveyData['financial']['discount_rate'] as num) * 100).toStringAsFixed(1)}%'
              : 'N/A'));

      surveyInputRows.add(_createPdfTableRow(
          l10n.inflationRateLabel,
          surveyData['financial']?['inflation_rate'] != null
              ? '${((surveyData['financial']['inflation_rate'] as num) * 100).toStringAsFixed(1)}%'
              : 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.analysisHorizonLabel,
          surveyData['financial']?['horizon']?.toString() ?? 'N/A'));

      surveyInputRows.add(_createPdfTableRow(
          l10n.safetyMarginLabel,
          surveyData['financial']?['safety_margin'] != null
              ? '${((surveyData['financial']['safety_margin'] as num) * 100).toStringAsFixed(1)}%'
              : 'N/A'));

      surveyInputRows.add(_createPdfTableRow(l10n.temperatureLabel,
          surveyData['financial']?['temperature']?.toString() ?? 'N/A'));
    }

    // Pre-generate all detail rows for each result
    final detailSections = results.map((result) {
      final isWinner = result.name == winnerLabel;

      // Create table rows for each detail
      final detailRows = [
        _createPdfTableRow(l10n.unitsNeeded, result.numAerators.toString()),
        _createPdfTableRow(
            l10n.aeratorsPerHaLabel, result.aeratorsPerHa.toStringAsFixed(2)),
        _createPdfTableRow(l10n.horsepowerPerHaLabel,
            '${result.hpPerHa.toStringAsFixed(2)} hp/ha'),
        _createPdfTableRow(l10n.initialCostLabel,
            ResultsPage.formatCurrencyK(result.totalInitialCost)),
        _createPdfTableRow(l10n.annualCostLabel,
            ResultsPage.formatCurrencyK(result.totalAnnualCost)),
        _createPdfTableRow(l10n.costPercentRevenueLabel,
            '${result.costPercentRevenue.toStringAsFixed(2)}%'),
        _createPdfTableRow(l10n.npvSavingsLabel,
            ResultsPage.formatCurrencyK(result.npvSavings)),
        _createPdfTableRow(
            l10n.saeLabel, '${result.sae.toStringAsFixed(2)} kg O₂/kWh',
            useSubscriptFont: true,
            notoSerifBlackFont: notoSerifBlackFont,
            notoSerifFont: notoSerifFont),
      ];

      // Create cost breakdown rows
      final costBreakdownRows = [
        _createPdfTableRow(l10n.annualEnergyCostLabel,
            ResultsPage.formatCurrencyK(result.annualEnergyCost)),
        _createPdfTableRow(l10n.annualMaintenanceCostLabel,
            ResultsPage.formatCurrencyK(result.annualMaintenanceCost)),
        _createPdfTableRow(l10n.annualReplacementCostLabel,
            ResultsPage.formatCurrencyK(result.annualReplacementCost)),
      ];

      if (result.opportunityCost > 0) {
        costBreakdownRows.add(_createPdfTableRow(l10n.opportunityCostLabel,
            ResultsPage.formatCurrencyK(result.opportunityCost)));
      }

      // Financial metrics rows
      final financialMetricsRows = [
        _createPdfTableRow(
            l10n.paybackPeriod,
            _formatPaybackPeriodForPdf(result.paybackYears, l10n,
                isWinner: isWinner)),
        _createPdfTableRow(l10n.roiLabel,
            _formatROIForPdf(result.roiPercent, l10n, isWinner: isWinner)),
        _createPdfTableRow(
            l10n.irrLabel,
            result.irr <= -100
                ? l10n.notApplicable
                : '${result.irr.toStringAsFixed(2)}%'),
        _createPdfTableRow(l10n.profitabilityIndexLabel,
            _formatProfitabilityKForPdf(result.profitabilityK)),
      ];

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
              color: isWinner ? PdfColors.green : PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
          color: isWinner ? PdfColors.green50 : PdfColors.white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  result.name,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: isWinner ? PdfColors.green800 : PdfColors.grey800),
                ),
                if (isWinner)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green700,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      l10n.recommended,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            pw.Divider(),
            pw.Text(
              l10n.mainMetrics,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: detailRows,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              l10n.costBreakdownVisualization,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: costBreakdownRows,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              l10n.financialMetrics,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: financialMetricsRows,
            ),
          ],
        ),
      );
    }).toList();

    // Create simple bar chart for cost visualization
    final costChartSection = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.costBreakdownVisualization,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Simple table representation of cost breakdown
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Name
              1: const pw.FlexColumnWidth(1.5), // Energy
              2: const pw.FlexColumnWidth(1.5), // Maintenance
              3: const pw.FlexColumnWidth(1.5), // Replacement
              4: const pw.FlexColumnWidth(1.5), // Total
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(l10n.aerator,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(l10n.energyCostLabel,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(l10n.maintenanceCostLabel,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(l10n.replacementCostLabel,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(l10n.totalLabel,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Data rows for each aerator
              ...results.map((result) {
                final isWinner = result.name == winnerLabel;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isWinner ? PdfColors.green50 : PdfColors.white,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        result.name,
                        style: isWinner
                            ? pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800)
                            : null,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                          ResultsPage.formatCurrencyK(result.annualEnergyCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(ResultsPage.formatCurrencyK(
                          result.annualMaintenanceCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(ResultsPage.formatCurrencyK(
                          result.annualReplacementCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        ResultsPage.formatCurrencyK(result.annualEnergyCost +
                            result.annualMaintenanceCost +
                            result.annualReplacementCost),
                        style: isWinner
                            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                            : null,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'AeraSync: ${l10n.aeratorComparisonResults}',
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l10n.summaryMetrics,
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${l10n.totalDemandLabel}: ${tod.toStringAsFixed(2)} kg O₂/h',
                    style: pw.TextStyle(
                      font: notoSansFont,
                      fontFallback: [notoSerifFont],
                    ),
                  ),
                  pw.Text(
                      '${l10n.annualRevenueLabel}: ${ResultsPage.formatCurrencyK(annualRevenue)}'),
                  pw.Text(
                    '${l10n.recommendedAerator}: $winnerLabel',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    l10n.surveyInputs,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  if (surveyData != null)
                    pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(1),
                      },
                      children: surveyInputRows,
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Comparison details section
            ...detailSections,

            pw.SizedBox(height: 20),

            // Cost breakdown visualization
            costChartSection,

            pw.SizedBox(height: 20),

            // Footer note
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated by AeraSync on ${DateTime.now().toString().substring(0, 10)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.TableRow _createPdfTableRow(String label, String value,
      {bool useSubscriptFont = false,
      pw.Font? notoSerifBlackFont,
      pw.Font? notoSerifFont}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value,
              style: useSubscriptFont &&
                      notoSerifBlackFont != null &&
                      notoSerifFont != null
                  ? pw.TextStyle(
                      font: notoSerifBlackFont,
                      fontFallback: [notoSerifFont],
                    )
                  : null),
        ),
      ],
    );
  }

  String _formatPaybackPeriodForPdf(double paybackYears, AppLocalizations l10n,
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

  String _formatROIForPdf(double roi, AppLocalizations l10n,
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

  String _formatProfitabilityKForPdf(double k) {
    if (k >= 1_000_000) return '${(k / 1_000_000).toStringAsFixed(2)}M';
    if (k >= 1000) return '${(k / 1000).toStringAsFixed(2)}K';
    return k.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final apiResults = appState.apiResults;

    if (apiResults == null || !apiResults.containsKey('aeratorResults')) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.results),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  l10n.noDataAvailable,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/survey'),
                  child: Text(l10n.returnToSurvey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final results = (apiResults['aeratorResults'] as List<dynamic>)
        .map((json) => AeratorResult.fromJson(json))
        .toList();
    final winnerLabel = apiResults['winnerLabel'] as String? ?? 'None';
    final tod = (apiResults['tod'] as num?)?.toDouble() ?? 0.0;
    final annualRevenue =
        (apiResults['annual_revenue'] as num?)?.toDouble() ?? 0.0;
    final equilibriumPrices =
        apiResults['equilibriumPrices'] as Map<String, dynamic>? ?? {};
    final surveyData = apiResults['surveyData'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.results),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EnhancedSummaryCard(
                              l10n: l10n,
                              tod: tod,
                              winnerLabel: winnerLabel,
                              annualRevenue: annualRevenue,
                              surveyData: surveyData,
                              results: results,
                            ),
                            const SizedBox(height: 16),
                            _AeratorComparisonCard(
                              l10n: l10n,
                              results: results,
                              winnerLabel: winnerLabel,
                            ),
                            const SizedBox(height: 16),
                            _EquilibriumPricesCard(
                              l10n: l10n,
                              equilibriumPrices: equilibriumPrices,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _CostVisualizationCard(
                              l10n: l10n,
                              results: results,
                              winnerLabel: winnerLabel,
                            ),
                            const SizedBox(height: 16),
                            _CostEvolutionCard(
                              l10n: l10n,
                              results: results,
                              winnerLabel: winnerLabel,
                              surveyData: surveyData,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  onPressed: () => appState.navigateToSurvey(),
                  child: Text(l10n.newComparison),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  onPressed: () async {
                    final pdfData = await _generatePdf(l10n, results,
                        winnerLabel, tod, annualRevenue, surveyData);
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async => pdfData,
                    );
                  },
                  child: Text(l10n.exportToPdf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedSummaryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final double tod;
  final String winnerLabel;
  final double annualRevenue;
  final Map<String, dynamic>? surveyData;
  final List<AeratorResult> results;

  const _EnhancedSummaryCard({
    required this.l10n,
    required this.tod,
    required this.winnerLabel,
    required this.annualRevenue,
    required this.surveyData,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildDetailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.summaryMetricsDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.summaryMetrics,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
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
                        child: Text(
                          '2',
                          style: const TextStyle(
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
                '${l10n.annualRevenueLabel}: ${ResultsPage.formatCurrencyK(annualRevenue)}',
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
                buildDetailRow(
                  l10n.farmAreaLabel,
                  surveyData?['farm']?['farm_area_ha']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.shrimpPriceLabel,
                  surveyData?['farm']?['shrimp_price']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.cultureDaysLabel,
                  surveyData?['farm']?['culture_days']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.shrimpDensityLabel,
                  surveyData?['farm']?['shrimp_density_kg_m3']?.toString() ??
                      'N/A',
                ),
                buildDetailRow(
                  l10n.pondDepthLabel,
                  surveyData?['farm']?['pond_depth_m']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.energyCostLabel,
                  surveyData?['financial']?['energy_cost']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.hoursPerNightLabel,
                  surveyData?['financial']?['hours_per_night']?.toString() ??
                      'N/A',
                ),
                buildDetailRow(
                  l10n.discountRateLabel,
                  surveyData?['financial']?['discount_rate'] != null
                      ? '${((surveyData?['financial']['discount_rate'] as num) * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                ),
                buildDetailRow(
                  l10n.inflationRateLabel,
                  surveyData?['financial']?['inflation_rate'] != null
                      ? '${((surveyData?['financial']['inflation_rate'] as num) * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                ),
                buildDetailRow(
                  l10n.analysisHorizonLabel,
                  surveyData?['financial']?['horizon']?.toString() ?? 'N/A',
                ),
                buildDetailRow(
                  l10n.safetyMarginLabel,
                  surveyData?['financial']?['safety_margin'] != null
                      ? '${((surveyData?['financial']['safety_margin'] as num) * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                ),
                buildDetailRow(
                  l10n.temperatureLabel,
                  surveyData?['financial']?['temperature']?.toString() ?? 'N/A',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AeratorComparisonCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String winnerLabel;

  const _AeratorComparisonCard({
    required this.l10n,
    required this.results,
    required this.winnerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.aeratorComparisonResultsDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aeratorComparisonResults,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ...results
                  .map((result) => _buildDetailedResultCard(context, result)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedResultCard(BuildContext context, AeratorResult result) {
    final isWinner = result.name == winnerLabel;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isWinner ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isWinner)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.recommended,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(),
            _detailRow(l10n.unitsNeeded, result.numAerators.toString()),
            _detailRow(l10n.aeratorsPerHaLabel,
                result.aeratorsPerHa.toStringAsFixed(2)),
            _detailRow(l10n.horsepowerPerHaLabel,
                '${result.hpPerHa.toStringAsFixed(2)} hp/ha'),
            _detailRow(l10n.initialCostLabel,
                ResultsPage.formatCurrencyK(result.totalInitialCost)),
            _detailRow(l10n.annualCostLabel,
                ResultsPage.formatCurrencyK(result.totalAnnualCost)),
            _detailRow(l10n.costPercentRevenueLabel,
                '${result.costPercentRevenue.toStringAsFixed(2)}%'),
            _detailRow(l10n.annualEnergyCostLabel,
                ResultsPage.formatCurrencyK(result.annualEnergyCost)),
            _detailRow(l10n.annualMaintenanceCostLabel,
                ResultsPage.formatCurrencyK(result.annualMaintenanceCost)),
            _detailRow(l10n.annualReplacementCostLabel,
                ResultsPage.formatCurrencyK(result.annualReplacementCost)),
            if (result.opportunityCost > 0)
              _detailRow(l10n.opportunityCostLabel,
                  ResultsPage.formatCurrencyK(result.opportunityCost)),
            const Divider(),
            _detailRow(
              l10n.npvSavingsLabel,
              ResultsPage.formatCurrencyK(result.npvSavings),
            ),
            _detailRow(
                l10n.paybackPeriod,
                _formatPaybackPeriod(result.paybackYears, l10n,
                    isWinner: isWinner)),
            _detailRow(l10n.roiLabel,
                _formatROI(result.roiPercent, l10n, isWinner: isWinner)),
            _detailRow(
                l10n.irrLabel,
                result.irr <= -100
                    ? l10n.notApplicable
                    : '${result.irr.toStringAsFixed(2)}%'),
            _detailRow(l10n.profitabilityIndexLabel,
                _formatProfitabilityK(result.profitabilityK)),
            _detailRow(
              l10n.saeLabel,
              '${result.sae.toStringAsFixed(2)} kg O₂/kWh',
              useSubscript: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool useSubscript = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          useSubscript
              ? Builder(
                  builder: (context) => RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: ''),
                        ...parseSaeText(value),
                      ],
                    ),
                  ),
                )
              : Text(value),
        ],
      ),
    );
  }

  List<InlineSpan> parseSaeText(String text) {
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
        spans.add(
          TextSpan(text: 'O'),
        );
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

  String _formatPaybackPeriod(double paybackYears, AppLocalizations l10n,
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

  String _formatROI(double roi, AppLocalizations l10n,
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

  String _formatProfitabilityK(double k) {
    if (k >= 1_000_000) return '${(k / 1_000_000).toStringAsFixed(2)}M';
    if (k >= 1000) return '${(k / 1000).toStringAsFixed(2)}K';
    return k.toStringAsFixed(2);
  }
}

class _EquilibriumPricesCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Map<String, dynamic> equilibriumPrices;

  const _EquilibriumPricesCard({
    required this.l10n,
    required this.equilibriumPrices,
  });

  @override
  Widget build(BuildContext context) {
    if (equilibriumPrices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.equilibriumPricesDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.equilibriumPrices,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.equilibriumPriceExplanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...equilibriumPrices.entries.map((entry) {
                final price =
                    (entry.value is num) ? entry.value.toDouble() : 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          ResultsPage.formatCurrencyK(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostVisualizationCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String winnerLabel;

  const _CostVisualizationCard({
    required this.l10n,
    required this.results,
    required this.winnerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.costBreakdownVisualization,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.annualCostComposition,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 450,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 24.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxCost() * 1.3,
                    barGroups: _getBarGroups(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < results.length) {
                              final name = results[value.toInt()].name;
                              final isWinner = name == winnerLabel;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  isWinner
                                      ? l10n.recommended
                                      : "Less Preferred",
                                  style: TextStyle(
                                    color: isWinner
                                        ? Colors.green.shade700
                                        : const Color.fromARGB(255, 252, 7, 7),
                                    fontWeight: isWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: _calculateYAxisInterval(),
                          getTitlesWidget: (value, meta) {
                            if (value % _calculateYAxisInterval() != 0) {
                              return const SizedBox.shrink();
                            }
                            final formattedValue = value >= 1_000_000
                                ? '${(value / 1_000_000).toStringAsFixed(1)}M'
                                : value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(0)}K'
                                    : value.toInt().toString();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '\$$formattedValue',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateYAxisInterval(),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(),
                        left: BorderSide(),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white.withAlpha(204),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final result = results[groupIndex];
                          String component;
                          double value;
                          if (rodIndex < 0 ||
                              rodIndex >= rod.rodStackItems.length) {
                            return null;
                          }
                          switch (rodIndex) {
                            case 0:
                              component = l10n.annualEnergyCostLabel;
                              value = result.annualEnergyCost;
                              break;
                            case 1:
                              component = l10n.annualMaintenanceCostLabel;
                              value = result.annualMaintenanceCost;
                              break;
                            case 2:
                              component = l10n.annualReplacementCostLabel;
                              value = result.annualReplacementCost;
                              break;
                            default:
                              return null;
                          }
                          return BarTooltipItem(
                            '$component\n${ResultsPage.formatCurrencyK(value)}',
                            const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      touchCallback:
                          (FlTouchEvent event, BarTouchResponse? response) {
                        if (response == null || response.spot == null) return;
                        if (event is! FlTapDownEvent) return;
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.blue.shade300, l10n.annualEnergyCostLabel),
        const SizedBox(width: 16),
        _legendItem(Colors.green.shade300, l10n.annualMaintenanceCostLabel),
        const SizedBox(width: 16),
        _legendItem(Colors.orange.shade300, l10n.annualReplacementCostLabel),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  double _getMaxCost() {
    double maxCost = 0;
    for (final result in results) {
      final totalCost = result.annualEnergyCost +
          result.annualMaintenanceCost +
          result.annualReplacementCost;
      if (totalCost > maxCost) {
        maxCost = totalCost;
      }
    }
    return maxCost;
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(results.length, (index) {
      final result = results[index];
      final isWinner = result.name == winnerLabel;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: result.annualEnergyCost +
                result.annualMaintenanceCost +
                result.annualReplacementCost,
            width: 100,
            borderRadius: BorderRadius.zero,
            rodStackItems: [
              BarChartRodStackItem(
                  0, result.annualEnergyCost, Colors.blue.shade300),
              BarChartRodStackItem(
                  result.annualEnergyCost,
                  result.annualEnergyCost + result.annualMaintenanceCost,
                  Colors.green.shade300),
              BarChartRodStackItem(
                  result.annualEnergyCost + result.annualMaintenanceCost,
                  result.annualEnergyCost +
                      result.annualMaintenanceCost +
                      result.annualReplacementCost,
                  Colors.orange.shade300),
            ],
            borderSide: isWinner
                ? BorderSide(color: Colors.green.shade700, width: 2)
                : BorderSide.none,
          ),
        ],
      );
    });
  }

  double _calculateYAxisInterval() {
    final maxCost = _getMaxCost();
    if (maxCost <= 100) return 20;
    if (maxCost <= 500) return 100;
    if (maxCost <= 1000) return 200;
    if (maxCost <= 5000) return 1000;
    if (maxCost <= 10000) return 2000;
    if (maxCost <= 50000) return 10000;
    if (maxCost <= 100000) return 20000;
    return maxCost / 5;
  }
}

class _CostEvolutionCard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<AeratorResult> results;
  final String winnerLabel;
  final Map<String, dynamic>? surveyData;

  const _CostEvolutionCard({
    required this.l10n,
    required this.results,
    required this.winnerLabel,
    required this.surveyData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.costEvolutionVisualization,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Cumulative cost difference (including initial cost) vs. recommended aerator over time',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: _getAreaChartData(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: _calculateYAxisInterval(),
                        getTitlesWidget: (value, meta) {
                          if (value % _calculateYAxisInterval() != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              ResultsPage.formatCurrencyK(value),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(),
                      left: BorderSide(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateYAxisInterval(),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.red,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendForCostEvolution(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendForCostEvolution(BuildContext context) {
    final winnerAerator =
        results.firstWhere((result) => result.name == winnerLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.withAlpha(51), Colors.blue],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Cumulative cost difference vs ${winnerAerator.name}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateYAxisInterval() {
    final maxDifference = _getMaxCostDifference();
    if (maxDifference <= 5000) return 1000;
    if (maxDifference <= 20000) return 5000;
    if (maxDifference <= 100000) return 20000;
    if (maxDifference <= 1000000) return 200000;
    return maxDifference / 5;
  }

  double _getMaxCostDifference() {
    final winnerAerator =
        results.firstWhere((result) => result.name == winnerLabel);
    final horizon = surveyData?['financial']?['horizon'] as int? ?? 10;
    double maxDiff = 0;
    double minDiff = 0;

    for (var result in results) {
      if (result.name != winnerLabel) {
        double cumulativeDiff =
            result.totalInitialCost - winnerAerator.totalInitialCost;
        if (cumulativeDiff > maxDiff) maxDiff = cumulativeDiff;
        if (cumulativeDiff < minDiff) minDiff = cumulativeDiff;
        for (var year = 1; year <= horizon; year++) {
          cumulativeDiff +=
              result.totalAnnualCost - winnerAerator.totalAnnualCost;
          if (cumulativeDiff > maxDiff) maxDiff = cumulativeDiff;
          if (cumulativeDiff < minDiff) minDiff = cumulativeDiff;
        }
      }
    }
    return (maxDiff.abs() > minDiff.abs()) ? maxDiff : minDiff.abs();
  }

  List<LineChartBarData> _getAreaChartData() {
    final List<LineChartBarData> barData = [];
    final winnerAerator =
        results.firstWhere((result) => result.name == winnerLabel);
    final horizon = surveyData?['financial']?['horizon'] as int? ?? 10;

    for (var result in results) {
      if (result.name != winnerLabel) {
        final spots = <FlSpot>[];
        double cumulativeDiff =
            result.totalInitialCost - winnerAerator.totalInitialCost;
        spots.add(FlSpot(0, cumulativeDiff));
        for (var year = 1; year <= horizon; year++) {
          cumulativeDiff +=
              result.totalAnnualCost - winnerAerator.totalAnnualCost;
          spots.add(FlSpot(year.toDouble(), cumulativeDiff));
        }
        barData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(76),
              applyCutOffY: false,
            ),
          ),
        );
      }
    }
    return barData;
  }
}

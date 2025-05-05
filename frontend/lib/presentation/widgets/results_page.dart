import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/app_state.dart';
import 'dart:typed_data';
import 'components/aerator_result.dart';
import 'components/enhanced_summary_card.dart';
import 'components/aerator_comparison_card.dart';
import 'components/equilibrium_prices_card.dart';
import 'components/cost_visualization_card.dart';
import 'components/cost_evolution_card.dart';
import 'utils/formatting_utils.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

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
            FormattingUtils.formatCurrencyK(result.totalInitialCost)),
        _createPdfTableRow(l10n.annualCostLabel,
            FormattingUtils.formatCurrencyK(result.totalAnnualCost)),
        _createPdfTableRow(l10n.costPercentRevenueLabel,
            '${result.costPercentRevenue.toStringAsFixed(2)}%'),
        _createPdfTableRow(l10n.npvSavingsLabel,
            FormattingUtils.formatCurrencyK(result.npvSavings)),
        _createPdfTableRow(
            l10n.saeLabel, '${result.sae.toStringAsFixed(2)} kg O₂/kWh',
            useSubscriptFont: true,
            notoSerifBlackFont: notoSerifBlackFont,
            notoSerifFont: notoSerifFont),
      ];

      // Create cost breakdown rows
      final costBreakdownRows = [
        _createPdfTableRow(l10n.annualEnergyCostLabel,
            FormattingUtils.formatCurrencyK(result.annualEnergyCost)),
        _createPdfTableRow(l10n.annualMaintenanceCostLabel,
            FormattingUtils.formatCurrencyK(result.annualMaintenanceCost)),
        _createPdfTableRow(l10n.annualReplacementCostLabel,
            FormattingUtils.formatCurrencyK(result.annualReplacementCost)),
      ];

      if (result.opportunityCost > 0) {
        costBreakdownRows.add(_createPdfTableRow(l10n.opportunityCostLabel,
            FormattingUtils.formatCurrencyK(result.opportunityCost)));
      }

      // Financial metrics rows
      final financialMetricsRows = [
        _createPdfTableRow(
            l10n.paybackPeriod,
            FormattingUtils.formatPaybackPeriod(result.paybackYears, l10n,
                isWinner: isWinner)),
        _createPdfTableRow(
            l10n.roiLabel,
            FormattingUtils.formatROI(result.roiPercent, l10n,
                isWinner: isWinner)),
        _createPdfTableRow(
            l10n.irrLabel,
            result.irr <= -100
                ? l10n.notApplicable
                : '${result.irr.toStringAsFixed(2)}%'),
        _createPdfTableRow(l10n.profitabilityIndexLabel,
            FormattingUtils.formatProfitabilityK(result.profitabilityK)),
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
                      child: pw.Text(FormattingUtils.formatCurrencyK(
                          result.annualEnergyCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(FormattingUtils.formatCurrencyK(
                          result.annualMaintenanceCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(FormattingUtils.formatCurrencyK(
                          result.annualReplacementCost)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        FormattingUtils.formatCurrencyK(
                            result.annualEnergyCost +
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
                      '${l10n.annualRevenueLabel}: ${FormattingUtils.formatCurrencyK(annualRevenue)}'),
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
                const Icon(Icons.warning_amber_rounded,
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
                            EnhancedSummaryCard(
                              l10n: l10n,
                              tod: tod,
                              winnerLabel: winnerLabel,
                              annualRevenue: annualRevenue,
                              surveyData: surveyData,
                              results: results,
                            ),
                            const SizedBox(height: 16),
                            AeratorComparisonCard(
                              l10n: l10n,
                              results: results,
                              winnerLabel: winnerLabel,
                            ),
                            const SizedBox(height: 16),
                            EquilibriumPricesCard(
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
                            CostVisualizationCard(
                              l10n: l10n,
                              results: results,
                              winnerLabel: winnerLabel,
                            ),
                            const SizedBox(height: 16),
                            CostEvolutionCard(
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

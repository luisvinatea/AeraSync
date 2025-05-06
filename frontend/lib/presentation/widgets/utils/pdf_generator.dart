import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../components/results/aerator_result.dart';
import 'formatting_utils.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(
      AppLocalizations l10n,
      List<AeratorResult> results,
      String winnerLabel,
      double tod,
      double annualRevenue,
      Map<String, dynamic>? surveyData,
      Map<String, dynamic> apiResults) async {
    final pdf = pw.Document();

    // Load fonts from assets
    final baseFont = await _loadFont('web/fonts/NotoSerif-Bold.ttf');
    final boldFont = await _loadFont('web/fonts/NotoSerif-Black.ttf');

    // Create a theme for consistent styling
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );

    // Create cost visualization table
    final costVisualizationTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Name
        1: const pw.FlexColumnWidth(1), // Energy
        2: const pw.FlexColumnWidth(1), // Maintenance
        3: const pw.FlexColumnWidth(1), // Replacement
        4: const pw.FlexColumnWidth(1), // Total
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell(l10n.aerator, isBold: true),
            _tableCell(l10n.energyCostLabel, isBold: true, isCenter: true),
            _tableCell(l10n.maintenanceCostLabel, isBold: true, isCenter: true),
            _tableCell(l10n.replacementCostLabel, isBold: true, isCenter: true),
            _tableCell(l10n.totalLabel, isBold: true, isCenter: true),
          ],
        ),
        // Data rows for each aerator
        ...results.map((result) {
          final isWinner = result.name == winnerLabel;
          final totalCost = result.annualEnergyCost +
              result.annualMaintenanceCost +
              result.annualReplacementCost;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isWinner ? PdfColors.green50 : PdfColors.white,
            ),
            children: [
              _tableCell(result.name,
                  isBold: isWinner,
                  textColor: isWinner ? PdfColors.green800 : null),
              _tableCell(
                  FormattingUtils.formatCurrencyK(result.annualEnergyCost),
                  isCenter: true),
              _tableCell(
                  FormattingUtils.formatCurrencyK(result.annualMaintenanceCost),
                  isCenter: true),
              _tableCell(
                  FormattingUtils.formatCurrencyK(result.annualReplacementCost),
                  isCenter: true),
              _tableCell(FormattingUtils.formatCurrencyK(totalCost),
                  isBold: isWinner, isCenter: true),
            ],
          );
        }),
      ],
    );

    // Create comparison table
    final comparisonTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell(l10n.metric, isBold: true),
            ...results.map((result) => _tableCell(result.name,
                isBold: result.name == winnerLabel,
                textColor:
                    result.name == winnerLabel ? PdfColors.green800 : null,
                isCenter: true)),
          ],
        ),
        // Key metrics rows
        _metricRow(l10n.unitsNeeded, results, (r) => r.numAerators.toString()),
        _metricRow(l10n.aeratorsPerHaLabel, results,
            (r) => r.aeratorsPerHa.toStringAsFixed(2)),
        _metricRow(l10n.horsepowerPerHaLabel, results,
            (r) => '${r.hpPerHa.toStringAsFixed(2)} hp/ha'),
        _metricRow(l10n.initialCostLabel, results,
            (r) => FormattingUtils.formatCurrencyK(r.totalInitialCost)),
        _metricRow(l10n.annualCostLabel, results,
            (r) => FormattingUtils.formatCurrencyK(r.totalAnnualCost)),
        _metricRow(l10n.npvSavingsLabel, results,
            (r) => FormattingUtils.formatCurrencyK(r.npvSavings)),
        _metricRow(l10n.saeLabel, results,
            (r) => '${r.sae.toStringAsFixed(2)} kg O₂/kWh'),
        _metricRow(
            l10n.paybackPeriod,
            results,
            (r) => FormattingUtils.formatPaybackPeriod(r.paybackYears, l10n,
                isWinner: r.name == winnerLabel)),
        _metricRow(
            l10n.roiLabel,
            results,
            (r) => FormattingUtils.formatROI(r.roiPercent, l10n,
                isWinner: r.name == winnerLabel)),
        _metricRow(l10n.profitabilityIndexLabel, results,
            (r) => FormattingUtils.formatProfitabilityK(r.profitabilityK)),
      ],
    );

    // Create equilibrium prices table if available
    pw.Widget equilibriumPricesTable = pw.Container();
    final equilibriumPrices =
        apiResults['equilibriumPrices'] as Map<String, dynamic>? ?? {};
    if (equilibriumPrices.isNotEmpty) {
      final rows = <pw.TableRow>[];

      // Header row
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _tableCell(l10n.parameter, isBold: true),
          _tableCell(l10n.equilibriumValue, isBold: true, isCenter: true),
        ],
      ));

      // Data rows
      equilibriumPrices.forEach((parameter, value) {
        rows.add(pw.TableRow(
          children: [
            _tableCell(parameter, isBold: true),
            _tableCell(
                FormattingUtils.formatCurrencyK(
                    value is num ? value.toDouble() : 0.0),
                isCenter: true),
          ],
        ));
      });

      equilibriumPricesTable = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.equilibriumPrices,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
            },
            children: rows,
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('AeraSync',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          // Summary header
          pw.Center(
            child: pw.Text(
              l10n.aeratorComparisonResults,
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700),
            ),
          ),
          pw.SizedBox(height: 8),

          // Summary section
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
              color: PdfColors.blue50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              '${l10n.totalDemandLabel}: ${tod.toStringAsFixed(2)} kg O₂/h'),
                          pw.Text(
                              '${l10n.annualRevenueLabel}: ${FormattingUtils.formatCurrencyK(annualRevenue)}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(color: PdfColors.green),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text(
                          '${l10n.recommendedAerator}: $winnerLabel',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Comparison table
          pw.Text(
            l10n.aeratorComparisonResults,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          comparisonTable,
          pw.SizedBox(height: 10),

          // Cost table
          pw.Text(
            l10n.costBreakdownVisualization,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          costVisualizationTable,
          pw.SizedBox(height: 10),

          // Equilibrium Prices (if available)
          if (equilibriumPrices.isNotEmpty) ...[
            equilibriumPricesTable,
            pw.SizedBox(height: 10),
          ],

          // Survey inputs (if space allows)
          if (surveyData != null) ...[
            pw.Text(
              l10n.surveyInputs,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            _buildSurveyInputsTable(surveyData, l10n),
          ],

          // Footer note
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Generated by AeraSync on ${DateTime.now().toString().substring(0, 10)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableCell(String text,
      {bool isBold = false, bool isCenter = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : null,
          color: textColor,
          fontSize: 9,
        ),
        textAlign: isCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _metricRow(String label, List<AeratorResult> results,
      String Function(AeratorResult) valueGetter) {
    return pw.TableRow(
      children: [
        _tableCell(label, isBold: true),
        ...results.map((result) => _tableCell(
              valueGetter(result),
              isBold: result.name ==
                  results.firstWhere((r) => r.name == results.first.name).name,
              isCenter: true,
            )),
      ],
    );
  }

  static pw.Widget _buildSurveyInputsTable(
      Map<String, dynamic> surveyData, AppLocalizations l10n) {
    final farmSection = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.farmSpecs,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            _inputRow(l10n.farmAreaLabel,
                '${surveyData['farm']?['farm_area_ha']?.toString() ?? 'N/A'} ha'),
            _inputRow(l10n.shrimpPriceLabel,
                '\$${surveyData['farm']?['shrimp_price']?.toString() ?? 'N/A'}/kg'),
            _inputRow(l10n.cultureDaysLabel,
                surveyData['farm']?['culture_days']?.toString() ?? 'N/A'),
            _inputRow(l10n.shrimpDensityLabel,
                '${surveyData['farm']?['shrimp_density_kg_m3']?.toString() ?? 'N/A'} kg/m³'),
            _inputRow(l10n.pondDepthLabel,
                '${surveyData['farm']?['pond_depth_m']?.toString() ?? 'N/A'} m'),
            _inputRow(l10n.temperatureLabel,
                '${surveyData['financial']?['temperature']?.toString() ?? 'N/A'} °C'),
          ],
        ),
      ],
    );

    // Aerator 1 specifications
    final aerator1Section = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "${l10n.aeratorLabel} 1",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            _inputRow(l10n.nameLabel,
                surveyData['aerator1']?['name']?.toString() ?? 'N/A'),
            _inputRow(l10n.powerLabel,
                '${surveyData['aerator1']?['power_hp']?.toString() ?? 'N/A'} HP'),
            _inputRow(l10n.sotrLabel,
                '${surveyData['aerator1']?['sotr']?.toString() ?? 'N/A'} kg O₂/h'),
            _inputRow(l10n.costLabel,
                '\$${surveyData['aerator1']?['cost']?.toString() ?? 'N/A'}'),
            _inputRow(l10n.durabilityLabel,
                '${surveyData['aerator1']?['durability']?.toString() ?? 'N/A'} ${l10n.years}'),
            _inputRow(l10n.maintenanceLabel,
                '\$${surveyData['aerator1']?['maintenance']?.toString() ?? 'N/A'}/${l10n.year}'),
          ],
        ),
      ],
    );

    // Aerator 2 specifications
    final aerator2Section = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "${l10n.aeratorLabel} 2",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            _inputRow(l10n.nameLabel,
                surveyData['aerator2']?['name']?.toString() ?? 'N/A'),
            _inputRow(l10n.powerLabel,
                '${surveyData['aerator2']?['power_hp']?.toString() ?? 'N/A'} HP'),
            _inputRow(l10n.sotrLabel,
                '${surveyData['aerator2']?['sotr']?.toString() ?? 'N/A'} kg O₂/h'),
            _inputRow(l10n.costLabel,
                '\$${surveyData['aerator2']?['cost']?.toString() ?? 'N/A'}'),
            _inputRow(l10n.durabilityLabel,
                '${surveyData['aerator2']?['durability']?.toString() ?? 'N/A'} ${l10n.years}'),
            _inputRow(l10n.maintenanceLabel,
                '\$${surveyData['aerator2']?['maintenance']?.toString() ?? 'N/A'}/${l10n.year}'),
          ],
        ),
      ],
    );

    final financialSection = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.financialAspects,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            _inputRow(l10n.energyCostLabel,
                '\$${surveyData['financial']?['energy_cost']?.toString() ?? 'N/A'}/kWh'),
            _inputRow(
                l10n.hoursPerNightLabel,
                surveyData['financial']?['hours_per_night']?.toString() ??
                    'N/A'),
            _inputRow(
                l10n.discountRateLabel,
                surveyData['financial']?['discount_rate'] != null
                    ? '${((surveyData['financial']['discount_rate'] as num) * 100).toStringAsFixed(1)}%'
                    : 'N/A'),
            _inputRow(
                l10n.inflationRateLabel,
                surveyData['financial']?['inflation_rate'] != null
                    ? '${((surveyData['financial']['inflation_rate'] as num) * 100).toStringAsFixed(1)}%'
                    : 'N/A'),
            _inputRow(l10n.analysisHorizonLabel,
                '${surveyData['financial']?['horizon']?.toString() ?? 'N/A'} ${l10n.years}'),
            _inputRow(
                l10n.safetyMarginLabel,
                surveyData['financial']?['safety_margin'] != null
                    ? '${((surveyData['financial']['safety_margin'] as num) * 100).toStringAsFixed(1)}%'
                    : 'N/A'),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        farmSection,
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Expanded(child: aerator1Section),
          pw.SizedBox(width: 10),
          pw.Expanded(child: aerator2Section),
        ]),
        pw.SizedBox(height: 10),
        financialSection,
      ],
    );
  }

  static pw.TableRow _inputRow(String label, String value) {
    return pw.TableRow(
      children: [
        _tableCell(label, isBold: true),
        _tableCell(value, isCenter: true),
      ],
    );
  }

  static Future<pw.Font> _loadFont(String path) async {
    final fontData = await rootBundle.load(path);
    return pw.Font.ttf(fontData);
  }
}

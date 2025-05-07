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
    final pdf = pw.Document(
      compress: true,
      title: "AeraSync Aerator Comparison Results",
      author: "AeraSync",
      creator: "AeraSync Analysis Tool",
    );

    // Load fonts from assets
    final baseFont = await _loadFont('assets/fonts/NotoSerif-Bold.ttf');
    final boldFont = await _loadFont('assets/fonts/NotoSerif-Black.ttf');

    // Create a theme for consistent styling
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );

    // Define common styling
    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue800,
    );

    final regularStyle = pw.TextStyle(fontSize: 10);

    final smallStyle = pw.TextStyle(fontSize: 8);

    final tableHeaderStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'AeraSync',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: smallStyle,
                ),
              ],
            ),
            if (context.pageNumber == 1) pw.SizedBox(height: 10),
            if (context.pageNumber == 1)
              pw.Center(
                child: pw.Text(
                  l10n.aeratorComparisonResults,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
            if (context.pageNumber == 1) pw.SizedBox(height: 5),
            if (context.pageNumber == 1)
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'AeraSync Report | Page ${context.pageNumber} of ${context.pagesCount}',
              style: smallStyle,
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        build: (pw.Context context) => [
          // Summary section
          pw.Text(l10n.summaryMetrics, style: headerStyle),
          pw.SizedBox(height: 8),

          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
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
                              '${l10n.totalDemandLabel}: ${tod.toStringAsFixed(2)} kg O₂/h',
                              style: regularStyle),
                          pw.Text(
                              '${l10n.annualRevenueLabel}: ${FormattingUtils.formatCurrencyK(annualRevenue)}',
                              style: regularStyle),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(color: PdfColors.green),
                          borderRadius: pw.BorderRadius.circular(4),
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
          pw.SizedBox(height: 15),

          // Comparison table - with better layout and styling
          pw.Text(l10n.aeratorComparisonResults, style: headerStyle),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headerStyle: tableHeaderStyle,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue700,
            ),
            headers: [l10n.metric, ...results.map((r) => r.name)],
            data: [
              [
                l10n.unitsNeeded,
                ...results.map((r) => r.numAerators.toString())
              ],
              [
                l10n.aeratorsPerHaLabel,
                ...results.map((r) => r.aeratorsPerHa.toStringAsFixed(2))
              ],
              [
                l10n.horsepowerPerHaLabel,
                ...results.map((r) => '${r.hpPerHa.toStringAsFixed(2)} hp/ha')
              ],
              [
                l10n.initialCostLabel,
                ...results.map(
                    (r) => FormattingUtils.formatCurrencyK(r.totalInitialCost))
              ],
              [
                l10n.annualCostLabel,
                ...results.map(
                    (r) => FormattingUtils.formatCurrencyK(r.totalAnnualCost))
              ],
              [
                l10n.npvSavingsLabel,
                ...results
                    .map((r) => FormattingUtils.formatCurrencyK(r.npvSavings))
              ],
              [
                l10n.saeLabel,
                ...results.map((r) => '${r.sae.toStringAsFixed(2)} kg O₂/kWh')
              ],
              [
                l10n.paybackPeriod,
                ...results.map((r) => FormattingUtils.formatPaybackPeriod(
                    r.paybackYears, l10n,
                    isWinner: r.name == winnerLabel))
              ],
              [
                l10n.roiLabel,
                ...results.map((r) => FormattingUtils.formatROI(
                    r.roiPercent, l10n,
                    isWinner: r.name == winnerLabel))
              ],
              [
                l10n.profitabilityIndexLabel,
                ...results.map((r) =>
                    FormattingUtils.formatProfitabilityK(r.profitabilityK))
              ],
            ],
            cellStyle: regularStyle,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              for (var i = 1; i <= results.length; i++) i: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              for (var i = 1; i <= results.length; i++)
                i: const pw.FlexColumnWidth(2),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            cellDecoration: (index, data, rowNum) {
              if (rowNum.isEven) {
                return pw.BoxDecoration(color: PdfColors.grey100);
              }
              return pw.BoxDecoration();
            },
          ),

          pw.SizedBox(height: 15),

          // Cost breakdown table
          pw.Text(l10n.costBreakdownVisualization, style: headerStyle),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headerStyle: tableHeaderStyle,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue700,
            ),
            headers: [
              l10n.aerator,
              l10n.annualEnergyCostLabel,
              l10n.annualMaintenanceCostLabel,
              l10n.annualReplacementCostLabel,
              l10n.totalLabel,
            ],
            data: results
                .map((result) => [
                      result.name,
                      FormattingUtils.formatCurrencyK(result.annualEnergyCost),
                      FormattingUtils.formatCurrencyK(
                          result.annualMaintenanceCost),
                      FormattingUtils.formatCurrencyK(
                          result.annualReplacementCost),
                      FormattingUtils.formatCurrencyK(result.totalAnnualCost),
                    ])
                .toList(),
            cellStyle: regularStyle,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            cellDecoration: (index, data, rowNum) {
              if (results[rowNum].name == winnerLabel) {
                return pw.BoxDecoration(color: PdfColors.green100);
              }
              if (rowNum.isEven) {
                return pw.BoxDecoration(color: PdfColors.grey100);
              }
              return pw.BoxDecoration();
            },
          ),

          pw.SizedBox(height: 15),

          // Equilibrium prices table
          if (apiResults['equilibriumPrices'] != null &&
              (apiResults['equilibriumPrices'] as Map).isNotEmpty) ...[
            pw.Text(l10n.equilibriumPrices, style: headerStyle),
            pw.SizedBox(height: 8),
            _buildEquilibriumPricesTable(
                apiResults['equilibriumPrices'] as Map<String, dynamic>, l10n),
            pw.SizedBox(height: 15),
          ],

          // Survey inputs section
          pw.Text(l10n.surveyInputs, style: headerStyle),
          pw.SizedBox(height: 8),

          // Display survey inputs in a more compact table layout
          _buildSurveyInputsTables(surveyData, l10n),
        ],
      ),
    );

    return pdf.save();
  }

  // Helper function for equilibrium prices table
  static pw.Widget _buildEquilibriumPricesTable(
      Map<String, dynamic> equilibriumPrices, AppLocalizations l10n) {
    final rows = <List<String>>[];

    equilibriumPrices.forEach((parameter, value) {
      rows.add([
        parameter,
        FormattingUtils.formatCurrencyK(value is num ? value.toDouble() : 0.0),
      ]);
    });

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue700,
      ),
      headers: [l10n.parameter, l10n.equilibriumValue],
      data: rows,
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
      },
      cellDecoration: (index, data, rowNum) {
        if (rowNum.isEven) {
          return pw.BoxDecoration(color: PdfColors.grey100);
        }
        return pw.BoxDecoration();
      },
    );
  }

  // Helper function for survey inputs tables with improved layout
  static pw.Widget _buildSurveyInputsTables(
      Map<String, dynamic>? surveyData, AppLocalizations l10n) {
    if (surveyData == null) {
      return pw.Container();
    }

    final farm = surveyData['farm'] ?? {};
    final financial = surveyData['financial'] ?? {};
    final aerator1 = surveyData['aerator1'] ?? {};
    final aerator2 = surveyData['aerator2'] ?? {};

    // Farm details table
    final farmTable = pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      headers: [l10n.parameter, l10n.value],
      data: [
        [l10n.farmAreaLabel, '${farm['farm_area_ha'] ?? 'N/A'} ha'],
        [l10n.shrimpPriceLabel, '\$${farm['shrimp_price'] ?? 'N/A'}/kg'],
        [l10n.cultureDaysLabel, '${farm['culture_days'] ?? 'N/A'}'],
        [
          l10n.shrimpDensityLabel,
          '${farm['shrimp_density_kg_m3'] ?? 'N/A'} kg/m³'
        ],
        [l10n.pondDepthLabel, '${farm['pond_depth_m'] ?? 'N/A'} m'],
      ],
      cellStyle: pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    );

    // Financial details table
    final financialTable = pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      headers: [l10n.parameter, l10n.value],
      data: [
        [l10n.energyCostLabel, '\$${financial['energy_cost'] ?? 'N/A'}/kWh'],
        [l10n.hoursPerNightLabel, '${financial['hours_per_night'] ?? 'N/A'}'],
        [
          l10n.discountRateLabel,
          '${financial['discount_rate'] != null ? (financial['discount_rate'] * 100).toStringAsFixed(1) : 'N/A'}%'
        ],
        [
          l10n.inflationRateLabel,
          '${financial['inflation_rate'] != null ? (financial['inflation_rate'] * 100).toStringAsFixed(1) : 'N/A'}%'
        ],
        [
          l10n.analysisHorizonLabel,
          '${financial['horizon'] ?? 'N/A'} ${l10n.years}'
        ],
        [
          l10n.safetyMarginLabel,
          '${financial['safety_margin'] != null ? (financial['safety_margin'] * 100).toStringAsFixed(1) : 'N/A'}%'
        ],
        [l10n.temperatureLabel, '${financial['temperature'] ?? 'N/A'} °C'],
      ],
      cellStyle: pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    );

    // Aerator 1 details table
    final aerator1Table = pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      headers: ['${l10n.aeratorLabel} 1', l10n.value],
      data: [
        [l10n.nameLabel, '${aerator1['name'] ?? 'N/A'}'],
        [l10n.powerLabel, '${aerator1['power_hp'] ?? 'N/A'} HP'],
        [l10n.sotrLabel, '${aerator1['sotr'] ?? 'N/A'} kg O₂/h'],
        [l10n.costLabel, '\$${aerator1['cost'] ?? 'N/A'}'],
        [
          l10n.durabilityLabel,
          '${aerator1['durability'] ?? 'N/A'} ${l10n.years}'
        ],
        [
          l10n.maintenanceLabel,
          '\$${aerator1['maintenance'] ?? 'N/A'}/${l10n.year}'
        ],
      ],
      cellStyle: pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    );

    // Aerator 2 details table
    final aerator2Table = pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      headers: ['${l10n.aeratorLabel} 2', l10n.value],
      data: [
        [l10n.nameLabel, '${aerator2['name'] ?? 'N/A'}'],
        [l10n.powerLabel, '${aerator2['power_hp'] ?? 'N/A'} HP'],
        [l10n.sotrLabel, '${aerator2['sotr'] ?? 'N/A'} kg O₂/h'],
        [l10n.costLabel, '\$${aerator2['cost'] ?? 'N/A'}'],
        [
          l10n.durabilityLabel,
          '${aerator2['durability'] ?? 'N/A'} ${l10n.years}'
        ],
        [
          l10n.maintenanceLabel,
          '\$${aerator2['maintenance'] ?? 'N/A'}/${l10n.year}'
        ],
      ],
      cellStyle: pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    );

    // Return the combined tables
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Farm section
        pw.Text(l10n.farmSpecs,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 4),
        farmTable,
        pw.SizedBox(height: 10),

        // Financial section
        pw.Text(l10n.financialAspects,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 4),
        financialTable,
        pw.SizedBox(height: 10),

        // Aerators section - side by side
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  aerator1Table,
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  aerator2Table,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Future<pw.Font> _loadFont(String path) async {
    try {
      final fontData = await rootBundle.load('assets/$path');
      return pw.Font.ttf(fontData.buffer.asUint8List() as ByteData);
    } catch (e) {
      // Fallback to base font if loading fails
      return pw.Font.helvetica();
    }
  }
}

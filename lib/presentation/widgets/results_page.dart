import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import 'dart:html' as html show Blob, Url, AnchorElement;

class ResultsWidget extends StatefulWidget {
  const ResultsWidget({super.key});

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  Future<pw.Document> _generatePDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    final surveyData = appState.surveyData!;

    final pdf = pw.Document();

    // Load local Montserrat fonts
    final regularFontData = await DefaultAssetBundle.of(context)
        .load('assets/fonts/Montserrat-Regular.ttf');
    final boldFontData =
        await DefaultAssetBundle.of(context).load('assets/fonts/Montserrat-Bold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                l10n.results,
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
            ),
            pw.Text(
              l10n.summaryMetrics,
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${l10n.totalDemandLabel}: ${(surveyData['tod'] as double).toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: regularFont),
            ),
            if (surveyData['shrimpDemand'] != null)
              pw.Text(
                '${l10n.shrimpDemandLabel}: ${(surveyData['shrimpDemand'] as double).toStringAsFixed(2)} kg O₂/h',
                style: pw.TextStyle(font: regularFont),
              ),
            if (surveyData['envDemand'] != null)
              pw.Text(
                '${l10n.envDemandLabel}: ${(surveyData['envDemand'] as double).toStringAsFixed(2)} kg O₂/h',
                style: pw.TextStyle(font: regularFont),
              ),
            pw.Text(
              '${l10n.annualRevenueLabel}: \$${surveyData['annualRevenue'].toStringAsFixed(2)}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              '${l10n.recommendedAerator}: ${(surveyData['apiResults'] as Map<String, dynamic>)['winnerLabel'] ?? 'N/A'}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.aeratorComparisonResults,
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: [
                l10n.aeratorLabel,
                l10n.unitsNeeded,
                l10n.totalAnnualCostLabel,
                l10n.costPercentage,
                l10n.saeLabel,
                l10n.npvLabel,
                l10n.irrLabel,
                l10n.paybackPeriod,
                l10n.roiLabel,
                l10n.profitabilityIndex,
              ],
              data: (surveyData['aeratorResults'] as List<dynamic>).map((result) {
                return [
                  result['name'].toString(),
                  result['numAerators'].toString(),
                  '\$${result['totalAnnualCost'].toStringAsFixed(2)}',
                  '${result['costPercentage'].toStringAsFixed(2)}%',
                  result['sae'].toStringAsFixed(2),
                  '\$${result['npv'].toStringAsFixed(2)}',
                  '${result['irr'].toStringAsFixed(2)}%',
                  '${(result['paybackPeriod'] / 365).toStringAsFixed(2)} years',
                  '${result['roi'].toStringAsFixed(2)}%',
                  (result['profitabilityIndex'] as double).isFinite
                      ? result['profitabilityIndex'].toStringAsFixed(2)
                      : '∞',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: regularFont),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.detailedFinancialMetrics,
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${l10n.equilibriumPriceP2Label}: \$ ${(surveyData['apiResults']['equilibriumPriceP2'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              '${l10n.costOfOpportunity}: \$ ${(surveyData['apiResults']['costOfOpportunity'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              '${l10n.annualSavings}: \$ ${(surveyData['apiResults']['annualSavings'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
              style: pw.TextStyle(font: regularFont),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  void _downloadCSV(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    final surveyData = appState.surveyData!;

    final aeratorResults = surveyData['aeratorResults'] as List<dynamic>;
    final apiResults = surveyData['apiResults'] as Map<String, dynamic>;

    final csvData = [
      [l10n.summaryMetrics],
      [
        l10n.totalDemandLabel,
        '${surveyData['tod'].toStringAsFixed(2)} kg O₂/h',
      ],
      if (surveyData['shrimpDemand'] != null)
        [
          l10n.shrimpDemandLabel,
          '${surveyData['shrimpDemand'].toStringAsFixed(2)} kg O₂/h',
        ],
      if (surveyData['envDemand'] != null)
        [
          l10n.envDemandLabel,
          '${surveyData['envDemand'].toStringAsFixed(2)} kg O₂/h',
        ],
      [
        l10n.annualRevenueLabel,
        '\$${surveyData['annualRevenue'].toStringAsFixed(2)}',
      ],
      [
        l10n.recommendedAerator,
        apiResults['winnerLabel'] ?? 'N/A',
      ],
      [],
      [l10n.aeratorComparisonResults],
      [
        l10n.aeratorLabel,
        l10n.unitsNeeded,
        l10n.totalAnnualCostLabel,
        l10n.costPercentage,
        l10n.saeLabel,
        l10n.npvLabel,
        l10n.irrLabel,
        l10n.paybackPeriod,
        l10n.roiLabel,
        l10n.profitabilityIndex,
      ],
      ...aeratorResults.map((result) => [
            result['name'].toString(),
            result['numAerators'].toString(),
            '\$${result['totalAnnualCost'].toStringAsFixed(2)}',
            '${result['costPercentage'].toStringAsFixed(2)}%',
            result['sae'].toStringAsFixed(2),
            '\$${result['npv'].toStringAsFixed(2)}',
            '${result['irr'].toStringAsFixed(2)}%',
            '${(result['paybackPeriod'] / 365).toStringAsFixed(2)} years',
            '${result['roi'].toStringAsFixed(2)}%',
            (result['profitabilityIndex'] as double).isFinite
                ? result['profitabilityIndex'].toStringAsFixed(2)
                : '∞',
          ]),
      [],
      [l10n.detailedFinancialMetrics],
      [
        l10n.equilibriumPriceP2Label,
        '\$${(apiResults['equilibriumPriceP2'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
      ],
      [
        l10n.costOfOpportunity,
        '\$${(apiResults['costOfOpportunity'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
      ],
      [
        l10n.annualSavings,
        '\$${(apiResults['annualSavings'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
      ],
    ];

    final csvString = csvData.map((row) => row.join(',')).join('\n');

    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'aerator_comparison.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.csvExportNotSupported)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final surveyData = appState.surveyData;

    if (surveyData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.results),
          backgroundColor: const Color(0xFF1E40AF),
        ),
        body: Center(child: Text(l10n.noDataAvailable)),
      );
    }

    final aeratorResults = (surveyData['aeratorResults'] as List<dynamic>)
        .map((result) => Map<String, dynamic>.from(result))
        .toList();
    final apiResults = surveyData['apiResults'] as Map<String, dynamic>;
    final tod = surveyData['tod'] as double;
    final shrimpDemand = surveyData['shrimpDemand'] as double?;
    final envDemand = surveyData['envDemand'] as double?;
    final annualRevenue = surveyData['annualRevenue'] as double;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.results),
        backgroundColor: const Color(0xFF1E40AF),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.summaryMetrics,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.totalDemandLabel}: ${tod.toStringAsFixed(2)} kg O₂/h',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (shrimpDemand != null)
                          Text(
                            '${l10n.shrimpDemandLabel}: ${shrimpDemand.toStringAsFixed(2)} kg O₂/h',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (envDemand != null)
                          Text(
                            '${l10n.envDemandLabel}: ${envDemand.toStringAsFixed(2)} kg O₂/h',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        Text(
                          '${l10n.annualRevenueLabel}: \$${annualRevenue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${l10n.recommendedAerator}: ${apiResults['winnerLabel'] ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (shrimpDemand != null && envDemand != null)
                  Card(
                    elevation: 4,
                    color: Colors.white.withValues(alpha: 0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.oxygenDemandBreakdown,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: [shrimpDemand, envDemand, tod]
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: shrimpDemand,
                                        color: const Color(0xFF1E40AF),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: envDemand,
                                        color: const Color(0xFF60A5FA),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: tod,
                                        color: const Color(0xFF3B82F6),
                                        width: 30,
                                      ),
                                    ],
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        switch (value.toInt()) {
                                          case 0:
                                            return Text(l10n.shrimpDemandLabel);
                                          case 1:
                                            return Text(l10n.envDemandLabel);
                                          case 2:
                                            return Text(l10n.totalDemandLabel);
                                          default:
                                            return const Text('');
                                        }
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(),
                                  rightTitles: const AxisTitles(),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aeratorComparisonResults,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(l10n.aeratorLabel)),
                              DataColumn(label: Text(l10n.unitsNeeded)),
                              DataColumn(label: Text(l10n.totalAnnualCostLabel)),
                              DataColumn(label: Text(l10n.costPercentage)),
                              DataColumn(label: Text(l10n.saeLabel)),
                              DataColumn(label: Text(l10n.npvLabel)),
                              DataColumn(label: Text(l10n.irrLabel)),
                              DataColumn(label: Text(l10n.paybackPeriod)),
                              DataColumn(label: Text(l10n.roiLabel)),
                              DataColumn(label: Text(l10n.profitabilityIndex)),
                            ],
                            rows: aeratorResults.map((result) {
                              return DataRow(cells: [
                                DataCell(Text(result['name'].toString())),
                                DataCell(Text(result['numAerators'].toString())),
                                DataCell(
                                  Text(
                                    '\$${result['totalAnnualCost'].toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${result['costPercentage'].toStringAsFixed(2)}%',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    result['sae'].toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\$${result['npv'].toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${result['irr'].toStringAsFixed(2)}%',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${(result['paybackPeriod'] / 365).toStringAsFixed(2)} years',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${result['roi'].toStringAsFixed(2)}%',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (result['profitabilityIndex'] as double).isFinite
                                        ? result['profitabilityIndex'].toStringAsFixed(2)
                                        : '∞',
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.detailedFinancialMetrics,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.equilibriumPriceP2Label}: \$${apiResults['equilibriumPriceP2']?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${l10n.costOfOpportunity}: \$${apiResults['costOfOpportunity']?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${l10n.annualSavings}: \$${apiResults['annualSavings']?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final pdf = await _generatePDF(context);
                            if (!mounted) return;
                            await Printing.sharePdf(
                              bytes: await pdf.save(),
                              filename: 'aerator_comparison_report.pdf',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${l10n.pdfGenerationFailed}: $e'),
                              ),
                            );
                          }
                        },
                        child: Text(l10n.downloadReport),
                      ),
                      ElevatedButton(
                        onPressed: () => _downloadCSV(context),
                        child: Text(l10n.downloadCSV),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
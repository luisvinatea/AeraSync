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
import 'package:universal_html/html.dart' as html; // Conditional import for web

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    if (_regularFont == null || _boldFont == null) {
      if (!mounted) return;
      final assetBundle = DefaultAssetBundle.of(context);
      final regularFontData = await assetBundle.load('assets/fonts/Montserrat-Regular.ttf');
      final boldFontData = await assetBundle.load('assets/fonts/Montserrat-Bold.ttf');
      if (!mounted) return;
      setState(() {
        _regularFont = pw.Font.ttf(regularFontData);
        _boldFont = pw.Font.ttf(boldFontData);
      });
    }
  }

  Future<pw.Document> _generatePDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    final results = appState.aeratorResults;

    final pdf = pw.Document();

    if (_regularFont == null || _boldFont == null) {
      await _loadFonts();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                l10n.results,
                style: pw.TextStyle(font: _boldFont, fontSize: 24),
              ),
            ),
            pw.Text(
              l10n.summaryMetrics,
              style: pw.TextStyle(font: _boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${l10n.totalDemandLabel}: ${appState.tod!.toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.shrimpRespirationLabel}: ${appState.shrimpRespiration!.toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.pondRespirationLabel}: ${appState.pondRespiration!.toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.pondWaterRespirationLabel}: ${(appState.pondWaterRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.pondBottomRespirationLabel}: ${(appState.pondBottomRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.annualRevenueLabel}: \$${appState.annualRevenue!.toStringAsFixed(2)}',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.recommendedAerator}: ${appState.winnerLabel ?? 'None'}',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.aeratorComparisonResults,
              style: pw.TextStyle(font: _boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
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
                l10n.profitabilityCoefficient,
              ],
              data: results.map((result) {
                return [
                  result.name,
                  result.numAerators.toString(),
                  '\$${result.totalAnnualCost.toStringAsFixed(2)}',
                  '${result.costPercentage.toStringAsFixed(2)}%',
                  result.sae.toStringAsFixed(2),
                  '\$${result.npv.toStringAsFixed(2)}',
                  result.irr.isFinite ? '${result.irr.toStringAsFixed(2)}%' : 'N/A',
                  result.paybackPeriod.isFinite ? '${result.paybackPeriod.toStringAsFixed(1)} months' : 'N/A',
                  result.roi.isFinite ? '${result.roi.toStringAsFixed(2)}%' : 'N/A',
                  result.profitabilityCoefficient.isFinite ? result.profitabilityCoefficient.toStringAsFixed(2) : '∞',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: _boldFont),
              cellStyle: pw.TextStyle(font: _regularFont),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.detailedFinancialMetrics,
              style: pw.TextStyle(font: _boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${l10n.equilibriumPriceP2Label}: \$${(_parseDouble(appState.apiResults?['equilibriumPriceP2'])).toStringAsFixed(2)}',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.opportunityCostLabel}: \$${(_parseDouble(appState.apiResults?['costOfOpportunity'])).toStringAsFixed(2)}',
              style: pw.TextStyle(font: _regularFont),
            ),
            pw.Text(
              '${l10n.annualSavings}: \$${(_parseDouble(appState.apiResults?['annualSavings'])).toStringAsFixed(2)}',
              style: pw.TextStyle(font: _regularFont),
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
    final results = appState.aeratorResults;
    final messenger = ScaffoldMessenger.of(context); // Capture early

    final csvData = [
      [l10n.summaryMetrics],
      [l10n.totalDemandLabel, '${appState.tod!.toStringAsFixed(2)} kg O₂/h'],
      [l10n.shrimpRespirationLabel, '${appState.shrimpRespiration!.toStringAsFixed(2)} kg O₂/h'],
      [l10n.pondRespirationLabel, '${appState.pondRespiration!.toStringAsFixed(2)} kg O₂/h'],
      [l10n.pondWaterRespirationLabel, '${(appState.pondWaterRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h'],
      [l10n.pondBottomRespirationLabel, '${(appState.pondBottomRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h'],
      [l10n.annualRevenueLabel, '\$${appState.annualRevenue!.toStringAsFixed(2)}'],
      [l10n.recommendedAerator, appState.winnerLabel ?? 'None'],
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
        l10n.profitabilityCoefficient,
      ],
      ...results.map((result) => [
            result.name,
            result.numAerators.toString(),
            '\$${result.totalAnnualCost.toStringAsFixed(2)}',
            '${result.costPercentage.toStringAsFixed(2)}%',
            result.sae.toStringAsFixed(2),
            '\$${result.npv.toStringAsFixed(2)}',
            result.irr.isFinite ? '${result.irr.toStringAsFixed(2)}%' : 'N/A',
            result.paybackPeriod.isFinite ? '${result.paybackPeriod.toStringAsFixed(1)} months' : 'N/A',
            result.roi.isFinite ? '${result.roi.toStringAsFixed(2)}%' : 'N/A',
            result.profitabilityCoefficient.isFinite ? result.profitabilityCoefficient.toStringAsFixed(2) : '∞',
          ]),
      [],
      [l10n.detailedFinancialMetrics],
      [
        l10n.equilibriumPriceP2Label,
        '\$${(_parseDouble(appState.apiResults?['equilibriumPriceP2'])).toStringAsFixed(2)}',
      ],
      [
        l10n.opportunityCostLabel,
        '\$${(_parseDouble(appState.apiResults?['costOfOpportunity'])).toStringAsFixed(2)}',
      ],
      [
        l10n.annualSavings,
        '\$${(_parseDouble(appState.apiResults?['annualSavings'])).toStringAsFixed(2)}',
      ],
    ];

    final csvString = csvData.map((row) => row.join(',')).join('\n');

    try {
      if (kIsWeb) {
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement;
        anchor.href = url;
        anchor.download = 'aerator_comparison.csv';
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.csvExportNotSupported)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.csvGenerationFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final results = appState.aeratorResults;

    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.results),
          backgroundColor: const Color(0xFF1E40AF),
        ),
        body: Center(
          child: Semantics(
            label: l10n.noDataAvailable,
            child: Text(l10n.noDataAvailable),
          ),
        ),
      );
    }

    final maxY = [
      appState.tod!,
      appState.shrimpRespiration!,
      appState.pondRespiration!,
      appState.pondWaterRespiration ?? 0.0,
      appState.pondBottomRespiration ?? 0.0,
    ].reduce((a, b) => a > b ? a : b) * 1.2;

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
                _SummaryCard(
                  l10n: l10n,
                  appState: appState,
                ),
                const SizedBox(height: 16),
                _OxygenDemandCard(
                  l10n: l10n,
                  appState: appState,
                  maxY: maxY,
                ),
                const SizedBox(height: 16),
                _AeratorComparisonCard(
                  l10n: l10n,
                  appState: appState,
                  results: results,
                ),
                const SizedBox(height: 16),
                _FinancialMetricsCard(
                  l10n: l10n,
                  appState: appState,
                ),
                const SizedBox(height: 16),
                _FinancialPieChartCard(
                  l10n: l10n,
                  appState: appState,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final pdf = await _generatePDF(context);
                            if (!mounted) return;
                            await Printing.sharePdf(
                              bytes: await pdf.save(),
                              filename: 'aerator_comparison_report.pdf',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.pdfGenerationFailed(e.toString())),
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

class _SummaryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppState appState;

  const _SummaryCard({
    required this.l10n,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.summaryMetrics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.summaryMetrics,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.totalDemandLabel}: ${appState.tod!.toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.shrimpRespirationLabel}: ${appState.shrimpRespiration!.toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.pondRespirationLabel}: ${appState.pondRespiration!.toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.pondWaterRespirationLabel}: ${(appState.pondWaterRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.pondBottomRespirationLabel}: ${(appState.pondBottomRespiration ?? 0.0).toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.annualRevenueLabel}: \$${appState.annualRevenue!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.recommendedAerator}: ${appState.winnerLabel ?? 'None'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OxygenDemandCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppState appState;
  final double maxY;

  const _OxygenDemandCard({
    required this.l10n,
    required this.appState,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (appState.tod == null || appState.shrimpRespiration == null || appState.pondRespiration == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.oxygenDemandBreakdown,
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
                    maxY: maxY,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: appState.tod!,
                            color: Colors.redAccent,
                            width: 15,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: appState.shrimpRespiration!,
                            color: const Color(0xFF1E40AF),
                            width: 15,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: appState.pondRespiration!,
                            color: const Color(0xFF60A5FA),
                            width: 15,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                            toY: appState.pondWaterRespiration ?? 0.0,
                            color: const Color(0xFF3B82F6),
                            width: 15,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 4,
                        barRods: [
                          BarChartRodData(
                            toY: appState.pondBottomRespiration ?? 0.0,
                            color: const Color(0xFF93C5FD),
                            width: 15,
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
                                return Text(l10n.totalDemandLabel, style: const TextStyle(fontSize: 10));
                              case 1:
                                return Text(l10n.shrimpRespirationLabel, style: const TextStyle(fontSize: 10));
                              case 2:
                                return Text(l10n.pondRespirationLabel, style: const TextStyle(fontSize: 10));
                              case 3:
                                return Text(l10n.pondWaterRespirationLabel, style: const TextStyle(fontSize: 10));
                              case 4:
                                return Text(l10n.pondBottomRespirationLabel, style: const TextStyle(fontSize: 10));
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
    );
  }
}

class _AeratorComparisonCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppState appState;
  final List<AeratorResult> results;

  const _AeratorComparisonCard({
    required this.l10n,
    required this.appState,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.aeratorComparisonResults,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aeratorComparisonResults,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                          DataColumn(label: Text(l10n.profitabilityCoefficient)),
                        ],
                        rows: results.map((result) {
                          final isWinner = result.name == appState.winnerLabel;
                          return DataRow(
                            color: isWinner ? WidgetStateProperty.all(Colors.green.withValues(alpha: 0.1)) : null,
                            cells: [
                              DataCell(Text(result.name)),
                              DataCell(Text(result.numAerators.toString())),
                              DataCell(Text('\$${result.totalAnnualCost.toStringAsFixed(2)}')),
                              DataCell(Text('${result.costPercentage.toStringAsFixed(2)}%')),
                              DataCell(Text(result.sae.toStringAsFixed(2))),
                              DataCell(Text('\$${result.npv.toStringAsFixed(2)}')),
                              DataCell(Text(result.irr.isFinite ? '${result.irr.toStringAsFixed(2)}%' : 'N/A')),
                              DataCell(Text(
                                  result.paybackPeriod.isFinite ? '${result.paybackPeriod.toStringAsFixed(1)} months' : 'N/A')),
                              DataCell(Text(result.roi.isFinite ? '${result.roi.toStringAsFixed(2)}%' : 'N/A')),
                              DataCell(
                                Text(
                                  result.profitabilityCoefficient.isFinite
                                      ? result.profitabilityCoefficient.toStringAsFixed(2)
                                      : '∞',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialMetricsCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppState appState;

  const _FinancialMetricsCard({
    required this.l10n,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.detailedFinancialMetrics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.detailedFinancialMetrics,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.equilibriumPriceP2Label}: \$${(_parseDouble(appState.apiResults?['equilibriumPriceP2'])).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.opportunityCostLabel}: \$${(_parseDouble(appState.apiResults?['costOfOpportunity'])).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.annualSavings}: \$${(_parseDouble(appState.apiResults?['annualSavings'])).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialPieChartCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AppState appState;

  const _FinancialPieChartCard({
    required this.l10n,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final annualSavings = _parseDouble(appState.apiResults?['annualSavings']);
    final opportunityCost = _parseDouble(appState.apiResults?['costOfOpportunity']);
    final totalCost = appState.aeratorResults.fold<double>(
      0.0,
      (sum, result) => sum + (result.name == appState.winnerLabel ? result.totalAnnualCost : 0),
    );

    if (annualSavings <= 0 && opportunityCost <= 0 && totalCost <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Semantics(
          label: l10n.financialBreakdown,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.financialBreakdown,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (totalCost > 0)
                        PieChartSectionData(
                          value: totalCost,
                          title: l10n.totalAnnualCostLabel,
                          color: const Color(0xFF1E40AF),
                          radius: 80,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      if (annualSavings > 0)
                        PieChartSectionData(
                          value: annualSavings,
                          title: l10n.annualSavings,
                          color: const Color(0xFF60A5FA),
                          radius: 80,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      if (opportunityCost > 0)
                        PieChartSectionData(
                          value: opportunityCost,
                          title: l10n.opportunityCostLabel,
                          color: const Color(0xFF93C5FD),
                          radius: 80,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
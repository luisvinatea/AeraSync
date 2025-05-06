import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'components/results/aerator_result.dart';
import 'components/results/enhanced_summary_card.dart';
import 'components/results/aerator_comparison_card.dart';
import 'components/results/equilibrium_prices_card.dart';
import 'components/results/cost_visualization_card.dart';
import 'components/results/cost_evolution_card.dart';
import 'utils/pdf_generator.dart';
import 'utils/wave_background.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with TickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final apiResults = appState.apiResults;

    if (apiResults == null || !apiResults.containsKey('aeratorResults')) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(249, 246, 244, 244),
          elevation: 0,
          title: Text(
            l10n.results,
            style: const TextStyle(color: Color.fromARGB(255, 50, 120, 201)),
          ),
        ),
        body: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return Stack(
              children: [
                WaveBackground(animation: _waveController.value),
                Center(
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
                          color: Color.fromARGB(255, 56, 112, 210),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade800,
                        ),
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/survey'),
                        child: Text(l10n.returnToSurvey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 244, 241, 241),
        elevation: 0,
        title: Text(
          l10n.results,
          style: const TextStyle(color: Color.fromARGB(255, 64, 126, 218)),
        ),
      ),
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Stack(
            children: [
              WaveBackground(animation: _waveController.value),
              Padding(
                padding: const EdgeInsets.all(36.0),
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
                                  const SizedBox(height: 24),
                                  AeratorComparisonCard(
                                    l10n: l10n,
                                    results: results,
                                    winnerLabel: winnerLabel,
                                  ),
                                  const SizedBox(height: 24),
                                  EquilibriumPricesCard(
                                    l10n: l10n,
                                    equilibriumPrices: equilibriumPrices,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  CostVisualizationCard(
                                    l10n: l10n,
                                    results: results,
                                    winnerLabel: winnerLabel,
                                  ),
                                  const SizedBox(height: 24),
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
                        style: AppTheme.secondaryButtonStyle,
                        onPressed: () => appState.navigateToSurvey(),
                        child: Text(
                          l10n.newComparison,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.fontSizeMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: AppTheme.secondaryButtonStyle,
                        onPressed: () async {
                          final pdfData = await PdfGenerator.generatePdf(
                              l10n,
                              results,
                              winnerLabel,
                              tod,
                              annualRevenue,
                              surveyData,
                              apiResults);
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
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_util.dart';
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.results,
            style: const TextStyle(color: Color.fromARGB(255, 242, 243, 245)),
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
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        title: Text(
          l10n.results,
          style: const TextStyle(color: Color.fromARGB(255, 254, 254, 255)),
        ),
      ),
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Stack(
            children: [
              WaveBackground(animation: _waveController.value),
              SafeArea(
                child: Padding(
                  padding:
                      EdgeInsets.all(ResponsiveUtil.contentPadding(context)),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ResponsiveUtil.responsiveBuilder(
                              context: context,
                              // Mobile layout (stacked columns)
                              mobile: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    const SizedBox(height: 16),
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
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),

                              // Tablet layout (optional)
                              tablet: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AeratorComparisonCard(
                                            l10n: l10n,
                                            results: results,
                                            winnerLabel: winnerLabel,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: EquilibriumPricesCard(
                                            l10n: l10n,
                                            equilibriumPrices:
                                                equilibriumPrices,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: CostVisualizationCard(
                                            l10n: l10n,
                                            results: results,
                                            winnerLabel: winnerLabel,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: CostEvolutionCard(
                                            l10n: l10n,
                                            results: results,
                                            winnerLabel: winnerLabel,
                                            surveyData: surveyData,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),

                              // Desktop layout (side-by-side columns)
                              desktop: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                            equilibriumPrices:
                                                equilibriumPrices,
                                          ),
                                          const SizedBox(height: 80),
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
                                          const SizedBox(height: 80),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Floating action buttons that adapt to screen size
                      Positioned(
                        bottom: 16,
                        left: ResponsiveUtil.isMobile(context) ? null : 16,
                        right: ResponsiveUtil.isMobile(context) ? null : null,
                        child: ResponsiveUtil.isMobile(context)
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FloatingActionButton.extended(
                                    heroTag: "pdf",
                                    icon: const Icon(Icons.picture_as_pdf,
                                        size: 16),
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    label: Text(l10n.exportToPdf),
                                    onPressed: () async {
                                      final pdfData =
                                          await PdfGenerator.generatePdf(
                                              l10n,
                                              results,
                                              winnerLabel,
                                              tod,
                                              annualRevenue,
                                              surveyData,
                                              apiResults);
                                      await Printing.layoutPdf(
                                        onLayout:
                                            (PdfPageFormat format) async =>
                                                pdfData,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.extended(
                                    heroTag: "new",
                                    icon: const Icon(Icons.refresh, size: 16),
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    label: Text(l10n.newComparison),
                                    onPressed: () =>
                                        appState.navigateToSurvey(),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(l10n.newComparison),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => appState.navigateToSurvey(),
                              ),
                      ),

                      // PDF export button - only shown on tablet/desktop
                      if (!ResponsiveUtil.isMobile(context))
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text(l10n.exportToPdf),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                                onLayout: (PdfPageFormat format) async =>
                                    pdfData,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

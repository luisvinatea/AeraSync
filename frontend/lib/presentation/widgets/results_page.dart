import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/app_state.dart';

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

  // Format currency in thousands with 2 decimal places
  String formatCurrencyK(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  // Helper function to format currency values in thousands with 2 decimal places
  static String formatCurrencyK(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                _CostVisualizationCard(
                  l10n: l10n,
                  results: results,
                  winnerLabel: winnerLabel,
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
              ],
            ),
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
    // Local helper for detail rows
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
              Text(
                '${l10n.totalDemandLabel}: ${tod.toStringAsFixed(2)} kg O₂/h',
                style: Theme.of(context).textTheme.bodyMedium,
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
                l10n.saeLabel, '${result.sae.toStringAsFixed(2)} kg O₂/kWh'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatPaybackPeriod(double paybackYears, AppLocalizations l10n,
      {bool isWinner = false}) {
    // Treat extremely large values (e.g., > 100 years) as effectively infinite
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
    if (k >= 1000) {
      return '${(k / 1000).toStringAsFixed(2)}K';
    }

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
              height: 450, // Increased height from 300 to 450
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 24.0), // Added bottom padding
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxCost() * 1.3, // Increased headroom from 1.2 to 1.3
                    barGroups: _getBarGroups(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // Check if the value is within our results range
                            if (value >= 0 && value < results.length) {
                              final name = results[value.toInt()].name;
                              final isWinner = name == winnerLabel;

                              // Display "Winner" for winner aerator and just "Other" for others
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
                          reservedSize: 60, // Increased from 40 to give more space
                          interval: _calculateYAxisInterval(), // Dynamic interval based on max value
                          getTitlesWidget: (value, meta) {
                            // Format values in thousands (K) with better spacing
                            if (value % _calculateYAxisInterval() != 0) {
                              return const SizedBox.shrink(); // Only show labels at interval points
                            }
                            
                            final formattedValue = value >= 1000
                                ? '${(value / 1000).toStringAsFixed(0)}K' // Remove decimal for cleaner display
                                : value.toInt().toString();
                                
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '\$$formattedValue',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12, // Increased from 10 for better readability
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
                      horizontalInterval: _calculateYAxisInterval(), // Match the interval of the labels
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
                      handleBuiltInTouches: false, // Disable built-in touch handling
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white.withAlpha(204), // Changed from withOpacity to withAlpha
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final result = results[groupIndex];
                          String component;
                          double value;
                          
                          // Get the specific stack item that was clicked
                          if (rodIndex < 0 || rodIndex >= rod.rodStackItems.length) {
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
                            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                        if (response == null || response.spot == null) return;
                        
                        // Only respond to tap down events for clicking
                        if (event is! FlTapDownEvent) return;
                        
                        // We don't need to do anything with these variables since we're just using the
                        // touch event to show tooltips. The fl_chart library will handle the tooltips.
                        
                        // Note: These variables were previously unused and causing lint warnings
                        // final groupIndex = response.spot!.touchedBarGroupIndex;
                        // final rodIndex = response.spot!.touchedRodDataIndex;
                        // final result = results[groupIndex];
                        // final touchedY = response.spot!.touchedStackItemIndex;
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
            width: 100, // Increased from 25 to 75 (3x wider)
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
    
    // Select an appropriate interval based on the max cost
    if (maxCost <= 100) return 20;  
    if (maxCost <= 500) return 100;
    if (maxCost <= 1000) return 200;
    if (maxCost <= 5000) return 1000;
    if (maxCost <= 10000) return 2000;
    if (maxCost <= 50000) return 10000;
    if (maxCost <= 100000) return 20000;
    return maxCost / 5; // Default to 5 divisions
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      annualMaintenanceCost: (json['annual_maintenance_cost'] as num?)?.toDouble() ?? 0.0,
      annualReplacementCost: (json['annual_replacement_cost'] as num?)?.toDouble() ?? 0.0,
      totalAnnualCost: (json['total_annual_cost'] as num?)?.toDouble() ?? 0.0,
      costPercentRevenue: (json['cost_percent_revenue'] as num?)?.toDouble() ?? 0.0,
      aeratorsPerHa: (json['aerators_per_ha'] as num?)?.toDouble() ?? 0.0,
      hpPerHa: (json['hp_per_ha'] as num?)?.toDouble() ?? 0.0,
      sae: (json['sae'] as num?)?.toDouble() ?? 0.0,
      npvSavings: (json['npv_savings'] as num?)?.toDouble() ?? 0.0,
      paybackYears: (json['payback_years'] as num?)?.toDouble() ?? double.infinity,
      roiPercent: (json['roi_percent'] as num?)?.toDouble() ?? 0.0,
      irr: (json['irr'] as num?)?.toDouble() ?? -100.0,
      profitabilityK: (json['profitability_k'] as num?)?.toDouble() ?? 0.0,
      opportunityCost: (json['opportunity_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

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
                Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
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
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/survey'),
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
    final annualRevenue = (apiResults['annual_revenue'] as num?)?.toDouble() ?? 0.0;
    final equilibriumPrices = apiResults['equilibriumPrices'] as Map<String, dynamic>? ?? {};

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
                _SummaryCard(
                  l10n: l10n,
                  tod: tod,
                  winnerLabel: winnerLabel,
                  annualRevenue: annualRevenue,
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
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/survey'),
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

class _SummaryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final double tod;
  final String winnerLabel;
  final double annualRevenue;

  const _SummaryCard({
    required this.l10n,
    required this.tod,
    required this.winnerLabel,
    required this.annualRevenue,
  });

  @override
  Widget build(BuildContext context) {
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
                '${l10n.annualRevenueLabel}: \$${annualRevenue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${l10n.recommendedAerator}: $winnerLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
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
                          DataColumn(label: Text(l10n.initialCostLabel)),
                          DataColumn(label: Text(l10n.annualCostLabel)),
                          DataColumn(label: Text(l10n.npvSavingsLabel)),
                          DataColumn(label: Text(l10n.saeLabel)),
                          DataColumn(label: Text(l10n.paybackPeriod)),
                          DataColumn(label: Text(l10n.roiLabel)),
                        ],
                        rows: results.map((result) {
                          final isWinner = result.name == winnerLabel;
                          return DataRow(
                            color: isWinner ? WidgetStateProperty.all(Colors.green.withOpacity(0.1)) : null,
                            cells: [
                              DataCell(Text(result.name,
                                  style: isWinner ? const TextStyle(fontWeight: FontWeight.bold) : null)),
                              DataCell(Text(result.numAerators.toString())),
                              DataCell(Text('\$${result.totalInitialCost.toStringAsFixed(2)}')),
                              DataCell(Text('\$${result.totalAnnualCost.toStringAsFixed(2)}')),
                              DataCell(Text('\$${result.npvSavings.toStringAsFixed(2)}')),
                              DataCell(Text(result.sae.toStringAsFixed(2))),
                              DataCell(Text(
                                  _formatPaybackPeriod(result.paybackYears, l10n, isWinner: result.name == winnerLabel))),
                              DataCell(Text(
                                  _formatROI(result.roiPercent, l10n, isWinner: result.name == winnerLabel))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.detailedResults,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...results.map((result) => _buildDetailedResultCard(context, result)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.recommended,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(),
            _detailRow(l10n.unitsNeeded, result.numAerators.toString()),
            _detailRow(l10n.aeratorsPerHaLabel, result.aeratorsPerHa.toStringAsFixed(2)),
            _detailRow(l10n.horsepowerPerHaLabel, '${result.hpPerHa.toStringAsFixed(2)} hp/ha'),
            _detailRow(l10n.initialCostLabel, '\$${result.totalInitialCost.toStringAsFixed(2)}'),
            _detailRow(l10n.annualCostLabel, '\$${result.totalAnnualCost.toStringAsFixed(2)}'),
            _detailRow(l10n.costPercentRevenueLabel, '${result.costPercentRevenue.toStringAsFixed(2)}%'),
            _detailRow(l10n.annualEnergyCostLabel, '\$${result.annualEnergyCost.toStringAsFixed(2)}'),
            _detailRow(l10n.annualMaintenanceCostLabel, '\$${result.annualMaintenanceCost.toStringAsFixed(2)}'),
            _detailRow(l10n.annualReplacementCostLabel, '\$${result.annualReplacementCost.toStringAsFixed(2)}'),
            if (result.opportunityCost > 0)
              _detailRow(l10n.opportunityCostLabel, '\$${result.opportunityCost.toStringAsFixed(2)}'),
            const Divider(),
            _detailRow(l10n.npvSavingsLabel, '\$${result.npvSavings.toStringAsFixed(2)}'),
            _detailRow(
                l10n.paybackPeriod,
                _formatPaybackPeriod(result.paybackYears, l10n, isWinner: result.name == winnerLabel)),
            _detailRow(
                l10n.roiLabel,
                _formatROI(result.roiPercent, l10n, isWinner: result.name == winnerLabel)),
            _detailRow(
                l10n.irrLabel,
                _formatIRR(result.irr, l10n, isWinner: result.name == winnerLabel)),
            _detailRow(
                l10n.profitabilityCoefficient,
                _formatProfitabilityK(result.profitabilityK, l10n, isWinner: result.name == winnerLabel)),
          ],
        ),
      ),
    );
  }

  String _formatPaybackPeriod(double paybackYears, AppLocalizations l10n, {bool isWinner = false}) {
    if (!paybackYears.isFinite || (paybackYears >= 100 && !isWinner)) {
      return l10n.notApplicable;
    }
    
    // For small periods (less than 30 days), show in days
    if (paybackYears < 0.0822) { // ~30 days
      final days = (paybackYears * 365).round();
      return '$days ${l10n.days}';
    }
    
    // For periods between 30 days and 1 year, show in months
    if (paybackYears < 1) {
      final months = (paybackYears * 12).round();
      return '$months ${l10n.months}';
    }
    
    // For periods over 1 year, show in years with 1 decimal place
    return '${paybackYears.toStringAsFixed(1)} ${l10n.years}';
  }

  String _formatROI(double roi, AppLocalizations l10n, {bool isWinner = false}) {
    if (roi <= 0 && !isWinner) {
      return l10n.notApplicable;
    }
    
    // Format high ROI values with K or M suffix for better readability
    if (roi >= 1000) {
      if (roi >= 1000000) {
        return '${(roi / 1000000).toStringAsFixed(1)}M%';
      }
      return '${(roi / 1000).toStringAsFixed(1)}K%';
    }
    
    return '${roi.toStringAsFixed(1)}%';
  }

  String _formatIRR(double irr, AppLocalizations l10n, {bool isWinner = false}) {
    if (irr <= -50 && !isWinner) {
      return l10n.notApplicable;
    }
    
    // Format high IRR values with K or M suffix for better readability
    if (irr >= 1000) {
      if (irr >= 1000000) {
        return '${(irr / 1000000).toStringAsFixed(1)}M%';
      }
      return '${(irr / 1000).toStringAsFixed(1)}K%';
    }
    
    return '${irr.toStringAsFixed(1)}%';
  }

  String _formatProfitabilityK(double k, AppLocalizations l10n, {bool isWinner = false}) {
    if (!k.isFinite && !isWinner) {
      return l10n.notApplicable;
    }
    
    // Format high k values with K or M suffix for better readability
    if (k >= 1000) {
      if (k >= 1000000) {
        return '${(k / 1000000).toStringAsFixed(1)}M';
      }
      return '${(k / 1000).toStringAsFixed(1)}K';
    }
    
    return k.toStringAsFixed(2);
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
                final price = (entry.value is num) ? entry.value.toDouble() : 0.0;
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
                          '\$${price.toStringAsFixed(2)}',
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
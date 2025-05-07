class AeratorResult {
  final String name;
  final int numAerators;
  final double aeratorsPerHa;
  final double totalPowerHp;
  final double hpPerHa;
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
  final double sae;
  final double opportunityCost;
  final double costPerKgO2;

  AeratorResult({
    required this.name,
    required this.numAerators,
    required this.aeratorsPerHa,
    required this.totalPowerHp,
    required this.hpPerHa,
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
    required this.sae,
    required this.opportunityCost,
    required this.costPerKgO2,
  });

  factory AeratorResult.fromJson(Map<String, dynamic> json) {
    return AeratorResult(
      name: json['name'] ?? 'Unknown',
      numAerators: json['num_aerators'] is int
          ? json['num_aerators']
          : (json['num_aerators'] as num?)?.toInt() ?? 0,
      aeratorsPerHa: (json['aerators_per_ha'] as num?)?.toDouble() ?? 0.0,
      totalPowerHp: (json['total_power_hp'] as num?)?.toDouble() ?? 0.0,
      hpPerHa: (json['hp_per_ha'] as num?)?.toDouble() ?? 0.0,
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
      sae: (json['sae'] as num?)?.toDouble() ?? 0.0,
      opportunityCost: (json['opportunity_cost'] as num?)?.toDouble() ?? 0.0,
      costPerKgO2: (json['cost_per_kg_o2'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'num_aerators': numAerators,
      'aerators_per_ha': aeratorsPerHa,
      'total_power_hp': totalPowerHp,
      'hp_per_ha': hpPerHa,
      'total_initial_cost': totalInitialCost,
      'annual_energy_cost': annualEnergyCost,
      'annual_maintenance_cost': annualMaintenanceCost,
      'annual_replacement_cost': annualReplacementCost,
      'total_annual_cost': totalAnnualCost,
      'cost_percent_revenue': costPercentRevenue,
      'npv_savings': npvSavings,
      'payback_years': paybackYears,
      'roi_percent': roiPercent,
      'irr': irr,
      'profitability_k': profitabilityK,
      'sae': sae,
      'opportunity_cost': opportunityCost,
      'cost_per_kg_o2': costPerKgO2,
    };
  }

  String formatCurrencyK(double value) {
    if (value >= 1_000_000) {
      return '\$${(value / 1_000_000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(2)}K';
    return '\$${value.toStringAsFixed(2)}';
  }
}

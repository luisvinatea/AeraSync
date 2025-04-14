import 'package:flutter/foundation.dart';

class Aerator {
  final String? brand;
  final String? model;
  final double power;
  final String sotrSource;
  final double? sotr;
  final double? klat;
  final double cost;
  final double durability;
  final double maintenance;

  Aerator({
    this.brand,
    this.model,
    required this.power,
    required this.sotrSource,
    this.sotr,
    this.klat,
    required this.cost,
    required this.durability,
    required this.maintenance,
  });

  factory Aerator.fromJson(Map<String, dynamic> json) {
    return Aerator(
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      power: (json['power'] as num).toDouble(),
      sotrSource: json['sotrSource'] as String,
      sotr: json['sotr'] != null ? (json['sotr'] as num).toDouble() : null,
      klat: json['klat'] != null ? (json['klat'] as num).toDouble() : null,
      cost: (json['cost'] as num).toDouble(),
      durability: (json['durability'] as num).toDouble(),
      maintenance: (json['maintenance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'power': power,
      'sotrSource': sotrSource,
      'sotr': sotr,
      'klat': klat,
      'cost': cost,
      'durability': durability,
      'maintenance': maintenance,
    };
  }
}

class FarmData {
  final double totalArea;
  final double productionPerHa;
  final double cyclesPerYear;

  FarmData({
    required this.totalArea,
    required this.productionPerHa,
    required this.cyclesPerYear,
  });

  factory FarmData.fromJson(Map<String, dynamic> json) {
    return FarmData(
      totalArea: (json['totalArea'] as num).toDouble(),
      productionPerHa: (json['productionPerHa'] as num).toDouble(),
      cyclesPerYear: (json['cyclesPerYear'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalArea': totalArea,
      'productionPerHa': productionPerHa,
      'cyclesPerYear': cyclesPerYear,
    };
  }
}

class OxygenDemandData {
  final double temperature;
  final double salinity;
  final double pondDepth;
  final double shrimpWeight;

  OxygenDemandData({
    required this.temperature,
    required this.salinity,
    required this.pondDepth,
    required this.shrimpWeight,
  });

  factory OxygenDemandData.fromJson(Map<String, dynamic> json) {
    return OxygenDemandData(
      temperature: (json['temperature'] as num).toDouble(),
      salinity: (json['salinity'] as num).toDouble(),
      pondDepth: (json['pondDepth'] as num).toDouble(),
      shrimpWeight: (json['shrimpWeight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'salinity': salinity,
      'pondDepth': pondDepth,
      'shrimpWeight': shrimpWeight,
    };
  }
}

class FinancialData {
  final double shrimpPrice;
  final double energyCost;
  final double operatingHours;
  final double discountRate;
  final double inflationRate;
  final double analysisHorizon;

  FinancialData({
    required this.shrimpPrice,
    required this.energyCost,
    required this.operatingHours,
    required this.discountRate,
    required this.inflationRate,
    required this.analysisHorizon,
  });

  factory FinancialData.fromJson(Map<String, dynamic> json) {
    return FinancialData(
      shrimpPrice: (json['shrimpPrice'] as num).toDouble(),
      energyCost: (json['energyCost'] as num).toDouble(),
      operatingHours: (json['operatingHours'] as num).toDouble(),
      discountRate: (json['discountRate'] as num).toDouble(),
      inflationRate: (json['inflationRate'] as num).toDouble(),
      analysisHorizon: (json['analysisHorizon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shrimpPrice': shrimpPrice,
      'energyCost': energyCost,
      'operatingHours': operatingHours,
      'discountRate': discountRate,
      'inflationRate': inflationRate,
      'analysisHorizon': analysisHorizon,
    };
  }
}

class AeratorResult {
  final String name;
  final double sae;
  final double numAerators;
  final double totalAnnualCost;
  final double costPercentage;
  final double npv;
  final double irr;
  final double paybackPeriod;
  final double roi;
  final double profitabilityIndex;

  AeratorResult({
    required this.name,
    required this.sae,
    required this.numAerators,
    required this.totalAnnualCost,
    required this.costPercentage,
    required this.npv,
    required this.irr,
    required this.paybackPeriod,
    required this.roi,
    required this.profitabilityIndex,
  });

  factory AeratorResult.fromJson(Map<String, dynamic> json) {
    return AeratorResult(
      name: json['name'] as String,
      sae: (json['sae'] as num).toDouble(),
      numAerators: (json['numAerators'] as num).toDouble(),
      totalAnnualCost: (json['totalAnnualCost'] as num).toDouble(),
      costPercentage: (json['costPercentage'] as num).toDouble(),
      npv: (json['npv'] as num).toDouble(),
      irr: (json['irr'] as num).toDouble(),
      paybackPeriod: (json['paybackPeriod'] as num).toDouble(),
      roi: (json['roi'] as num).toDouble(),
      profitabilityIndex: (json['profitabilityIndex'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sae': sae,
      'numAerators': numAerators,
      'totalAnnualCost': totalAnnualCost,
      'costPercentage': costPercentage,
      'npv': npv,
      'irr': irr,
      'paybackPeriod': paybackPeriod,
      'roi': roi,
      'profitabilityIndex': profitabilityIndex,
    };
  }
}

class AppState extends ChangeNotifier {
  String? _error;
  bool _isLoading = false;
  List<Aerator>? _aerators;
  FarmData? _farmData;
  OxygenDemandData? _oxygenDemandData;
  FinancialData? _financialData;
  List<AeratorResult>? _aeratorResults;
  double? _tod;
  double? _annualRevenue;
  Map<String, dynamic>? _apiResults;

  String? get error => _error;
  bool get isLoading => _isLoading;
  List<Aerator>? get aerators => _aerators;
  FarmData? get farmData => _farmData;
  OxygenDemandData? get oxygenDemandData => _oxygenDemandData;
  FinancialData? get financialData => _financialData;
  List<AeratorResult>? get aeratorResults => _aeratorResults;
  double? get tod => _tod;
  double? get annualRevenue => _annualRevenue;
  Map<String, dynamic>? get apiResults => _apiResults;

  Map<String, dynamic>? get surveyData {
    if (_aerators == null ||
        _farmData == null ||
        _oxygenDemandData == null ||
        _financialData == null ||
        _aeratorResults == null) {
      return null;
    }
    return {
      'aerators': _aerators!.map((a) => a.toJson()).toList(),
      'farmData': _farmData!.toJson(),
      'oxygenDemandData': _oxygenDemandData!.toJson(),
      'financialData': _financialData!.toJson(),
      'aeratorResults': _aeratorResults!.map((r) => r.toJson()).toList(),
      'tod': _tod,
      'annualRevenue': _annualRevenue,
      'apiResults': _apiResults,
    };
  }

  void setSurveyData(Map<String, dynamic> data) {
    _aerators = (data['aerators'] as List<dynamic>)
        .map((a) => Aerator.fromJson(Map<String, dynamic>.from(a)))
        .toList();
    _farmData = FarmData.fromJson(Map<String, dynamic>.from(data['farmData']));
    _oxygenDemandData =
        OxygenDemandData.fromJson(Map<String, dynamic>.from(data['oxygenDemandData']));
    _financialData =
        FinancialData.fromJson(Map<String, dynamic>.from(data['financialData']));
    _aeratorResults = (data['aeratorResults'] as List<dynamic>)
        .map((r) => AeratorResult.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    _tod = (data['tod'] as num?)?.toDouble();
    _annualRevenue = (data['annualRevenue'] as num?)?.toDouble();
    _apiResults = data['apiResults'] != null
        ? Map<String, dynamic>.from(data['apiResults'])
        : null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (_isLoading) {
        _error = null;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    print("AppState disposing.");
    _aerators = null;
    _farmData = null;
    _oxygenDemandData = null;
    _financialData = null;
    _aeratorResults = null;
    _tod = null;
    _annualRevenue = null;
    _apiResults = null;
    super.dispose();
  }

  initialize() {}
}
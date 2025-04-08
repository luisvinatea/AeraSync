// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AeraSync';

  @override
  String get aeratorComparisonCalculator => 'Aerator Comparison Calculator';

  @override
  String get totalOxygenDemandLabel => 'Total Oxygen Demand (kg O₂/h)';

  @override
  String get sotrAerator1Label => 'SOTR Aerator 1 (kg O₂/h per aerator)';

  @override
  String get sotrAerator2Label => 'SOTR Aerator 2 (kg O₂/h per aerator)';

  @override
  String get priceAerator1Label => 'Price Aerator 1 (USD per aerator)';

  @override
  String get priceAerator2Label => 'Price Aerator 2 (USD per aerator)';

  @override
  String get maintenanceCostAerator1Label => 'Maintenance Cost Aerator 1 (USD/year per aerator)';

  @override
  String get maintenanceCostAerator2Label => 'Maintenance Cost Aerator 2 (USD/year per aerator)';

  @override
  String get durabilityAerator1Label => 'Durability Aerator 1 (years)';

  @override
  String get durabilityAerator2Label => 'Durability Aerator 2 (years)';

  @override
  String get annualEnergyCostLabel => 'Annual Energy Cost (USD/year per aerator)';

  @override
  String get numberOfAerator1UnitsLabel => 'Number of Aerator 1 Units';

  @override
  String get numberOfAerator2UnitsLabel => 'Number of Aerator 2 Units';

  @override
  String get totalAnnualCostAerator1Label => 'Total Annual Cost Aerator 1 (USD/year)';

  @override
  String get totalAnnualCostAerator2Label => 'Total Annual Cost Aerator 2 (USD/year)';

  @override
  String get equilibriumPriceP2Label => 'Equilibrium Price P₂ (USD)';

  @override
  String get actualPriceP2Label => 'Actual Price P₂ (USD)';

  @override
  String get aeratorEstimationCalculator => 'Aerator Estimation Calculator';

  @override
  String get startO2ColumnLabel => 'Start O₂ Column (mg/L)';

  @override
  String get finalO2ColumnLabel => 'Final O₂ Column (mg/L)';

  @override
  String get startO2BottomLabel => 'Start O₂ Bottom (mg/L)';

  @override
  String get finalO2BottomLabel => 'Final O₂ Bottom (mg/L)';

  @override
  String get timeLabel => 'Time (hours)';

  @override
  String get volumeLabel => 'Volume (m³)';

  @override
  String get sotrLabel => 'SOTR (kg O₂/h)';

  @override
  String get pondDepthLabel => 'Pond Depth (m)';

  @override
  String get shrimpRespirationLabel => 'Shrimp Respiration (mg/L/h)';

  @override
  String get columnRespirationLabel => 'Column Respiration (mg/L/h)';

  @override
  String get bottomRespirationLabel => 'Bottom Respiration (mg/L/h)';

  @override
  String get totalOxygenDemandMgPerLPerHLabel => 'Total Oxygen Demand (mg/L/h)';

  @override
  String get todLabel => 'TOD (kg O₂/h)';

  @override
  String get todLabelShort => 'TOD';

  @override
  String get todPerHectareLabel => 'TOD per Hectare (kg O₂/h/ha)';

  @override
  String get otr20Label => 'OTR20 (kg O₂/h)';

  @override
  String get otrTLabel => 'OTRt (kg O₂/h)';

  @override
  String get otrTLabelShort => 'OTRt';

  @override
  String get numberOfAeratorsPerHectareLabel => 'Number of Aerators per Hectare';

  @override
  String get aeratorsLabelShort => 'Aerators';

  @override
  String get aeratorPerformanceCalculator => 'Aerator Performance Calculator';

  @override
  String get horsepowerLabel => 'Horsepower (HP)';

  @override
  String get t10Label => 'T10 (minutes)';

  @override
  String get t70Label => 'T70 (minutes)';

  @override
  String get electricityCostLabel => 'Electricity Cost (\$/kWh)';

  @override
  String get brandLabel => 'Brand (Optional)';

  @override
  String get aeratorTypeLabel => 'Aerator Type';

  @override
  String get specifyAeratorTypeLabel => 'Specify Aerator Type';

  @override
  String get paddlewheel => 'Paddlewheel';

  @override
  String get propeller => 'Propeller';

  @override
  String get splash => 'Splash';

  @override
  String get diffused => 'Diffused';

  @override
  String get injector => 'Injector';

  @override
  String get other => 'Other';

  @override
  String get dataCollectionConsentLabel => 'I agree to allow my data to be collected safely for research purposes, in accordance with applicable laws.';

  @override
  String get learnMore => 'Learn More';

  @override
  String get forPlottingOnly => 'For plotting only';

  @override
  String get comparisonResults => 'Comparison Results';

  @override
  String get numberOfAeratorsNeeded => 'Number of Aerators Needed';

  @override
  String get totalAnnualCostLabel => 'Total Annual Cost (USD/year)';

  @override
  String get aerator1 => 'Aerator 1';

  @override
  String get aerator2 => 'Aerator 2';

  @override
  String get aerator2MoreCostEffective => 'Aerator 2 is more cost-effective at the current price.';

  @override
  String get aerator1MoreCostEffective => 'Aerator 1 may be more cost-effective at the current price.';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String get error => 'Error';

  @override
  String get calculationFailed => 'Calculation failed';

  @override
  String get calculatorNotInitialized => 'Calculator not initialized';

  @override
  String get specifyAeratorTypeRequired => 'Please specify the aerator type';

  @override
  String get t70MustBeGreaterThanT10 => 'T70 must be greater than T10';

  @override
  String get generic => 'Generic';

  @override
  String get couldNotOpenPrivacyPolicy => 'Could not open privacy policy';

  @override
  String get calculateButton => 'Calculate';

  @override
  String get enterValuesToCalculate => 'Enter values and click Calculate to see results';

  @override
  String get downloadCsvButton => 'Download as CSV (only values)';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String rangeError(Object max, Object min) {
    return 'Must be between $min and $max';
  }

  @override
  String get oxygenDemandCalculator => 'Oxygen Demand Calculator';

  @override
  String get farmAreaLabel => 'Farm Area (ha)';

  @override
  String get farmAreaTooltip => 'Total area of the farm in hectares';

  @override
  String get shrimpBiomassLabel => 'Shrimp Biomass (kg/ha)';

  @override
  String get shrimpBiomassTooltip => 'Biomass of shrimp per hectare';

  @override
  String get waterTemperatureLabel => 'Water Temperature (°C)';

  @override
  String get waterTemperatureTooltip => 'Temperature of the water in the pond';

  @override
  String get salinityLabel => 'Salinity (‰)';

  @override
  String get salinityTooltip => 'Salinity of the water in parts per thousand';

  @override
  String get averageShrimpWeightLabel => 'Average Shrimp Weight (g)';

  @override
  String get averageShrimpWeightTooltip => 'Average weight of the shrimp in grams';

  @override
  String get safetyMarginLabel => 'Safety Margin';

  @override
  String get safetyMarginTooltip => 'Multiplier to account for unexpected oxygen demand';

  @override
  String get respirationRateLabel => 'Respiration Rate (g O₂/kg shrimp/h)';

  @override
  String get oxygenDemandFromShrimpLabel => 'Oxygen Demand from Shrimp (kg O₂/h)';

  @override
  String get environmentalOxygenDemandLabel => 'Environmental Oxygen Demand (kg O₂/h)';

  @override
  String get oxygenDemandResults => 'Oxygen Demand Results';

  @override
  String get totalOxygenDemandCopied => 'Total Oxygen Demand copied to clipboard';

  @override
  String get copyToClipboardTooltip => 'Copy to clipboard';

  @override
  String get totalOxygenDemandTooltip => 'Total oxygen required by the system in kg O₂ per hour';

  @override
  String get sotrAerator1Tooltip => 'Standard Oxygen Transfer Rate for Aerator 1 in kg O₂ per hour per aerator';

  @override
  String get sotrAerator2Tooltip => 'Standard Oxygen Transfer Rate for Aerator 2 in kg O₂ per hour per aerator';

  @override
  String get priceAerator1Tooltip => 'Purchase price of Aerator 1 in USD per unit';

  @override
  String get priceAerator2Tooltip => 'Purchase price of Aerator 2 in USD per unit';

  @override
  String get maintenanceCostAerator1Tooltip => 'Annual maintenance cost for Aerator 1 in USD per year per aerator';

  @override
  String get maintenanceCostAerator2Tooltip => 'Annual maintenance cost for Aerator 2 in USD per year per aerator';

  @override
  String get durabilityAerator1Tooltip => 'Expected lifespan of Aerator 1 in years';

  @override
  String get durabilityAerator2Tooltip => 'Expected lifespan of Aerator 2 in years';

  @override
  String get annualEnergyCostTooltip => 'Annual energy cost for operating one aerator in USD per year';

  @override
  String get startO2ColumnTooltip => 'Initial oxygen concentration in the water column in mg/L';

  @override
  String get finalO2ColumnTooltip => 'Final oxygen concentration in the water column in mg/L';

  @override
  String get startO2BottomTooltip => 'Initial oxygen concentration at the pond bottom in mg/L';

  @override
  String get finalO2BottomTooltip => 'Final oxygen concentration at the pond bottom in mg/L';

  @override
  String get timeTooltip => 'Time duration for the oxygen concentration change in hours';

  @override
  String get volumeTooltip => 'Volume of the pond in cubic meters';

  @override
  String get sotrTooltip => 'Standard Oxygen Transfer Rate of the aerator in kg O₂ per hour';

  @override
  String get pondDepthTooltip => 'Depth of the pond in meters';

  @override
  String get horsepowerTooltip => 'Power rating of the aerator in horsepower (HP)';

  @override
  String get t10Tooltip => 'Time to reach 10% of oxygen saturation in minutes (used for plotting)';

  @override
  String get t70Tooltip => 'Time to reach 70% of oxygen saturation in minutes';

  @override
  String get electricityCostTooltip => 'Cost of electricity per kilowatt-hour in USD';

  @override
  String get equilibriumPriceCopied => 'Equilibrium Price copied to clipboard';

  @override
  String get sotrCopied => 'SOTR copied to clipboard';

  @override
  String get numberOfAeratorsCopied => 'Number of Aerators copied to clipboard';
}

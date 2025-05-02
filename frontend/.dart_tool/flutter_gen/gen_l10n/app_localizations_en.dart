// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AeraSync';

  @override
  String get welcomeToAeraSync => 'Welcome to AeraSync';

  @override
  String get startSurvey => 'Start Survey';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get apiUnreachable => 'Unable to connect to the server. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get dataDisclosure => 'Data Disclosure';

  @override
  String get dataDisclosureMessage => 'We collect anonymous usage data to improve the app.';

  @override
  String get agree => 'Agree';

  @override
  String get learnMore => 'Learn More';

  @override
  String get error => 'Error';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get survey => 'Survey';

  @override
  String get farmAndOxygenDemand => 'Farm and Oxygen Demand';

  @override
  String get aeratorDetails => 'Aerator Details';

  @override
  String get financialAspects => 'Financial Aspects';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get farmFinancialDetails => 'Farm & Financial Details';

  @override
  String get aerator => 'Aerator';

  @override
  String get totalOxygenDemand => 'Total Oxygen Demand';

  @override
  String get farmArea => 'Farm Area';

  @override
  String get energyCost => 'Electricity Cost';

  @override
  String get operatingHours => 'Operating Hours';

  @override
  String get discountRate => 'Discount Rate';

  @override
  String get inflationRate => 'Inflation Rate';

  @override
  String get analysisHorizon => 'Analysis Years';

  @override
  String get safetyMargin => 'Safety Margin';

  @override
  String get name => 'Name';

  @override
  String get horsepower => 'Power';

  @override
  String get sotr => 'Standard Oxygen Transfer Rate';

  @override
  String get cost => 'Cost';

  @override
  String get durability => 'Durability';

  @override
  String get maintenanceCost => 'Maintenance Cost';

  @override
  String get addAerator => 'Add Aerator';

  @override
  String get nameLabel => 'Aerator Name';

  @override
  String get nameTooltip => 'Unique name for the aerator';

  @override
  String get horsepowerLabel => 'Horsepower (hp)';

  @override
  String get horsepowerTooltip => 'Power rating of the aerator in horsepower (0.1 to 100)';

  @override
  String get sotrLabel => 'SOTR (kg O₂/h)';

  @override
  String get sotrTooltip => 'Standard Oxygen Transfer Rate per hour (0.1 to 10)';

  @override
  String get priceLabel => 'Price (USD)';

  @override
  String get priceAeratorTooltip => 'Initial purchase cost of the aerator in USD (0 to 10000)';

  @override
  String get durabilityLabel => 'Durability (years)';

  @override
  String get durabilityAeratorTooltip => 'Expected lifespan of the aerator in years (0.1 to 20)';

  @override
  String get maintenanceCostLabel => 'Annual Maintenance Cost (USD)';

  @override
  String get maintenanceCostAeratorTooltip => 'Annual maintenance cost of the aerator in USD (0 to 1000)';

  @override
  String get farmAreaLabel => 'Total Farm Area (ha)';

  @override
  String get farmAreaTooltip => 'Total area of the farm in hectares (0.1 to 100000)';

  @override
  String get waterTemperatureLabel => 'Water Temperature (°C)';

  @override
  String get waterTemperatureTooltip => 'Average water temperature in Celsius (0 to 40)';

  @override
  String get salinityLabel => 'Salinity (ppt)';

  @override
  String get salinityTooltip => 'Water salinity in parts per thousand (0 to 40)';

  @override
  String get pondDepthLabel => 'Pond Depth (m)';

  @override
  String get pondDepthTooltip => 'Average depth of the ponds in meters (0.5 to 5)';

  @override
  String get averageShrimpWeightLabel => 'Average Shrimp Weight (g)';

  @override
  String get averageShrimpWeightTooltip => 'Average weight of shrimp in grams (0 to 50)';

  @override
  String get shrimpBiomassLabel => 'Shrimp Biomass (kg/ha)';

  @override
  String get shrimpBiomassTooltip => 'Biomass of shrimp per hectare (0 to 100000)';

  @override
  String get safetyMarginLabel => 'Safety Margin (%)';

  @override
  String get safetyMarginTooltip => 'Safety margin for calculations (0 to 100)';

  @override
  String get shrimpPriceLabel => 'Shrimp Price (USD/kg)';

  @override
  String get shrimpPriceTooltip => 'Market price of shrimp per kilogram (0.1 to 50)';

  @override
  String get electricityCostLabel => 'Electricity Cost (USD/kWh)';

  @override
  String get electricityCostTooltip => 'Cost of electricity per kilowatt-hour (0 to 1)';

  @override
  String get operatingHoursLabel => 'Operating Hours per Year';

  @override
  String get operatingHoursTooltip => 'Total hours aerators run per year (0 to 8760)';

  @override
  String get discountRateLabel => 'Discount Rate (%)';

  @override
  String get discountRateTooltip => 'Discount rate for financial calculations (0 to 100)';

  @override
  String get inflationRateLabel => 'Inflation Rate (%)';

  @override
  String get inflationRateTooltip => 'Annual inflation rate (0 to 100)';

  @override
  String get analysisHorizonLabel => 'Analysis Horizon (years)';

  @override
  String get analysisHorizonTooltip => 'Time period for financial analysis (1 to 50)';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String rangeError(String min, String max) {
    return 'Value must be between $min and $max';
  }

  @override
  String minimumValueError(String value) {
    return 'Please enter a value greater than or equal to $value';
  }

  @override
  String get optionalField => 'Optional';

  @override
  String get minimumAeratorsError => 'At least two aerators are required';

  @override
  String submissionFailed(String error) {
    return 'Failed to submit survey: $error';
  }

  @override
  String get surveyError => 'Error submitting survey';

  @override
  String get results => 'Results';

  @override
  String get summaryMetrics => 'Summary Metrics';

  @override
  String get totalDemandLabel => 'Total Oxygen Demand';

  @override
  String get recommendedAerator => 'Recommended Aerator';

  @override
  String get aeratorComparisonResults => 'Aerator Comparison Results';

  @override
  String get equilibriumPrices => 'Equilibrium Prices';

  @override
  String get equilibriumPriceLabel => 'Equilibrium Price';

  @override
  String get noEquilibriumPrices => 'No equilibrium prices available';

  @override
  String get aeratorLabel => 'Aerator';

  @override
  String get unitsNeeded => 'Units Needed';

  @override
  String get initialCostLabel => 'Initial Cost';

  @override
  String get annualEnergyCostLabel => 'Annual Energy Cost';

  @override
  String get annualMaintenanceCostLabel => 'Annual Maintenance Cost';

  @override
  String get npvCostLabel => 'NPV of Costs';

  @override
  String get saeLabel => 'SAE (kg O₂/kWh)';

  @override
  String get paybackPeriod => 'Payback Period';

  @override
  String get roiLabel => 'ROI';

  @override
  String get irrLabel => 'IRR';

  @override
  String get profitabilityCoefficient => 'Profitability Coefficient';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get summaryMetricsDescription => 'Summary metrics for aerator comparison';

  @override
  String get aeratorComparisonResultsDescription => 'Comparison table of aerator results';

  @override
  String get equilibriumPricesDescription => 'Equilibrium prices for non-recommended aerators';

  @override
  String get noDataAvailableDescription => 'No data available to display';

  @override
  String get todLabel => 'Total Oxygen Demand';

  @override
  String get costLabel => 'Cost (USD)';

  @override
  String get npvSavingsLabel => 'NPV Savings';

  @override
  String get cultureDaysLabel => 'Culture Days';

  @override
  String get pondDensityLabel => 'Pond Density';

  @override
  String get temperatureLabel => 'Water Temperature';

  @override
  String get surveySubmissionSuccessful => 'Survey submission was successful';

  @override
  String get returnToSurvey => 'Return to Survey';

  @override
  String get newComparison => 'New Comparison';

  @override
  String get annualRevenueLabel => 'Annual Revenue';

  @override
  String get annualCostLabel => 'Annual Cost';

  @override
  String get notApplicable => 'N/A';

  @override
  String get years => 'years';

  @override
  String get detailedResults => 'Detailed Results';

  @override
  String get recommended => 'Recommended';

  @override
  String get aeratorsPerHaLabel => 'Aerators per Hectare';

  @override
  String get horsepowerPerHaLabel => 'Horsepower per Hectare';

  @override
  String get costPercentRevenueLabel => 'Cost % of Revenue';

  @override
  String get annualReplacementCostLabel => 'Annual Replacement Cost';

  @override
  String get opportunityCostLabel => 'Opportunity Cost';

  @override
  String get equilibriumPriceExplanation => 'Price at which this aerator becomes financially equivalent to the recommended option';

  @override
  String get days => 'Days';

  @override
  String get months => 'Months';
}

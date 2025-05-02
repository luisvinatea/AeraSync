import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'AeraSync'**
  String get appTitle;

  /// Welcome message on home page
  ///
  /// In en, this message translates to:
  /// **'Welcome to AeraSync'**
  String get welcomeToAeraSync;

  /// Button to start survey
  ///
  /// In en, this message translates to:
  /// **'Start Survey'**
  String get startSurvey;

  /// Label for the language selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Label indicating the API is unreachable
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Please try again later.'**
  String get apiUnreachable;

  /// Button to retry API health check
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title for the data disclosure popup
  ///
  /// In en, this message translates to:
  /// **'Data Disclosure'**
  String get dataDisclosure;

  /// Message explaining data collection in the disclosure popup
  ///
  /// In en, this message translates to:
  /// **'We collect anonymous usage data to improve the app.'**
  String get dataDisclosureMessage;

  /// Label for the agree button in the disclosure popup
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// Label for the learn more link in the disclosure popup
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// Label for error messages
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Label for dismissing error messages
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Title for the survey page
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get survey;

  /// Title for the farm specifications and oxygen demand section
  ///
  /// In en, this message translates to:
  /// **'Farm and Oxygen Demand'**
  String get farmAndOxygenDemand;

  /// Title for the aerator details section in the survey
  ///
  /// In en, this message translates to:
  /// **'Aerator Details'**
  String get aeratorDetails;

  /// Title for the financial aspects section
  ///
  /// In en, this message translates to:
  /// **'Financial Aspects'**
  String get financialAspects;

  /// Label for the back button in the survey stepper
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Label for the next button in the survey stepper
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Label for the submit button to process the survey
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Title for the farm and financial details section
  ///
  /// In en, this message translates to:
  /// **'Farm & Financial Details'**
  String get farmFinancialDetails;

  /// Label for the aerator section
  ///
  /// In en, this message translates to:
  /// **'Aerator'**
  String get aerator;

  /// Label for the total oxygen demand input field
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand'**
  String get totalOxygenDemand;

  /// Label for the farm area input field
  ///
  /// In en, this message translates to:
  /// **'Farm Area'**
  String get farmArea;

  /// Label for the electricity cost input field
  ///
  /// In en, this message translates to:
  /// **'Electricity Cost'**
  String get energyCost;

  /// Label for the operating hours input field
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours;

  /// Label for the discount rate input field
  ///
  /// In en, this message translates to:
  /// **'Discount Rate'**
  String get discountRate;

  /// Label for the inflation rate input field
  ///
  /// In en, this message translates to:
  /// **'Inflation Rate'**
  String get inflationRate;

  /// Label for the analysis horizon input field
  ///
  /// In en, this message translates to:
  /// **'Analysis Years'**
  String get analysisHorizon;

  /// Label for the safety margin input field
  ///
  /// In en, this message translates to:
  /// **'Safety Margin'**
  String get safetyMargin;

  /// Label for the name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for the horsepower input field
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get horsepower;

  /// Label for the Standard Oxygen Transfer Rate input field
  ///
  /// In en, this message translates to:
  /// **'Standard Oxygen Transfer Rate'**
  String get sotr;

  /// Label for the cost input field
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// Label for the durability input field
  ///
  /// In en, this message translates to:
  /// **'Durability'**
  String get durability;

  /// Label for the maintenance cost input field
  ///
  /// In en, this message translates to:
  /// **'Maintenance Cost'**
  String get maintenanceCost;

  /// Label for the button to add a new aerator
  ///
  /// In en, this message translates to:
  /// **'Add Aerator'**
  String get addAerator;

  /// Label for the aerator name input field
  ///
  /// In en, this message translates to:
  /// **'Aerator Name'**
  String get nameLabel;

  /// Tooltip for the aerator name input field
  ///
  /// In en, this message translates to:
  /// **'Unique name for the aerator'**
  String get nameTooltip;

  /// Label for the power rating of the aerator in horsepower
  ///
  /// In en, this message translates to:
  /// **'Horsepower (hp)'**
  String get horsepowerLabel;

  /// Tooltip for the aerator horsepower input field
  ///
  /// In en, this message translates to:
  /// **'Power rating of the aerator in horsepower (0.1 to 100)'**
  String get horsepowerTooltip;

  /// Label for the Standard Oxygen Transfer Rate of the aerator in kg O₂ per hour
  ///
  /// In en, this message translates to:
  /// **'SOTR (kg O₂/h)'**
  String get sotrLabel;

  /// Tooltip for the SOTR input field
  ///
  /// In en, this message translates to:
  /// **'Standard Oxygen Transfer Rate per hour (0.1 to 10)'**
  String get sotrTooltip;

  /// Label for the aerator price input field
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get priceLabel;

  /// Tooltip for the aerator price input field
  ///
  /// In en, this message translates to:
  /// **'Initial purchase cost of the aerator in USD (0 to 10000)'**
  String get priceAeratorTooltip;

  /// Label for the aerator durability input field
  ///
  /// In en, this message translates to:
  /// **'Durability (years)'**
  String get durabilityLabel;

  /// Tooltip for the aerator durability input field
  ///
  /// In en, this message translates to:
  /// **'Expected lifespan of the aerator in years (0.1 to 20)'**
  String get durabilityAeratorTooltip;

  /// Label for the aerator maintenance cost input field
  ///
  /// In en, this message translates to:
  /// **'Annual Maintenance Cost (USD)'**
  String get maintenanceCostLabel;

  /// Tooltip for the aerator maintenance cost input field
  ///
  /// In en, this message translates to:
  /// **'Annual maintenance cost of the aerator in USD (0 to 1000)'**
  String get maintenanceCostAeratorTooltip;

  /// Label for the farm area input field
  ///
  /// In en, this message translates to:
  /// **'Total Farm Area (ha)'**
  String get farmAreaLabel;

  /// Tooltip for the farm area input field
  ///
  /// In en, this message translates to:
  /// **'Total area of the farm in hectares (0.1 to 100000)'**
  String get farmAreaTooltip;

  /// Label for the water temperature input field
  ///
  /// In en, this message translates to:
  /// **'Water Temperature (°C)'**
  String get waterTemperatureLabel;

  /// Tooltip for the water temperature input field
  ///
  /// In en, this message translates to:
  /// **'Average water temperature in Celsius (0 to 40)'**
  String get waterTemperatureTooltip;

  /// Label for the water salinity input field
  ///
  /// In en, this message translates to:
  /// **'Salinity (ppt)'**
  String get salinityLabel;

  /// Tooltip for the water salinity input field
  ///
  /// In en, this message translates to:
  /// **'Water salinity in parts per thousand (0 to 40)'**
  String get salinityTooltip;

  /// Label for the depth of the pond in meters
  ///
  /// In en, this message translates to:
  /// **'Pond Depth (m)'**
  String get pondDepthLabel;

  /// Tooltip for the pond depth input field
  ///
  /// In en, this message translates to:
  /// **'Average depth of the ponds in meters (0.5 to 5)'**
  String get pondDepthTooltip;

  /// Label for the average shrimp weight input field
  ///
  /// In en, this message translates to:
  /// **'Average Shrimp Weight (g)'**
  String get averageShrimpWeightLabel;

  /// Tooltip for the average shrimp weight input field
  ///
  /// In en, this message translates to:
  /// **'Average weight of shrimp in grams (0 to 50)'**
  String get averageShrimpWeightTooltip;

  /// Label for the shrimp biomass input field
  ///
  /// In en, this message translates to:
  /// **'Shrimp Biomass (kg/ha)'**
  String get shrimpBiomassLabel;

  /// Tooltip for the shrimp biomass input field
  ///
  /// In en, this message translates to:
  /// **'Biomass of shrimp per hectare (0 to 100000)'**
  String get shrimpBiomassTooltip;

  /// Label for the safety margin input field
  ///
  /// In en, this message translates to:
  /// **'Safety Margin (%)'**
  String get safetyMarginLabel;

  /// Tooltip for the safety margin input field
  ///
  /// In en, this message translates to:
  /// **'Safety margin for calculations (0 to 100)'**
  String get safetyMarginTooltip;

  /// Label for the shrimp price input field
  ///
  /// In en, this message translates to:
  /// **'Shrimp Price (USD/kg)'**
  String get shrimpPriceLabel;

  /// Tooltip for the shrimp price input field
  ///
  /// In en, this message translates to:
  /// **'Market price of shrimp per kilogram (0.1 to 50)'**
  String get shrimpPriceTooltip;

  /// Label for the cost of electricity per kilowatt-hour in USD
  ///
  /// In en, this message translates to:
  /// **'Electricity Cost (USD/kWh)'**
  String get electricityCostLabel;

  /// Tooltip for the electricity cost input field
  ///
  /// In en, this message translates to:
  /// **'Cost of electricity per kilowatt-hour (0 to 1)'**
  String get electricityCostTooltip;

  /// Label for the total hours aerators run per year
  ///
  /// In en, this message translates to:
  /// **'Operating Hours per Year'**
  String get operatingHoursLabel;

  /// Tooltip for the aerator operating hours input field
  ///
  /// In en, this message translates to:
  /// **'Total hours aerators run per year (0 to 8760)'**
  String get operatingHoursTooltip;

  /// Label for the discount rate input field
  ///
  /// In en, this message translates to:
  /// **'Discount Rate (%)'**
  String get discountRateLabel;

  /// Tooltip for the discount rate input field
  ///
  /// In en, this message translates to:
  /// **'Discount rate for financial calculations (0 to 100)'**
  String get discountRateTooltip;

  /// Label for the inflation rate input field
  ///
  /// In en, this message translates to:
  /// **'Inflation Rate (%)'**
  String get inflationRateLabel;

  /// Tooltip for the inflation rate input field
  ///
  /// In en, this message translates to:
  /// **'Annual inflation rate (0 to 100)'**
  String get inflationRateTooltip;

  /// Label for the analysis horizon input field
  ///
  /// In en, this message translates to:
  /// **'Analysis Horizon (years)'**
  String get analysisHorizonLabel;

  /// Tooltip for the analysis horizon input field
  ///
  /// In en, this message translates to:
  /// **'Time period for financial analysis (1 to 50)'**
  String get analysisHorizonTooltip;

  /// Validation message for required input fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Validation message for invalid numeric input
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// Validation message for input out of range
  ///
  /// In en, this message translates to:
  /// **'Value must be between {min} and {max}'**
  String rangeError(String min, String max);

  /// Validation message for minimum value input
  ///
  /// In en, this message translates to:
  /// **'Please enter a value greater than or equal to {value}'**
  String minimumValueError(String value);

  /// Label for optional input fields
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalField;

  /// Error message when fewer than two aerators are provided
  ///
  /// In en, this message translates to:
  /// **'At least two aerators are required'**
  String get minimumAeratorsError;

  /// Error message when survey submission fails
  ///
  /// In en, this message translates to:
  /// **'Failed to submit survey: {error}'**
  String submissionFailed(String error);

  /// Error message when survey submission fails
  ///
  /// In en, this message translates to:
  /// **'Error submitting survey'**
  String get surveyError;

  /// Title for the results page
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// Title for the summary metrics section
  ///
  /// In en, this message translates to:
  /// **'Summary Metrics'**
  String get summaryMetrics;

  /// Label for total oxygen demand in the summary
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand'**
  String get totalDemandLabel;

  /// Label for the recommended aerator
  ///
  /// In en, this message translates to:
  /// **'Recommended Aerator'**
  String get recommendedAerator;

  /// Title for the aerator comparison results section
  ///
  /// In en, this message translates to:
  /// **'Aerator Comparison Results'**
  String get aeratorComparisonResults;

  /// Title for the equilibrium prices section
  ///
  /// In en, this message translates to:
  /// **'Equilibrium Prices'**
  String get equilibriumPrices;

  /// Label for the equilibrium price of an aerator
  ///
  /// In en, this message translates to:
  /// **'Equilibrium Price'**
  String get equilibriumPriceLabel;

  /// Message shown when no equilibrium prices are available
  ///
  /// In en, this message translates to:
  /// **'No equilibrium prices available'**
  String get noEquilibriumPrices;

  /// Label for the aerator column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Aerator'**
  String get aeratorLabel;

  /// Label for the units needed column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Units Needed'**
  String get unitsNeeded;

  /// Label for the initial cost column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Initial Cost'**
  String get initialCostLabel;

  /// Label for the annual energy cost column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Annual Energy Cost'**
  String get annualEnergyCostLabel;

  /// Label for the annual maintenance cost column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Annual Maintenance Cost'**
  String get annualMaintenanceCostLabel;

  /// Label for the NPV of costs column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'NPV of Costs'**
  String get npvCostLabel;

  /// Label for the SAE column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'SAE (kg O₂/kWh)'**
  String get saeLabel;

  /// Label for the payback period column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Payback Period'**
  String get paybackPeriod;

  /// Label for the ROI column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get roiLabel;

  /// Label for the IRR column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'IRR'**
  String get irrLabel;

  /// Label for the profitability coefficient column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Profitability Coefficient'**
  String get profitabilityCoefficient;

  /// Message shown when no survey data is available
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Accessibility description for summary metrics section
  ///
  /// In en, this message translates to:
  /// **'Summary metrics for aerator comparison'**
  String get summaryMetricsDescription;

  /// Accessibility description for aerator comparison results table
  ///
  /// In en, this message translates to:
  /// **'Comparison table of aerator results'**
  String get aeratorComparisonResultsDescription;

  /// Accessibility description for equilibrium prices section
  ///
  /// In en, this message translates to:
  /// **'Equilibrium prices for non-recommended aerators'**
  String get equilibriumPricesDescription;

  /// Accessibility description for no data available message
  ///
  /// In en, this message translates to:
  /// **'No data available to display'**
  String get noDataAvailableDescription;

  /// Label for total oxygen demand input field
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand'**
  String get todLabel;

  /// Label for the cost input field in USD
  ///
  /// In en, this message translates to:
  /// **'Cost (USD)'**
  String get costLabel;

  /// Label for the NPV savings column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'NPV Savings'**
  String get npvSavingsLabel;

  /// Label for the culture days input field
  ///
  /// In en, this message translates to:
  /// **'Culture Days'**
  String get cultureDaysLabel;

  /// Label for the pond density input field
  ///
  /// In en, this message translates to:
  /// **'Pond Density'**
  String get pondDensityLabel;

  /// Label for the water temperature input field
  ///
  /// In en, this message translates to:
  /// **'Water Temperature'**
  String get temperatureLabel;

  /// Message shown when survey submission is successful
  ///
  /// In en, this message translates to:
  /// **'Survey submission was successful'**
  String get surveySubmissionSuccessful;

  /// Button label to return to the survey page
  ///
  /// In en, this message translates to:
  /// **'Return to Survey'**
  String get returnToSurvey;

  /// Button label to start a new comparison
  ///
  /// In en, this message translates to:
  /// **'New Comparison'**
  String get newComparison;

  /// Label for the annual revenue metric
  ///
  /// In en, this message translates to:
  /// **'Annual Revenue'**
  String get annualRevenueLabel;

  /// Label for the annual cost column in the comparison table
  ///
  /// In en, this message translates to:
  /// **'Annual Cost'**
  String get annualCostLabel;

  /// Label used when a value is not applicable
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// Text for years unit
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Title for the detailed results section
  ///
  /// In en, this message translates to:
  /// **'Detailed Results'**
  String get detailedResults;

  /// Label for the recommended aerator
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Label for aerators per hectare metric
  ///
  /// In en, this message translates to:
  /// **'Aerators per Hectare'**
  String get aeratorsPerHaLabel;

  /// Label for horsepower per hectare metric
  ///
  /// In en, this message translates to:
  /// **'Horsepower per Hectare'**
  String get horsepowerPerHaLabel;

  /// Label for cost as percentage of revenue
  ///
  /// In en, this message translates to:
  /// **'Cost % of Revenue'**
  String get costPercentRevenueLabel;

  /// Label for the annual replacement cost
  ///
  /// In en, this message translates to:
  /// **'Annual Replacement Cost'**
  String get annualReplacementCostLabel;

  /// Label for the opportunity cost metric
  ///
  /// In en, this message translates to:
  /// **'Opportunity Cost'**
  String get opportunityCostLabel;

  /// Explanation of what equilibrium price means
  ///
  /// In en, this message translates to:
  /// **'Price at which this aerator becomes financially equivalent to the recommended option'**
  String get equilibriumPriceExplanation;

  /// Text for days unit
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Text for months unit
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

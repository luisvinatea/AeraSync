import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
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
    Locale('es'),
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AeraSync'**
  String get appTitle;

  /// No description provided for @aeratorComparisonCalculator.
  ///
  /// In en, this message translates to:
  /// **'Aerator Comparison Calculator'**
  String get aeratorComparisonCalculator;

  /// No description provided for @totalOxygenDemandLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand (kg O₂/h)'**
  String get totalOxygenDemandLabel;

  /// No description provided for @sotrAerator1Label.
  ///
  /// In en, this message translates to:
  /// **'SOTR Aerator 1 (kg O₂/h per aerator)'**
  String get sotrAerator1Label;

  /// No description provided for @sotrAerator2Label.
  ///
  /// In en, this message translates to:
  /// **'SOTR Aerator 2 (kg O₂/h per aerator)'**
  String get sotrAerator2Label;

  /// No description provided for @priceAerator1Label.
  ///
  /// In en, this message translates to:
  /// **'Price Aerator 1 (USD per aerator)'**
  String get priceAerator1Label;

  /// No description provided for @priceAerator2Label.
  ///
  /// In en, this message translates to:
  /// **'Price Aerator 2 (USD per aerator)'**
  String get priceAerator2Label;

  /// No description provided for @maintenanceCostAerator1Label.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Cost Aerator 1 (USD/year per aerator)'**
  String get maintenanceCostAerator1Label;

  /// No description provided for @maintenanceCostAerator2Label.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Cost Aerator 2 (USD/year per aerator)'**
  String get maintenanceCostAerator2Label;

  /// No description provided for @durabilityAerator1Label.
  ///
  /// In en, this message translates to:
  /// **'Durability Aerator 1 (years)'**
  String get durabilityAerator1Label;

  /// No description provided for @durabilityAerator2Label.
  ///
  /// In en, this message translates to:
  /// **'Durability Aerator 2 (years)'**
  String get durabilityAerator2Label;

  /// No description provided for @annualEnergyCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual Energy Cost (USD/year per aerator)'**
  String get annualEnergyCostLabel;

  /// No description provided for @numberOfAerator1UnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Aerator 1 Units'**
  String get numberOfAerator1UnitsLabel;

  /// No description provided for @numberOfAerator2UnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Aerator 2 Units'**
  String get numberOfAerator2UnitsLabel;

  /// No description provided for @totalAnnualCostAerator1Label.
  ///
  /// In en, this message translates to:
  /// **'Total Annual Cost Aerator 1 (USD/year)'**
  String get totalAnnualCostAerator1Label;

  /// No description provided for @totalAnnualCostAerator2Label.
  ///
  /// In en, this message translates to:
  /// **'Total Annual Cost Aerator 2 (USD/year)'**
  String get totalAnnualCostAerator2Label;

  /// No description provided for @equilibriumPriceP2Label.
  ///
  /// In en, this message translates to:
  /// **'Equilibrium Price P₂ (USD)'**
  String get equilibriumPriceP2Label;

  /// No description provided for @actualPriceP2Label.
  ///
  /// In en, this message translates to:
  /// **'Actual Price P₂ (USD)'**
  String get actualPriceP2Label;

  /// No description provided for @aeratorEstimationCalculator.
  ///
  /// In en, this message translates to:
  /// **'Aerator Estimation Calculator'**
  String get aeratorEstimationCalculator;

  /// No description provided for @startO2ColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Start O₂ Column (mg/L)'**
  String get startO2ColumnLabel;

  /// No description provided for @finalO2ColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Final O₂ Column (mg/L)'**
  String get finalO2ColumnLabel;

  /// No description provided for @startO2BottomLabel.
  ///
  /// In en, this message translates to:
  /// **'Start O₂ Bottom (mg/L)'**
  String get startO2BottomLabel;

  /// No description provided for @finalO2BottomLabel.
  ///
  /// In en, this message translates to:
  /// **'Final O₂ Bottom (mg/L)'**
  String get finalO2BottomLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (hours)'**
  String get timeLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume (m³)'**
  String get volumeLabel;

  /// No description provided for @sotrLabel.
  ///
  /// In en, this message translates to:
  /// **'SOTR (kg O₂/h)'**
  String get sotrLabel;

  /// No description provided for @pondDepthLabel.
  ///
  /// In en, this message translates to:
  /// **'Pond Depth (m)'**
  String get pondDepthLabel;

  /// No description provided for @shrimpRespirationLabel.
  ///
  /// In en, this message translates to:
  /// **'Shrimp Respiration (mg/L/h)'**
  String get shrimpRespirationLabel;

  /// No description provided for @columnRespirationLabel.
  ///
  /// In en, this message translates to:
  /// **'Column Respiration (mg/L/h)'**
  String get columnRespirationLabel;

  /// No description provided for @bottomRespirationLabel.
  ///
  /// In en, this message translates to:
  /// **'Bottom Respiration (mg/L/h)'**
  String get bottomRespirationLabel;

  /// No description provided for @totalOxygenDemandMgPerLPerHLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand (mg/L/h)'**
  String get totalOxygenDemandMgPerLPerHLabel;

  /// No description provided for @todLabel.
  ///
  /// In en, this message translates to:
  /// **'TOD (kg O₂/h)'**
  String get todLabel;

  /// No description provided for @todLabelShort.
  ///
  /// In en, this message translates to:
  /// **'TOD'**
  String get todLabelShort;

  /// No description provided for @todPerHectareLabel.
  ///
  /// In en, this message translates to:
  /// **'TOD per Hectare (kg O₂/h/ha)'**
  String get todPerHectareLabel;

  /// No description provided for @otr20Label.
  ///
  /// In en, this message translates to:
  /// **'OTR20 (kg O₂/h)'**
  String get otr20Label;

  /// No description provided for @otrTLabel.
  ///
  /// In en, this message translates to:
  /// **'OTRt (kg O₂/h)'**
  String get otrTLabel;

  /// No description provided for @otrTLabelShort.
  ///
  /// In en, this message translates to:
  /// **'OTRt'**
  String get otrTLabelShort;

  /// No description provided for @numberOfAeratorsPerHectareLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Aerators per Hectare'**
  String get numberOfAeratorsPerHectareLabel;

  /// No description provided for @aeratorsLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Aerators'**
  String get aeratorsLabelShort;

  /// No description provided for @aeratorPerformanceCalculator.
  ///
  /// In en, this message translates to:
  /// **'Aerator Performance Calculator'**
  String get aeratorPerformanceCalculator;

  /// No description provided for @horsepowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Horsepower (HP)'**
  String get horsepowerLabel;

  /// No description provided for @t10Label.
  ///
  /// In en, this message translates to:
  /// **'T10 (minutes)'**
  String get t10Label;

  /// No description provided for @t70Label.
  ///
  /// In en, this message translates to:
  /// **'T70 (minutes)'**
  String get t70Label;

  /// No description provided for @electricityCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Electricity Cost (\$/kWh)'**
  String get electricityCostLabel;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand (Optional)'**
  String get brandLabel;

  /// No description provided for @aeratorTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Aerator Type'**
  String get aeratorTypeLabel;

  /// No description provided for @specifyAeratorTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Specify Aerator Type'**
  String get specifyAeratorTypeLabel;

  /// No description provided for @paddlewheel.
  ///
  /// In en, this message translates to:
  /// **'Paddlewheel'**
  String get paddlewheel;

  /// No description provided for @propeller.
  ///
  /// In en, this message translates to:
  /// **'Propeller'**
  String get propeller;

  /// No description provided for @splash.
  ///
  /// In en, this message translates to:
  /// **'Splash'**
  String get splash;

  /// No description provided for @diffused.
  ///
  /// In en, this message translates to:
  /// **'Diffused'**
  String get diffused;

  /// No description provided for @injector.
  ///
  /// In en, this message translates to:
  /// **'Injector'**
  String get injector;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @dataCollectionConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to allow my data to be collected safely for research purposes, in accordance with applicable laws.'**
  String get dataCollectionConsentLabel;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @forPlottingOnly.
  ///
  /// In en, this message translates to:
  /// **'For plotting only'**
  String get forPlottingOnly;

  /// No description provided for @comparisonResults.
  ///
  /// In en, this message translates to:
  /// **'Comparison Results'**
  String get comparisonResults;

  /// No description provided for @numberOfAeratorsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Number of Aerators Needed'**
  String get numberOfAeratorsNeeded;

  /// No description provided for @totalAnnualCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Annual Cost (USD/year)'**
  String get totalAnnualCostLabel;

  /// No description provided for @aerator1.
  ///
  /// In en, this message translates to:
  /// **'Aerator 1'**
  String get aerator1;

  /// No description provided for @aerator2.
  ///
  /// In en, this message translates to:
  /// **'Aerator 2'**
  String get aerator2;

  /// No description provided for @aerator2MoreCostEffective.
  ///
  /// In en, this message translates to:
  /// **'Aerator 2 is more cost-effective at the current price.'**
  String get aerator2MoreCostEffective;

  /// No description provided for @aerator1MoreCostEffective.
  ///
  /// In en, this message translates to:
  /// **'Aerator 1 may be more cost-effective at the current price.'**
  String get aerator1MoreCostEffective;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @calculationFailed.
  ///
  /// In en, this message translates to:
  /// **'Calculation failed'**
  String get calculationFailed;

  /// No description provided for @calculatorNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Calculator not initialized'**
  String get calculatorNotInitialized;

  /// No description provided for @specifyAeratorTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify the aerator type'**
  String get specifyAeratorTypeRequired;

  /// No description provided for @t70MustBeGreaterThanT10.
  ///
  /// In en, this message translates to:
  /// **'T70 must be greater than T10'**
  String get t70MustBeGreaterThanT10;

  /// No description provided for @generic.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get generic;

  /// No description provided for @couldNotOpenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Could not open privacy policy'**
  String get couldNotOpenPrivacyPolicy;

  /// No description provided for @calculateButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculateButton;

  /// No description provided for @enterValuesToCalculate.
  ///
  /// In en, this message translates to:
  /// **'Enter values and click Calculate to see results'**
  String get enterValuesToCalculate;

  /// No description provided for @downloadCsvButton.
  ///
  /// In en, this message translates to:
  /// **'Download as CSV (only values)'**
  String get downloadCsvButton;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @rangeError.
  ///
  /// In en, this message translates to:
  /// **'Must be between {min} and {max}'**
  String rangeError(Object max, Object min);

  /// No description provided for @oxygenDemandCalculator.
  ///
  /// In en, this message translates to:
  /// **'Oxygen Demand Calculator'**
  String get oxygenDemandCalculator;

  /// No description provided for @farmAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Area (ha)'**
  String get farmAreaLabel;

  /// No description provided for @farmAreaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Total area of the farm in hectares'**
  String get farmAreaTooltip;

  /// No description provided for @shrimpBiomassLabel.
  ///
  /// In en, this message translates to:
  /// **'Shrimp Biomass (kg/ha)'**
  String get shrimpBiomassLabel;

  /// No description provided for @shrimpBiomassTooltip.
  ///
  /// In en, this message translates to:
  /// **'Biomass of shrimp per hectare'**
  String get shrimpBiomassTooltip;

  /// No description provided for @waterTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Temperature (°C)'**
  String get waterTemperatureLabel;

  /// No description provided for @waterTemperatureTooltip.
  ///
  /// In en, this message translates to:
  /// **'Temperature of the water in the pond'**
  String get waterTemperatureTooltip;

  /// No description provided for @salinityLabel.
  ///
  /// In en, this message translates to:
  /// **'Salinity (‰)'**
  String get salinityLabel;

  /// No description provided for @salinityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Salinity of the water in parts per thousand'**
  String get salinityTooltip;

  /// No description provided for @averageShrimpWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Shrimp Weight (g)'**
  String get averageShrimpWeightLabel;

  /// No description provided for @averageShrimpWeightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Average weight of the shrimp in grams'**
  String get averageShrimpWeightTooltip;

  /// No description provided for @safetyMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety Margin'**
  String get safetyMarginLabel;

  /// No description provided for @safetyMarginTooltip.
  ///
  /// In en, this message translates to:
  /// **'Multiplier to account for unexpected oxygen demand'**
  String get safetyMarginTooltip;

  /// No description provided for @respirationRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Respiration Rate (g O₂/kg shrimp/h)'**
  String get respirationRateLabel;

  /// No description provided for @oxygenDemandFromShrimpLabel.
  ///
  /// In en, this message translates to:
  /// **'Oxygen Demand from Shrimp (kg O₂/h)'**
  String get oxygenDemandFromShrimpLabel;

  /// No description provided for @environmentalOxygenDemandLabel.
  ///
  /// In en, this message translates to:
  /// **'Environmental Oxygen Demand (kg O₂/h)'**
  String get environmentalOxygenDemandLabel;

  /// No description provided for @oxygenDemandResults.
  ///
  /// In en, this message translates to:
  /// **'Oxygen Demand Results'**
  String get oxygenDemandResults;

  /// No description provided for @totalOxygenDemandCopied.
  ///
  /// In en, this message translates to:
  /// **'Total Oxygen Demand copied to clipboard'**
  String get totalOxygenDemandCopied;

  /// No description provided for @copyToClipboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboardTooltip;

  /// No description provided for @totalOxygenDemandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Total oxygen required by the system in kg O₂ per hour'**
  String get totalOxygenDemandTooltip;

  /// No description provided for @sotrAerator1Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Standard Oxygen Transfer Rate for Aerator 1 in kg O₂ per hour per aerator'**
  String get sotrAerator1Tooltip;

  /// No description provided for @sotrAerator2Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Standard Oxygen Transfer Rate for Aerator 2 in kg O₂ per hour per aerator'**
  String get sotrAerator2Tooltip;

  /// No description provided for @priceAerator1Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Purchase price of Aerator 1 in USD per unit'**
  String get priceAerator1Tooltip;

  /// No description provided for @priceAerator2Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Purchase price of Aerator 2 in USD per unit'**
  String get priceAerator2Tooltip;

  /// No description provided for @maintenanceCostAerator1Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Annual maintenance cost for Aerator 1 in USD per year per aerator'**
  String get maintenanceCostAerator1Tooltip;

  /// No description provided for @maintenanceCostAerator2Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Annual maintenance cost for Aerator 2 in USD per year per aerator'**
  String get maintenanceCostAerator2Tooltip;

  /// No description provided for @durabilityAerator1Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Expected lifespan of Aerator 1 in years'**
  String get durabilityAerator1Tooltip;

  /// No description provided for @durabilityAerator2Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Expected lifespan of Aerator 2 in years'**
  String get durabilityAerator2Tooltip;

  /// No description provided for @annualEnergyCostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Annual energy cost for operating one aerator in USD per year'**
  String get annualEnergyCostTooltip;

  /// No description provided for @startO2ColumnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Initial oxygen concentration in the water column in mg/L'**
  String get startO2ColumnTooltip;

  /// No description provided for @finalO2ColumnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Final oxygen concentration in the water column in mg/L'**
  String get finalO2ColumnTooltip;

  /// No description provided for @startO2BottomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Initial oxygen concentration at the pond bottom in mg/L'**
  String get startO2BottomTooltip;

  /// No description provided for @finalO2BottomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Final oxygen concentration at the pond bottom in mg/L'**
  String get finalO2BottomTooltip;

  /// No description provided for @timeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Time duration for the oxygen concentration change in hours'**
  String get timeTooltip;

  /// No description provided for @volumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Volume of the pond in cubic meters'**
  String get volumeTooltip;

  /// No description provided for @sotrTooltip.
  ///
  /// In en, this message translates to:
  /// **'Standard Oxygen Transfer Rate of the aerator in kg O₂ per hour'**
  String get sotrTooltip;

  /// No description provided for @pondDepthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Depth of the pond in meters'**
  String get pondDepthTooltip;

  /// No description provided for @horsepowerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Power rating of the aerator in horsepower (HP)'**
  String get horsepowerTooltip;

  /// No description provided for @t10Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Time to reach 10% of oxygen saturation in minutes (used for plotting)'**
  String get t10Tooltip;

  /// No description provided for @t70Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Time to reach 70% of oxygen saturation in minutes'**
  String get t70Tooltip;

  /// No description provided for @electricityCostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cost of electricity per kilowatt-hour in USD'**
  String get electricityCostTooltip;

  /// No description provided for @equilibriumPriceCopied.
  ///
  /// In en, this message translates to:
  /// **'Equilibrium Price copied to clipboard'**
  String get equilibriumPriceCopied;

  /// No description provided for @sotrCopied.
  ///
  /// In en, this message translates to:
  /// **'SOTR copied to clipboard'**
  String get sotrCopied;

  /// No description provided for @numberOfAeratorsCopied.
  ///
  /// In en, this message translates to:
  /// **'Number of Aerators copied to clipboard'**
  String get numberOfAeratorsCopied;

  /// No description provided for @discountRateInflationRateError.
  ///
  /// In en, this message translates to:
  /// **'Discount rate and inflation rate cannot be equal.'**
  String get discountRateInflationRateError;

  /// No description provided for @sotrZeroError.
  ///
  /// In en, this message translates to:
  /// **'SOTR values cannot be zero.'**
  String get sotrZeroError;

  /// No description provided for @integerError.
  ///
  /// In en, this message translates to:
  /// **'This value must be an integer.'**
  String get integerError;

  /// Recommendation message when Aerator 1 is more cost-effective
  ///
  /// In en, this message translates to:
  /// **'Recommendation: Choose Aerator 1 to save {amount} USD over the analysis horizon.'**
  String recommendationChooseAerator1(double amount);

  /// Recommendation message when Aerator 2 is more cost-effective
  ///
  /// In en, this message translates to:
  /// **'Recommendation: Choose Aerator 2 to save {amount} USD over the analysis horizon.'**
  String recommendationChooseAerator2(double amount);

  /// No description provided for @recommendationEqualCosts.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: Both aerators have equal annual costs.'**
  String get recommendationEqualCosts;

  /// Message shown when a value is copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied {value} to clipboard.'**
  String valueCopied(String value);

  /// No description provided for @totalAnnualCostAerator1LabelShort.
  ///
  /// In en, this message translates to:
  /// **'Cost Aerator 1'**
  String get totalAnnualCostAerator1LabelShort;

  /// No description provided for @totalAnnualCostAerator2LabelShort.
  ///
  /// In en, this message translates to:
  /// **'Cost Aerator 2'**
  String get totalAnnualCostAerator2LabelShort;

  /// No description provided for @costOfOpportunityLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Cost of Opportunity'**
  String get costOfOpportunityLabelShort;

  /// No description provided for @totalAnnualCostAerator1Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Total annual cost for Aerator 1, including energy, maintenance, and capital costs.'**
  String get totalAnnualCostAerator1Tooltip;

  /// No description provided for @totalAnnualCostAerator2Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Total annual cost for Aerator 2, including energy, maintenance, and capital costs.'**
  String get totalAnnualCostAerator2Tooltip;

  /// No description provided for @costOfOpportunityTooltip.
  ///
  /// In en, this message translates to:
  /// **'The present value of savings by choosing the more cost-effective aerator.'**
  String get costOfOpportunityTooltip;

  /// No description provided for @costBreakdownTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown'**
  String get costBreakdownTableTitle;

  /// No description provided for @costComponentLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost Component'**
  String get costComponentLabel;

  /// No description provided for @energyCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy Cost (USD/year)'**
  String get energyCostLabel;

  /// No description provided for @maintenanceCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Cost (USD/year)'**
  String get maintenanceCostLabel;

  /// No description provided for @capitalCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Capital Cost (USD/year)'**
  String get capitalCostLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['es', 'en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es': return AppLocalizationsEs();
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class SurveyDataProcessor {
  /// Format and prepare survey data for API submission
  static Map<String, dynamic> prepareSurveyData({
    // Farm inputs
    required TextEditingController todController,
    required TextEditingController farmAreaController,
    required TextEditingController shrimpPriceController,
    required TextEditingController cultureDaysController,
    required TextEditingController shrimpDensityController,
    required TextEditingController pondDepthController,

    // Financial inputs
    required TextEditingController energyCostController,
    required TextEditingController hoursPerNightController,
    required TextEditingController discountRateController,
    required TextEditingController inflationRateController,
    required TextEditingController horizonController,
    required TextEditingController safetyMarginController,
    required TextEditingController temperatureController,

    // Aerator 1 inputs
    required TextEditingController aerator1NameController,
    required TextEditingController aerator1PowerController,
    required TextEditingController aerator1SotrController,
    required TextEditingController aerator1CostController,
    required TextEditingController aerator1DurabilityController,
    required TextEditingController aerator1MaintenanceController,

    // Aerator 2 inputs
    required TextEditingController aerator2NameController,
    required TextEditingController aerator2PowerController,
    required TextEditingController aerator2SotrController,
    required TextEditingController aerator2CostController,
    required TextEditingController aerator2DurabilityController,
    required TextEditingController aerator2MaintenanceController,
  }) {
    developer.log('Preparing survey data for submission');

    return {
      'farm': {
        'tod': double.tryParse(todController.text) ?? 0.0,
        'farm_area_ha': double.tryParse(farmAreaController.text) ?? 0.0,
        'shrimp_price': double.tryParse(shrimpPriceController.text) ?? 5.0,
        'culture_days': double.tryParse(cultureDaysController.text) ?? 120,
        'shrimp_density_kg_m3':
            double.tryParse(shrimpDensityController.text) ?? 0.3333333,
        'pond_depth_m': double.tryParse(pondDepthController.text) ?? 1.0,
      },
      'financial': {
        'energy_cost': double.tryParse(energyCostController.text) ?? 0.05,
        'hours_per_night': double.tryParse(hoursPerNightController.text) ?? 8,
        'discount_rate':
            (double.tryParse(discountRateController.text) ?? 10.0) / 100,
        'inflation_rate':
            (double.tryParse(inflationRateController.text) ?? 3.0) / 100,
        'horizon': int.tryParse(horizonController.text) ?? 9,
        'safety_margin':
            (double.tryParse(safetyMarginController.text) ?? 0.0) / 100,
        'temperature': double.tryParse(temperatureController.text) ?? 31.5,
      },
      'aerators': [
        {
          'name': aerator1NameController.text,
          'power_hp': double.tryParse(aerator1PowerController.text) ?? 3.0,
          'sotr': double.tryParse(aerator1SotrController.text) ?? 1.4,
          'cost': double.tryParse(aerator1CostController.text) ?? 500.0,
          'durability':
              double.tryParse(aerator1DurabilityController.text) ?? 2.0,
          'maintenance':
              double.tryParse(aerator1MaintenanceController.text) ?? 65.0,
        },
        {
          'name': aerator2NameController.text,
          'power_hp': double.tryParse(aerator2PowerController.text) ?? 3.0,
          'sotr': double.tryParse(aerator2SotrController.text) ?? 2.6,
          'cost': double.tryParse(aerator2CostController.text) ?? 800.0,
          'durability':
              double.tryParse(aerator2DurabilityController.text) ?? 4.5,
          'maintenance':
              double.tryParse(aerator2MaintenanceController.text) ?? 50.0,
        },
      ],
    };
  }

  /// Log survey data for debugging purposes
  static void logSurveyData(Map<String, dynamic> surveyData) {
    developer.log('Survey data prepared for submission: $surveyData');
  }
}

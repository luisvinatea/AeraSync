import math
from typing import Dict, Any, Optional

class SaturationCalculator:
    def get_o2_saturation(self, temperature: float, salinity: float) -> float:
        # Dummy implementation for placeholder
        print(f"Warning: Using dummy SaturationCalculator.get_o2_saturation({temperature}, {salinity})")
        # Approximate based on common values, replace with real calculator
        base_sat = 8.2
        temp_effect = (temperature - 20) * -0.1
        sal_effect = salinity * -0.05
        return max(0.1, base_sat + temp_effect + sal_effect)

class ShrimpRespirationCalculator:
     def get_respiration_rate(self, salinity: float, temperature: float, shrimp_weight: float) -> float:
         # Dummy implementation for placeholder
         print(f"Warning: Using dummy ShrimpRespirationCalculator.get_respiration_rate({salinity}, {temperature}, {shrimp_weight})")
         # Very rough approximation, replace with real calculator
         base_rate = 0.5 # mg O2/g/h
         temp_factor = 1 + (temperature - 25) * 0.03
         weight_factor = max(0.1, 1 - (shrimp_weight - 10) * 0.02)
         return base_rate * temp_factor * weight_factor
# End Placeholder classes

class AeratorComparer:
    """
    Performs aerator comparison calculations, including oxygen demand,
    unit requirements, costs, and financial metrics.
    """

    def __init__(self, saturation_calculator: SaturationCalculator, respiration_calculator: ShrimpRespirationCalculator):
        """
        Initializes the comparer with necessary calculator dependencies.

        Args:
            saturation_calculator: An instance capable of calculating O2 saturation.
            respiration_calculator: An instance capable of calculating shrimp respiration.
        """
        if not isinstance(saturation_calculator, SaturationCalculator):
             raise TypeError("saturation_calculator must be an instance of SaturationCalculator")
        if not isinstance(respiration_calculator, ShrimpRespirationCalculator):
             raise TypeError("respiration_calculator must be an instance of ShrimpRespirationCalculator")

        self.saturation_calc = saturation_calculator
        self.respiration_calc = respiration_calculator

        # Constants (Consider making these configurable)
        self.ENERGY_COST_PER_KWH: float = 0.05  # USD/kWh
        self.HP_AERATOR_1: float = 3.0
        self.HP_AERATOR_2: float = 3.5
        self.HOURS_PER_YEAR: float = 2920.0  # 8 hours/day * 365 days
        self.KW_CONVERSION_FACTOR: float = 0.746  # HP to kW
        self.THETA: float = 1.024  # Temperature correction factor for OTR
        self.STANDARD_TEMP: float = 20.0  # °C
        self.TOTAL_HECTARES: float = 1000.0 # Standard farm size for comparison base
        self.POND_DEPTH: float = 1.0 # meters (Assumption)
        self.WATER_VOLUME_PER_HA: float = 10000.0 * self.POND_DEPTH # m³/ha
        self.BOTTOM_VOLUME_FACTOR: float = 0.1 # Assumption

    def _calculate_otrt(self, sotr: float, temperature: float, salinity: float) -> float:
        """Calculates Oxygen Transfer Rate at temperature T (OTRt)."""
        cs_t = self.saturation_calc.get_o2_saturation(temperature, salinity)
        cs_20 = self.saturation_calc.get_o2_saturation(self.STANDARD_TEMP, salinity)

        if cs_20 <= 0:
            # Handle potential division by zero or invalid saturation value
            print(f"Warning: Cs at 20°C is {cs_20} for salinity {salinity}. Cannot calculate OTRt accurately.")
            # Return 0 or raise a more specific error depending on desired behavior
            return 0.0
            # raise ValueError(f"Cannot calculate OTRt: Cs at 20°C is zero or negative for salinity {salinity}")

        temp_correction_factor = self.THETA ** (temperature - self.STANDARD_TEMP)
        # Saturation correction factor (CsT / Cs20) assumes transfer into water with 0 DO
        # If a minimum DO (C_pond) is maintained, the factor is (CsT - C_pond) / (Cs20 - 0)
        # For simplicity matching the Dart code's apparent assumption:
        saturation_correction_factor = cs_t / cs_20

        otrt = sotr * temp_correction_factor * saturation_correction_factor
        return otrt

    def _calculate_tod(self, use_manual_tod: bool, manual_tod_value: float,
                       temperature: float, salinity: float, biomass_kg_ha: float,
                       use_custom_shrimp: bool, custom_shrimp_rate: Optional[float],
                       use_custom_water: bool, custom_water_rate: Optional[float],
                       use_custom_bottom: bool, custom_bottom_rate: Optional[float]) -> Dict[str, float]:
        """Calculates Total Oxygen Demand (TOD) in kg O₂/h for the total farm area."""
        if use_manual_tod:
            total_demand_kg_h_total_area = manual_tod_value
            shrimp_demand_kg_h_ha = 0.0 # Not calculated if manual
            water_demand_kg_h_ha = 0.0  # Not calculated if manual
            bottom_demand_kg_h_ha = 0.0 # Not calculated if manual
        else:
            # Shrimp Respiration (kg O₂/h/ha)
            avg_weight_g = 10.0 # Assumption, consider making this an input if variable
            respiration_rate_mg_g_h = (custom_shrimp_rate if use_custom_shrimp
                                       else self.respiration_calc.get_respiration_rate(salinity, temperature, avg_weight_g))
            if respiration_rate_mg_g_h is None:
                raise ValueError("Respiration rate cannot be None.")
            shrimp_demand_kg_h_ha = respiration_rate_mg_g_h * biomass_kg_ha * 1000.0 / 1_000_000.0

            # Water Respiration (kg O₂/h/ha)
            water_resp_rate_mg_l_h = custom_water_rate if use_custom_water else 0.1 # Default assumption
            if water_resp_rate_mg_l_h is None:
                raise ValueError("Water respiration rate cannot be None.")
            water_demand_kg_h_ha = water_resp_rate_mg_l_h * self.WATER_VOLUME_PER_HA * 1000.0 / 1_000_000.0

            # Bottom Respiration (kg O₂/h/ha)
            bottom_resp_rate_mg_l_h = custom_bottom_rate if use_custom_bottom else 0.05 # Default assumption
            if bottom_resp_rate_mg_l_h is None:
                raise ValueError("Bottom respiration rate cannot be None.")
            bottom_demand_kg_h_ha = bottom_resp_rate_mg_l_h * self.WATER_VOLUME_PER_HA * self.BOTTOM_VOLUME_FACTOR * 1000.0 / 1_000_000.0

            total_demand_kg_h_per_ha = shrimp_demand_kg_h_ha + water_demand_kg_h_ha + bottom_demand_kg_h_ha
            total_demand_kg_h_total_area = total_demand_kg_h_per_ha * self.TOTAL_HECTARES

        if total_demand_kg_h_total_area <= 0:
            raise ValueError("Total Oxygen Demand must be positive.")

        return {
            "total_demand_kg_h_total_area": total_demand_kg_h_total_area,
            "shrimp_demand_kg_h_ha": shrimp_demand_kg_h_ha,
            "water_demand_kg_h_ha": water_demand_kg_h_ha,
            "bottom_demand_kg_h_ha": bottom_demand_kg_h_ha,
        }

    def _calculate_tir(self, initial_investment_diff: float, annual_savings: float,
                       inflation_rate: float, analysis_horizon_years: int) -> float:
        """Calculates the Internal Rate of Return (TIR) using Newton-Raphson."""
        if initial_investment_diff == 0:
            return float('inf') if annual_savings > 0 else 0.0 # Or NaN? TIR is undefined if cost diff is 0
        if initial_investment_diff < 0 and annual_savings <= 0:
             return float('-inf') # Negative investment yields negative savings -> negative infinity TIR
        if initial_investment_diff > 0 and annual_savings <= 0:
             return float('-inf') # Positive investment yields negative savings -> negative infinity TIR

        # Newton-Raphson method
        tir = 0.10  # Initial guess (10%)
        max_iterations = 100
        tolerance = 1e-7

        for _ in range(max_iterations):
            present_value = 0.0
            derivative = 0.0
            effective_discount_rate = 1 + tir

            for t in range(1, int(analysis_horizon_years) + 1):
                try:
                    discount_factor = effective_discount_rate ** t
                    if discount_factor == 0: break # Avoid division by zero

                    cash_flow = annual_savings * ((1 + inflation_rate) ** t)
                    present_value += cash_flow / discount_factor
                    derivative += -t * cash_flow / (discount_factor * effective_discount_rate)
                except OverflowError:
                    print("Warning: Overflow encountered during TIR calculation. TIR might be very large.")
                    return float('inf') # Or handle as appropriate

            # Check if derivative is valid for Newton-Raphson step
            if derivative == 0 or not math.isfinite(derivative):
                 print("Warning: TIR derivative is zero or invalid. Cannot continue Newton-Raphson.")
                 return float('nan') # Cannot calculate

            f = present_value - initial_investment_diff
            if abs(f) < tolerance:
                return tir * 100.0  # Converged, return as percentage

            tir -= f / derivative

            # Prevent unreasonable TIR values during iteration
            if tir <= -1.0: # TIR cannot be less than -100%
                 tir = -0.9999

        print(f"Warning: TIR calculation did not converge within {max_iterations} iterations.")
        return float('nan') # Failed to converge


    def compare_aerators(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Performs the full aerator comparison calculation.

        Args:
            inputs (Dict[str, Any]): A dictionary containing all required input parameters:
                'temperature', 'salinity', 'biomass_kg_ha', 'sotr1', 'sotr2',
                'price1', 'price2', 'maintenance1', 'maintenance2',
                'durability1', 'durability2', 'discount_rate_pct', 'inflation_rate_pct',
                'analysis_horizon_years', 'use_manual_tod', 'manual_tod_value',
                'use_custom_shrimp', 'custom_shrimp_rate',
                'use_custom_water', 'custom_water_rate',
                'use_custom_bottom', 'custom_bottom_rate'

        Returns:
            Dict[str, Any]: A dictionary containing calculated results and key inputs.

        Raises:
            ValueError: If inputs are invalid or calculations fail.
            Exception: If dependent calculators are not ready or other errors occur.
        """
        try:
            # --- Input Parsing and Validation ---
            temp = float(inputs['temperature'])
            sal = float(inputs['salinity'])
            biomass = float(inputs.get('biomass_kg_ha', 0.0)) # Default to 0 if not provided
            sotr1 = float(inputs['sotr1'])
            sotr2 = float(inputs['sotr2'])
            price1 = float(inputs['price1'])
            price2 = float(inputs['price2'])
            maint1 = float(inputs['maintenance1'])
            maint2 = float(inputs['maintenance2'])
            dur1 = float(inputs['durability1'])
            dur2 = float(inputs['durability2'])
            discount_rate = float(inputs['discount_rate_pct']) / 100.0
            inflation_rate = float(inputs['inflation_rate_pct']) / 100.0
            horizon = int(inputs['analysis_horizon_years'])

            use_manual_tod = bool(inputs.get('use_manual_tod', False))
            manual_tod = float(inputs.get('manual_tod_value', 0.0))
            use_custom_shrimp = bool(inputs.get('use_custom_shrimp', False))
            custom_shrimp = float(inputs.get('custom_shrimp_rate', 0.0))
            use_custom_water = bool(inputs.get('use_custom_water', False))
            custom_water = float(inputs.get('custom_water_rate', 0.0))
            use_custom_bottom = bool(inputs.get('use_custom_bottom', False))
            custom_bottom = float(inputs.get('custom_bottom_rate', 0.0))

            if discount_rate == inflation_rate:
                raise ValueError("Discount rate cannot be equal to inflation rate for PV calculation.")
            if sotr1 <= 0 or sotr2 <= 0:
                raise ValueError("SOTR values must be positive.")
            if dur1 <= 0 or dur2 <= 0:
                raise ValueError("Durability values must be positive.")
            if horizon <= 0:
                 raise ValueError("Analysis horizon must be positive.")

            # --- Core Calculations ---
            # Energy Costs per aerator per year
            kw1 = self.HP_AERATOR_1 * self.KW_CONVERSION_FACTOR
            kw2 = self.HP_AERATOR_2 * self.KW_CONVERSION_FACTOR
            energy_cost1_per_year = kw1 * self.ENERGY_COST_PER_KWH * self.HOURS_PER_YEAR
            energy_cost2_per_year = kw2 * self.ENERGY_COST_PER_KWH * self.HOURS_PER_YEAR

            # OTRt per aerator
            otrt1 = self._calculate_otrt(sotr1, temp, sal)
            otrt2 = self._calculate_otrt(sotr2, temp, sal)
            if otrt1 <= 0 or otrt2 <= 0:
                raise ValueError("Calculated OTRt is zero or negative. Check inputs or saturation data.")

            # Total Oxygen Demand (TOD)
            tod_results = self._calculate_tod(
                use_manual_tod, manual_tod, temp, sal, biomass,
                use_custom_shrimp, custom_shrimp,
                use_custom_water, custom_water,
                use_custom_bottom, custom_bottom
            )
            total_demand_kg_h = tod_results["total_demand_kg_h_total_area"]
            tod_per_ha = total_demand_kg_h / self.TOTAL_HECTARES

            # Number of Units Needed (round up)
            n1 = math.ceil(total_demand_kg_h / otrt1)
            n2 = math.ceil(total_demand_kg_h / otrt2)

            # Costs
            capital_cost1_per_year = price1 / dur1
            capital_cost2_per_year = price2 / dur2
            annual_unit_cost1 = energy_cost1_per_year + maint1 + capital_cost1_per_year
            annual_unit_cost2 = energy_cost2_per_year + maint2 + capital_cost2_per_year
            total_annual_cost1 = n1 * annual_unit_cost1
            total_annual_cost2 = n2 * annual_unit_cost2

            # Equilibrium Price P2
            # n1 * annual_unit_cost1 = n2 * (energy_cost2_per_year + maint2 + p2_eq / dur2)
            if n2 == 0: # Avoid division by zero if n2 is 0 (e.g., OTR2 is extremely high)
                p2_equilibrium = float('inf') if n1 * annual_unit_cost1 > 0 else 0.0
            else:
                p2_equilibrium = dur2 * ((n1 * annual_unit_cost1 / n2) - (energy_cost2_per_year + maint2))


            # Financial Metrics
            annual_savings = abs(total_annual_cost1 - total_annual_cost2)
            initial_investment_diff = (n2 * price2) - (n1 * price1)

            # Present Value of Savings (Annuity)
            pv_savings: float
            if discount_rate == inflation_rate: # Should have been caught earlier, but handle again
                pv_savings = annual_savings * horizon / (1 + discount_rate)
            else:
                effective_rate_factor = (1 + inflation_rate) / (1 + discount_rate)
                # Check if effective_rate_factor is 1 (shouldn't happen if d != g)
                if abs(effective_rate_factor - 1.0) < 1e-9:
                     pv_savings = annual_savings * horizon / (1 + discount_rate)
                else:
                     pv_savings = annual_savings * ( (1 + inflation_rate) / (discount_rate - inflation_rate) ) * (1 - (effective_rate_factor ** horizon))


            k = pv_savings / initial_investment_diff if initial_investment_diff != 0 else float('inf')
            vpn = pv_savings - initial_investment_diff

            # Payback Period (Discounted)
            payback_years = float('inf')
            cumulative_discounted_savings = 0.0
            if initial_investment_diff > 0: # Payback only relevant if there's an initial cost difference to recover
                for t in range(1, int(horizon) + 1):
                    discount_factor = (1 + discount_rate) ** t
                    if discount_factor == 0: break
                    discounted_saving = (annual_savings * ((1 + inflation_rate) ** t)) / discount_factor
                    cumulative_discounted_savings += discounted_saving
                    if cumulative_discounted_savings >= initial_investment_diff:
                        # Interpolate for more precision (optional)
                        # payback_years = t - 1 + (initial_investment_diff - (cumulative_discounted_savings - discounted_saving)) / discounted_saving
                        payback_years = float(t)
                        break
            payback_days = float('inf') if payback_years == float('inf') else round(payback_years * 365)


            roi = (annual_savings / initial_investment_diff) * 100 if initial_investment_diff != 0 else float('inf')
            tir = self._calculate_tir(initial_investment_diff, annual_savings, inflation_rate, horizon)

            # Cost of Opportunity & Real Price
            cost_of_opportunity = abs(vpn)
            is_aerator1_more_expensive = total_annual_cost1 > total_annual_cost2
            loser_label: str
            real_price_loser: float
            loser_units: int

            if is_aerator1_more_expensive: # A2 is better
                loser_label = "Aerator 1"
                # Real cost = price + opportunity cost (lost NPV) spread over units
                real_price_loser = price1 + (cost_of_opportunity / n1) if n1 > 0 else float('inf')
                loser_units = n1
            else: # A1 is better or equal
                loser_label = "Aerator 2"
                real_price_loser = price2 + (cost_of_opportunity / n2) if n2 > 0 else float('inf')
                loser_units = n2

            # --- Prepare Output ---
            results = {
                # Intermediate Calc Values
                "otrtAerator1": round(otrt1, 4),
                "otrtAerator2": round(otrt2, 4),
                "totalOxygenDemand": round(total_demand_kg_h, 4),
                "shrimpDemandKgHa": round(tod_results["shrimp_demand_kg_h_ha"], 4) if not use_manual_tod else None,
                "waterDemandKgHa": round(tod_results["water_demand_kg_h_ha"], 4) if not use_manual_tod else None,
                "bottomDemandKgHa": round(tod_results["bottom_demand_kg_h_ha"], 4) if not use_manual_tod else None,
                # Core Comparison Results
                "numberOfAerator1Units": n1,
                "numberOfAerator2Units": n2,
                "totalAnnualCostAerator1": round(total_annual_cost1, 2),
                "totalAnnualCostAerator2": round(total_annual_cost2, 2),
                "equilibriumPriceP2": round(p2_equilibrium, 2),
                "actualPriceP2": round(price2, 2),
                # Financial Metrics
                "profitabilityIndex": k if math.isfinite(k) else ('inf' if k > 0 else '-inf'), # Represent infinity
                "netPresentValue": round(vpn, 2),
                "paybackPeriodDays": payback_days if math.isfinite(payback_days) else 'inf',
                "returnOnInvestment": roi if math.isfinite(roi) else ('inf' if roi > 0 else '-inf'),
                "internalRateOfReturn": round(tir, 2) if math.isfinite(tir) else ('inf' if tir > 0 else ('-inf' if tir < 0 else 'nan')), # Handle NaN/Inf TIR
                "costOfOpportunity": round(cost_of_opportunity, 2),
                "realPriceLosingAerator": round(real_price_loser, 2) if math.isfinite(real_price_loser) else 'inf',
                "loserLabel": loser_label,
                "numberOfUnitsLosingAerator": loser_units,
                 # Include key inputs for context
                "inputs": inputs
            }
            return results

        except Exception as e:
            print(f"Error during aerator comparison calculation: {e}")
            # Re-raise or return an error structure
            raise

# Example Usage (Requires SaturationCalculator and ShrimpRespirationCalculator instances)
if __name__ == '__main__':
    # Assume calculators are initialized with correct paths
    # Replace dummy placeholders with actual imports and initializations
    sat_calc = SaturationCalculator() # Dummy
    resp_calc = ShrimpRespirationCalculator() # Dummy

    comparer = AeratorComparer(saturation_calculator=sat_calc, respiration_calculator=resp_calc)

    # Example input matching the Dart form defaults
    test_inputs = {
        'temperature': 31.5,
        'salinity': 20.0,
        'biomass_kg_ha': 3333.33,
        'sotr1': 1.4,
        'sotr2': 2.2,
        'price1': 500.0,
        'price2': 800.0,
        'maintenance1': 65.0,
        'maintenance2': 50.0,
        'durability1': 2.0,
        'durability2': 4.5,
        'discount_rate_pct': 10.0,
        'inflation_rate_pct': 2.5,
        'analysis_horizon_years': 9,
        'use_manual_tod': False,
        'manual_tod_value': 5443.7675, # This value is used only if use_manual_tod is True
        'use_custom_shrimp': False,
        'custom_shrimp_rate': 0.3436,
        'use_custom_water': False,
        'custom_water_rate': 0.49125,
        'use_custom_bottom': False,
        'custom_bottom_rate': 0.245625,
    }

    try:
        comparison_results = comparer.compare_aerators(test_inputs)
        print("\n--- Aerator Comparison Results ---")
        for key, value in comparison_results.items():
            if key != 'inputs': # Don't print the whole input dict again
                 print(f"{key}: {value}")
    except Exception as e:
        print(f"\n--- Error during comparison ---")
        print(e)

    # Example with Manual TOD
    test_inputs_manual_tod = test_inputs.copy()
    test_inputs_manual_tod['use_manual_tod'] = True
    test_inputs_manual_tod['manual_tod_value'] = 6000.0 # Example manual TOD in kg/h for 1000ha

    try:
        comparison_results_manual = comparer.compare_aerators(test_inputs_manual_tod)
        print("\n--- Aerator Comparison Results (Manual TOD) ---")
        for key, value in comparison_results_manual.items():
             if key != 'inputs':
                 print(f"{key}: {value}")
    except Exception as e:
        print(f"\n--- Error during comparison (Manual TOD) ---")
        print(e)

"""Aerator comparison module for shrimp pond aeration analysis."""
import json
import math
import sqlite3
from typing import Any, Dict, List, Optional

from scipy.optimize import newton
from shrimp_respiration_calculator import ShrimpRespirationCalculator
from sotr_calculator import ShrimpPondCalculator as SaturationCalculator


class AeratorComparer:
    """Compares aerators for shrimp pond aeration and financial analysis."""
    def __init__(
        self,
        saturation_calculator: SaturationCalculator,
        respiration_calculator: ShrimpRespirationCalculator,
        db_path: str = "aerasync.db"
    ):
        if not isinstance(saturation_calculator, SaturationCalculator):
            raise TypeError(
                "saturation_calculator must be an instance of "
                "SaturationCalculator"
            )
        if not isinstance(respiration_calculator, ShrimpRespirationCalculator):
            raise TypeError(
                "respiration_calculator must be an instance of "
                "ShrimpRespirationCalculator"
            )
        self.kw_conversion_factor: float = 0.746  # HP to kW
        self.theta: float = 1.024  # Temperature correction factor
        self.standard_temp: float = 20.0  # °C
        self.bottom_volume_factor: float = 0.05  # Adjusted per PDF
        self.saturation_calc = saturation_calculator
        self.respiration_calc = respiration_calculator
        self.db_path = db_path
        self._init_database()

    def _init_database(self):
        """Initialize SQLite database and create table."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS aerator_comparisons (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
                    inputs TEXT,
                    results TEXT
                )
                """
            )
            conn.commit()

    def _log_comparison(
        self,
        inputs: Dict[str, Any],
        log_results: Dict[str, Any]
    ):
        """Log inputs and results to SQLite database."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                (
                    "INSERT INTO aerator_comparisons (inputs, results) "
                    "VALUES (?, ?)",
                    (json.dumps(inputs, default=str),
                     json.dumps(log_results, default=str))
                )
            )
            conn.commit()

    def _calculate_otrt(
        self, sotr: float, temperature: float, salinity: float
    ) -> float:
        """Calculate Oxygen Transfer Rate at temperature T (OTRt)."""
        cs_20 = self.saturation_calc.get_o2_saturation(
            self.standard_temp, salinity
        )
        if cs_20 <= 0:
            raise ValueError(
                f"O2 saturation at 20°C is {cs_20} for salinity {salinity}"
            )
        temp_corr = self.theta ** (temperature - self.standard_temp)
        sat_corr = 0.5  # Fixed per PDF
        otrt = sotr * temp_corr * sat_corr
        if otrt <= 0:
            raise ValueError("OTRt must be positive")
        return otrt

    def _calculate_tod(
        self,
        total_area: float,
        pond_depth: float,
        temperature: float,
        salinity: float,
        biomass_kg_ha: float,
        shrimp_weight: float,
        safety_margin_percent: Optional[float]
    ) -> Dict[str, float]:
        """Calculate Total Oxygen Demand (TOD) in kg O₂/h."""
        water_vol_ha = 10000.0 * pond_depth  # m³/ha
        resp_rate = self.respiration_calc.get_respiration_rate(
            salinity, temperature, shrimp_weight
        )
        if resp_rate is None:
            raise ValueError("Shrimp respiration rate cannot be None")
        shrimp_demand = resp_rate * biomass_kg_ha * 1000.0 / 1_000_000.0
        water_rate = 0.49125  # kg O₂/m³/h, per PDF
        water_demand = water_rate * water_vol_ha * 1000.0 / 1_000_000.0
        bottom_rate = 0.245625  # kg O₂/m³/h, per PDF
        bottom_demand = (
            bottom_rate * water_vol_ha * self.bottom_volume_factor
            * 1000.0 / 1_000_000.0
        )
        pond_demand = water_demand + bottom_demand
        total_per_ha = shrimp_demand + pond_demand
        total_demand = total_per_ha * total_area
        if safety_margin_percent is not None and safety_margin_percent > 0:
            total_demand *= (1 + safety_margin_percent / 100.0)
        if total_demand <= 0:
            raise ValueError("Total Oxygen Demand must be positive")
        return {
            "total_demand_kg_h": total_demand,
            "shrimp_demand_kg_h_ha": shrimp_demand,
            "pond_demand_kg_h_ha": pond_demand,
            "water_demand_kg_h_ha": water_demand,
            "bottom_demand_kg_h_ha": bottom_demand
        }

    def _calculate_annual_revenue(
        self,
        production_kg_ha_year: float,
        total_area: float,
        shrimp_price_usd_kg: float
    ) -> float:
        """Calculate annual revenue."""
        if production_kg_ha_year < 0 or total_area < 0 or \
                shrimp_price_usd_kg < 0:
            raise ValueError(
                "Production, area, and price must be non-negative"
            )
        total_yield_kg = production_kg_ha_year * total_area
        return total_yield_kg * shrimp_price_usd_kg

    def _calculate_npv(
        self,
        cash_flows: List[float],
        discount_rate: float,
        inflation_rate: float,
        horizon: int
    ) -> float:
        """Calculate NPV with growing annuity."""
        npv = 0.0
        for t in range(horizon):
            growth_factor = (1 + inflation_rate) ** t
            discount_factor = (1 + discount_rate) ** (t + 1)
            npv += (cash_flows[t] * growth_factor) / discount_factor
        return npv

    def _calculate_irr(
        self,
        initial_investment: float,
        cash_flows: List[float],
        horizon: int
    ) -> float:
        """Calculate IRR using numerical method."""
        def npv_for_irr(r: float) -> float:
            npv = -initial_investment
            for t in range(horizon):
                npv += cash_flows[t] / (1 + r) ** (t + 1)
            return npv
        try:
            irr = newton(npv_for_irr, 0.1, maxiter=1000)
            return irr * 100  # Convert to percentage
        except RuntimeError:
            return float('inf')

    def compare_aerators(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Compare aerators based on survey data."""
        try:
            # Extract inputs
            farm = inputs['farm']
            oxygen = inputs['oxygen']
            aerators = inputs['aerators']
            financial = inputs['financial']

            total_area = float(farm['area_ha'])
            pond_depth = float(farm['pond_depth_m'])
            production_kg_ha_year = float(farm['production_kg_ha_year'])
            temperature = float(oxygen['temperature_c'])
            salinity = float(oxygen['salinity_ppt'])
            shrimp_weight = float(oxygen['shrimp_weight_g'])
            biomass_kg_ha = float(oxygen['biomass_kg_ha'])
            shrimp_price_usd_kg = float(financial['shrimp_price_usd_kg'])
            energy_cost = float(financial['energy_cost_usd_kwh'])
            operating_hours = float(financial['operating_hours_year'])
            discount_rate = float(financial['discount_rate_percent']) / 100.0
            inflation_rate = float(financial['inflation_rate_percent']) / 100.0
            horizon = int(financial['analysis_horizon_years'])
            safety_margin_percent = financial.get('safety_margin_percent')

            if not aerators or len(aerators) < 2:
                raise ValueError("At least two aerators are required")
            if discount_rate == inflation_rate:
                raise ValueError(
                    "Discount rate cannot equal inflation rate"
                )
            if horizon <= 0:
                raise ValueError("Analysis horizon must be positive")

            # Calculate TOD
            tod_results = self._calculate_tod(
                total_area=total_area,
                pond_depth=pond_depth,
                temperature=temperature,
                salinity=salinity,
                biomass_kg_ha=biomass_kg_ha,
                shrimp_weight=shrimp_weight,
                safety_margin_percent=safety_margin_percent
            )
            total_demand_kg_h = tod_results['total_demand_kg_h']

            # Calculate annual revenue
            annual_revenue = self._calculate_annual_revenue(
                production_kg_ha_year=production_kg_ha_year,
                total_area=total_area,
                shrimp_price_usd_kg=shrimp_price_usd_kg
            )

            # Process each aerator
            aerator_results = []
            annual_costs = []
            for aerator in aerators:
                name = str(aerator['name'])
                power_hp = float(aerator['power_hp'])
                sotr = float(aerator['sotr_kg_o2_h'])
                initial_cost = float(aerator['initial_cost_usd'])
                durability = float(aerator['durability_years'])
                maintenance = float(aerator['maintenance_usd_year'])

                if sotr <= 0 or durability <= 0 or power_hp <= 0:
                    raise ValueError(f"Invalid aerator data for {name}")

                # Calculate SAE
                power_kw = power_hp * self.kw_conversion_factor
                sae = sotr / power_kw if power_kw > 0 else float('inf')

                # Calculate OTRt
                otrt = self._calculate_otrt(sotr, temperature, salinity)

                # Number of aerators
                num_aerators = math.ceil(total_demand_kg_h / otrt)

                # Annual costs
                energy_cost_year = power_kw * energy_cost * operating_hours
                capital_cost_year = initial_cost / durability
                total_unit_cost = (
                    energy_cost_year + maintenance + capital_cost_year
                )
                total_annual_cost = num_aerators * total_unit_cost

                # Cost percentage
                cost_percentage = (
                    total_annual_cost / annual_revenue * 100
                    if annual_revenue > 0 else float('inf')
                )

                aerator_results.append({
                    'name': name,
                    'sae': sae,
                    'numAerators': num_aerators,
                    'totalAnnualCost': total_annual_cost,
                    'costPercentage': cost_percentage
                })
                annual_costs.append(
                    (total_annual_cost, name, num_aerators, initial_cost)
                )

            # Financial metrics (relative to least efficient aerator)
            baseline_cost, baseline_name, baseline_units, _ = max(annual_costs)
            winner_cost, winner_name, winner_units, winner_price = \
                min(annual_costs)
            annual_savings = baseline_cost - winner_cost
            initial_investment = winner_units * winner_price
            cash_flows = [annual_savings] * horizon

            # NPV
            npv_value = self._calculate_npv(
                cash_flows, discount_rate, inflation_rate, horizon
            )

            # IRR
            irr_value = (
                self._calculate_irr(initial_investment, cash_flows, horizon)
                if initial_investment > 0 else float('inf')
            )

            # Payback Period (simplified)
            payback_period = (
                initial_investment / annual_savings * 12
                if annual_savings > 0 else float('inf')
            )

            # ROI
            roi = (
                npv_value / initial_investment * 100
                if initial_investment > 0 else float('inf')
            )

            # Profitability Coefficient (k)
            k = (
                npv_value / initial_investment
                if initial_investment > 0 else float('inf')
            )

            # Equilibrium price for winner (relative to baseline)
            equilibrium_price = float('inf')
            if winner_units > 0:
                baseline_unit_cost = (
                    baseline_cost / baseline_units
                    if baseline_units > 0 else float('inf')
                )
                equilibrium_price = (
                    baseline_unit_cost * winner_units
                    - winner_cost
                    + winner_price
                )

            # Cost of opportunity
            cost_of_opportunity = npv_value if npv_value > 0 else 0.0

            # Update aerator results with financial metrics
            for result in aerator_results:
                if result['name'] == baseline_name:
                    result.update({
                        'npv': 0.0,
                        'irr': 0.0,
                        'paybackPeriod': 0.0,
                        'roi': 0.0,
                        'profitabilityCoefficient': 0.0
                    })
                else:
                    result.update({
                        'npv': npv_value,
                        'irr': irr_value,
                        'paybackPeriod': payback_period,
                        'roi': roi,
                        'profitabilityCoefficient': k
                    })

            results = {
                'tod': round(total_demand_kg_h, 4),
                'shrimpRespiration': round(
                    tod_results['shrimp_demand_kg_h_ha'], 4),
                'pondRespiration': round(
                    tod_results['pond_demand_kg_h_ha'], 4),
                'pondWaterRespiration': round(
                    tod_results['water_demand_kg_h_ha'], 4),
                'pondBottomRespiration': round(
                    tod_results['bottom_demand_kg_h_ha'], 4),
                'annualRevenue': round(annual_revenue, 2),
                'winnerLabel': winner_name,
                'aeratorResults': aerator_results,
                'apiResults': {
                    'equilibriumPriceP2': round(equilibrium_price, 2),
                    'costOfOpportunity': round(cost_of_opportunity, 2),
                    'annualSavings': round(annual_savings, 2)
                }
            }

            self._log_comparison(inputs, results)
            return results

        except (ValueError, TypeError, RuntimeError) as e:
            print(f"Error during aerator comparison: {e}")
            raise


if __name__ == "__main__":
    sat_calc = SaturationCalculator()
    resp_calc = ShrimpRespirationCalculator()
    comparer = AeratorComparer(
        saturation_calculator=sat_calc,
        respiration_calculator=resp_calc
    )
    test_inputs = {
        'farm': {
            'area_ha': 1000.0,
            'production_kg_ha_year': 10000.0,
            'cycles_per_year': 3.0,
            'pond_depth_m': 1.0
        },
        'oxygen': {
            'temperature_c': 31.5,
            'salinity_ppt': 20.0,
            'shrimp_weight_g': 10.0,
            'biomass_kg_ha': 3333.33
        },
        'aerators': [
            {
                'name': 'Aerator 1',
                'power_hp': 3.0,
                'sotr_kg_o2_h': 1.4,
                'initial_cost_usd': 500.0,
                'durability_years': 2.0,
                'maintenance_usd_year': 65.0
            },
            {
                'name': 'Aerator 2',
                'power_hp': 3.5,
                'sotr_kg_o2_h': 2.2,
                'initial_cost_usd': 800.0,
                'durability_years': 4.5,
                'maintenance_usd_year': 50.0
            }
        ],
        'financial': {
            'shrimp_price_usd_kg': 5.0,
            'energy_cost_usd_kwh': 0.05,
            'operating_hours_year': 2920.0,
            'discount_rate_percent': 10.0,
            'inflation_rate_percent': 2.5,
            'analysis_horizon_years': 9,
            'safety_margin_percent': 0.0  # Added default value
        }
    }
    try:
        comparison_results = comparer.compare_aerators(test_inputs)
        print("\n--- Aerator Comparison Results ---")
        for key, value in comparison_results.items():
            print(f"{key}: {value}")
    except (ValueError, TypeError, RuntimeError) as e:
        print("\n--- Error ---")
        print(e)

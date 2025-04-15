import math
import sqlite3
from typing import Dict, Any, Optional
from sotr_calculator import ShrimpPondCalculator as SaturationCalculator
from shrimp_respiration_calculator import ShrimpRespirationCalculator


class AeratorComparer:
    def __init__(
        self,
        saturation_calculator: SaturationCalculator,
        respiration_calculator: ShrimpRespirationCalculator,
        db_path: str = "aerasync.db"
    ):
        if not isinstance(saturation_calculator, SaturationCalculator):
            raise TypeError(
                "saturation_calculator must be an instance"
                "of SaturationCalculator"
            )
        if not isinstance(respiration_calculator, ShrimpRespirationCalculator):
            raise TypeError(
                "respiration_calculator must be an instance of "
                "ShrimpRespirationCalculator"
            )
        self.saturation_calc = saturation_calculator
        self.respiration_calc = respiration_calculator
        self.KW_CONVERSION_FACTOR: float = 0.746  # HP to kW
        self.THETA: float = 1.024  # Temp. correction factor for OTR
        self.STANDARD_TEMP: float = 20.0  # °C
        self.BOTTOM_VOLUME_FACTOR: float = 0.1  # Assumption
        self.db_path = db_path
        self._init_database()

    def _init_database(self):
        """Initialize the SQLite database and create the necessary table."""
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
        self, inputs: Dict[str, Any], results: Dict[str, Any]
    ):
        """Log the inputs and results to the SQLite database."""
        import json
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO aerator_comparisons"
                "(inputs, results) VALUES (?, ?)",
                (json.dumps(inputs), json.dumps(results))
            )
            conn.commit()

    def _calculate_otrt(
        self, sotr: float, temperature: float, salinity: float
    ) -> float:
        """Calculates Oxygen Transfer Rate at temperature T (OTRt)."""
        cs_t = self.saturation_calc.get_o2_saturation(temperature, salinity)
        cs_20 = self.saturation_calc.get_o2_saturation(
            self.STANDARD_TEMP, salinity)
        if cs_20 <= 0:
            print(
                f"Warning: Cs at 20°C is {cs_20} for salinity {salinity}. "
                "Cannot calculate OTRt accurately."
            )
            return 0.0
        temp_corr = self.THETA ** (temperature - self.STANDARD_TEMP)
        sat_corr = cs_t / cs_20
        otrt = sotr * temp_corr * sat_corr
        return otrt

    def _calculate_tod(
        self,
        total_area: float,
        pond_depth: float,
        use_manual_tod: bool,
        manual_tod_value: float,
        temperature: float,
        salinity: float,
        biomass_kg_ha: float,
        shrimp_weight: float,
        use_custom_shrimp: bool,
        custom_shrimp_rate: Optional[float],
        use_custom_water: bool,
        custom_water_rate: Optional[float],
        use_custom_bottom: bool,
        custom_bottom_rate: Optional[float],
    ) -> Dict[str, float]:
        """Calculates Total Oxygen Demand
        (TOD) in kg O₂/h for the farm area."""
        water_vol_ha = 10000.0 * pond_depth  # m³/ha
        if use_manual_tod:
            total_demand = manual_tod_value
            shrimp_demand = 0.0
            water_demand = 0.0
            bottom_demand = 0.0
        else:
            resp_rate = (
                custom_shrimp_rate if use_custom_shrimp else
                self.respiration_calc.get_respiration_rate(
                    salinity, temperature, shrimp_weight
                )
            )
            if resp_rate is None:
                raise ValueError("Respiration rate cannot be None.")
            shrimp_demand = resp_rate * biomass_kg_ha * 1000.0 / 1_000_000.0
            water_rate = custom_water_rate if use_custom_water else 0.1
            if water_rate is None:
                raise ValueError("Water respiration rate cannot be None.")
            water_demand = water_rate * water_vol_ha * 1000.0 / 1_000_000.0
            bottom_rate = custom_bottom_rate if use_custom_bottom else 0.05
            if bottom_rate is None:
                raise ValueError("Bottom respiration rate cannot be None.")
            bottom_demand = (
                bottom_rate * water_vol_ha * self.BOTTOM_VOLUME_FACTOR * 1000.0
                / 1_000_000.0
            )
            total_per_ha = shrimp_demand + water_demand + bottom_demand
            total_demand = total_per_ha * total_area
        if total_demand <= 0:
            raise ValueError("Total Oxygen Demand must be positive.")
        return {
            "total_demand_kg_h_total_area": total_demand,
            "shrimp_demand_kg_h_ha": shrimp_demand,
            "water_demand_kg_h_ha": water_demand,
            "bottom_demand_kg_h_ha": bottom_demand,
        }

    def _calculate_pv_savings(
        self,
        annual_savings: float,
        discount_rate: float,
        inflation_rate: float,
        horizon: int,
    ) -> float:
        """Calculates the Present Value of savings
        using the annuity formula."""
        if discount_rate == inflation_rate:
            return annual_savings * horizon / (1 + discount_rate)
        eff_rate = (1 + inflation_rate) / (1 + discount_rate)
        if abs(eff_rate - 1.0) < 1e-9:
            return annual_savings * horizon / (1 + discount_rate)
        pv_factor = (1 + inflation_rate) / (discount_rate - inflation_rate)
        pv_savings = annual_savings * pv_factor * (1 - (eff_rate ** horizon))
        return pv_savings

    def _calculate_annual_revenue(
        self,
        shrimp_density_kg_ha: float,
        total_area: float,
        shrimp_price_usd_kg: float,
        cycles_per_year: float,
    ) -> float:
        """Calculates annual revenue
        based on shrimp density, area, price, cycles."""
        if (
            shrimp_density_kg_ha < 0 or total_area < 0 or
            shrimp_price_usd_kg < 0 or cycles_per_year < 0
        ):
            raise ValueError(
                "Shrimp density,"
                "farm size, shrimp price, and cycles must be non-negative."
            )
        total_yield_kg = shrimp_density_kg_ha * total_area
        annual_revenue = total_yield_kg * shrimp_price_usd_kg * cycles_per_year
        return annual_revenue

    def compare_aerators(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Performs the full aerator comparison calculation, including equilibrium
        price and profitability coefficient k. Uses shrimp density, farm size,
        shrimp price, and cycles per year to compute annual revenue.
        """
        try:
            temp = float(inputs['temperature'])
            sal = float(inputs['salinity'])
            total_area = float(inputs['total_area'])
            pond_depth = float(inputs['pond_depth'])
            biomass = float(inputs.get('biomass_kg_ha', 0.0))
            shrimp_weight = float(inputs['shrimp_weight'])
            shrimp_density_kg_ha = float(inputs['shrimp_density_kg_ha'])
            shrimp_price_usd_kg = float(inputs['shrimp_price_usd_kg'])
            cycles_per_year = float(inputs['cycles_per_year'])
            sotr1 = float(inputs['sotr1'])
            sotr2 = float(inputs['sotr2'])
            price1 = float(inputs['price1'])
            price2 = float(inputs['price2'])
            maint1 = float(inputs['maintenance1'])
            maint2 = float(inputs['maintenance2'])
            dur1 = float(inputs['durability1'])
            dur2 = float(inputs['durability2'])
            energy_cost = float(inputs['energy_cost'])
            operating_hours = float(inputs['operating_hours'])
            power1 = float(inputs['power1'])
            power2 = float(inputs['power2'])
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
                raise ValueError(
                    "Discount rate cannot be equal"
                    "to inflation rate for PV calculation."
                )
            if sotr1 <= 0 or sotr2 <= 0:
                raise ValueError("SOTR values must be positive.")
            if dur1 <= 0 or dur2 <= 0:
                raise ValueError("Durability values must be positive.")
            if horizon <= 0:
                raise ValueError("Analysis horizon must be positive.")
            annual_revenue = self._calculate_annual_revenue(
                shrimp_density_kg_ha, total_area,
                shrimp_price_usd_kg, cycles_per_year
            )
            hours_per_year = operating_hours * 365.0
            kw1 = power1 * self.KW_CONVERSION_FACTOR
            kw2 = power2 * self.KW_CONVERSION_FACTOR
            energy_cost1_per_year = kw1 * energy_cost * hours_per_year
            energy_cost2_per_year = kw2 * energy_cost * hours_per_year
            otrt1 = self._calculate_otrt(sotr1, temp, sal)
            otrt2 = self._calculate_otrt(sotr2, temp, sal)
            if otrt1 <= 0 or otrt2 <= 0:
                raise ValueError(
                    "Calculated OTRt is zero or negative."
                    "Check inputs or saturation data."
                )
            tod_results = self._calculate_tod(
                total_area=total_area,
                pond_depth=pond_depth,
                use_manual_tod=use_manual_tod,
                manual_tod_value=manual_tod,
                temperature=temp,
                salinity=sal,
                biomass_kg_ha=biomass,
                shrimp_weight=shrimp_weight,
                use_custom_shrimp=use_custom_shrimp,
                custom_shrimp_rate=custom_shrimp,
                use_custom_water=use_custom_water,
                custom_water_rate=custom_water,
                use_custom_bottom=use_custom_bottom,
                custom_bottom_rate=custom_bottom
            )
            total_demand_kg_h = tod_results["total_demand_kg_h_total_area"]
            n1 = math.ceil(total_demand_kg_h / otrt1)
            n2 = math.ceil(total_demand_kg_h / otrt2)
            capital_cost1_per_year = price1 / dur1
            capital_cost2_per_year = price2 / dur2
            annual_unit_cost1 = (
                energy_cost1_per_year + maint1 + capital_cost1_per_year
            )
            annual_unit_cost2 = (
                energy_cost2_per_year + maint2 + capital_cost2_per_year
            )
            total_annual_cost1 = n1 * annual_unit_cost1
            total_annual_cost2 = n2 * annual_unit_cost2
            p2_equilibrium = (
                float('inf') if n2 == 0
                else
                dur2 * (n1 * annual_unit_cost1 / n2 -
                        (energy_cost2_per_year + maint2))
            )
            annual_savings = abs(total_annual_cost1 - total_annual_cost2)
            initial_investment_diff = (n2 * price2) - (n1 * price1)
            pv_savings = self._calculate_pv_savings(
                annual_savings, discount_rate, inflation_rate, horizon
            )
            k = (
                pv_savings / initial_investment_diff
                if initial_investment_diff != 0 else float('inf')
            )
            is_aerator1_better = total_annual_cost1 < total_annual_cost2
            winner_label = "Aerator 1" if is_aerator1_better else "Aerator 2"
            loser_label = "Aerator 2" if is_aerator1_better else "Aerator 1"
            loser_units = n2 if is_aerator1_better else n1
            cost_of_opportunity = abs(pv_savings - initial_investment_diff)
            real_price_loser = (
                price2 + (cost_of_opportunity / n2)
                if is_aerator1_better else price1 + (cost_of_opportunity / n1)
            ) if loser_units > 0 else float('inf')
            results = {
                "otrtAerator1": round(otrt1, 4),
                "otrtAerator2": round(otrt2, 4),
                "totalOxygenDemand": round(total_demand_kg_h, 4),
                "shrimpDemandKgHa": (
                    round(tod_results["shrimp_demand_kg_h_ha"], 4)
                    if not use_manual_tod else None
                ),
                "waterDemandKgHa": (
                    round(tod_results["water_demand_kg_h_ha"], 4)
                    if not use_manual_tod else None
                ),
                "bottomDemandKgHa": (
                    round(tod_results["bottom_demand_kg_h_ha"], 4)
                    if not use_manual_tod else None
                ),
                "numberOfAerator1Units": n1,
                "numberOfAerator2Units": n2,
                "totalAnnualCostAerator1": round(total_annual_cost1, 2),
                "totalAnnualCostAerator2": round(total_annual_cost2, 2),
                "equilibriumPriceP2": round(p2_equilibrium, 2),
                "actualPriceP2": round(price2, 2),
                "profitabilityIndex": (
                    k if math.isfinite(k) else ('inf' if k > 0 else '-inf')
                ),
                "netPresentValue": round(
                    pv_savings - initial_investment_diff, 2),
                "costOfOpportunity": round(cost_of_opportunity, 2),
                "realPriceLosingAerator": (
                    round(real_price_loser, 2)
                    if math.isfinite(real_price_loser) else 'inf'
                ),
                "winnerLabel": winner_label,
                "loserLabel": loser_label,
                "numberOfUnitsLosingAerator": loser_units,
                "annualSavings": round(annual_savings, 2),
                "initialInvestmentDiff": round(initial_investment_diff, 2),
                "pvSavings": round(pv_savings, 2),
                "computedAnnualRevenue": round(annual_revenue, 2),
                "inputs": inputs
            }
            self._log_comparison(inputs, results)
            return results
        except Exception as e:
            print(f"Error during aerator comparison calculation: {e}")
            raise


if __name__ == "__main__":
    sat_calc = SaturationCalculator()
    resp_calc = ShrimpRespirationCalculator()
    comparer = AeratorComparer(
        saturation_calculator=sat_calc, respiration_calculator=resp_calc
    )
    test_inputs = {
        'temperature': 31.5,
        'salinity': 20.0,
        'total_area': 1000.0,
        'pond_depth': 1.0,
        'biomass_kg_ha': 3333.33,
        'shrimp_weight': 10.0,
        'shrimp_density_kg_ha': 5000.0,
        'shrimp_price_usd_kg': 5.0,
        'cycles_per_year': 2.0,
        'sotr1': 1.4,
        'sotr2': 2.2,
        'power1': 3.0,
        'power2': 3.5,
        'price1': 500.0,
        'price2': 800.0,
        'maintenance1': 65.0,
        'maintenance2': 50.0,
        'durability1': 2.0,
        'durability2': 4.5,
        'energy_cost': 0.05,
        'operating_hours': 8.0,
        'discount_rate_pct': 10.0,
        'inflation_rate_pct': 2.5,
        'analysis_horizon_years': 9,
        'use_manual_tod': False,
        'manual_tod_value': 5443.7675,
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
            if key != 'inputs':
                print(f"{key}: {value}")
    except Exception as e:
        print("\n--- Error during comparison ---")
        print(e)

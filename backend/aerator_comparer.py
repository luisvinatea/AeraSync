"""Aerator comparison module for shrimp pond aeration analysis."""

from typing import Any, Dict, List, Tuple, Union
import sqlite3
import json

from .aerator_types import (
    AeratorComparisonInputs,
    AeratorResult,
    ComparisonResults,
    FinancialData,
    AeratorComparisonRequest,
)
from .aerator_calculations import (
    calculate_annual_revenue,
    calculate_tod,
    calculate_otrt,
    compute_equilibrium_price,
    compute_financial_metrics,
)
from .sotr_calculator import ShrimpPondCalculator as SaturationCalculator
from .shrimp_respiration_calculator import ShrimpRespirationCalculator


class AeratorComparer:
    """Compares aerators for shrimp pond aeration and financial analysis."""

    def __init__(
        self,
        saturation_calculator: SaturationCalculator,
        respiration_calculator: ShrimpRespirationCalculator,
        db_url: str,
    ):
        """Initialize the AeratorComparer with calculators and SQLite DB path.

        Args:
            saturation_calculator: Calculator for oxygen saturation.
            respiration_calculator: Calculator for shrimp respiration.
            db_url: SQLite database file path or ":memory:".
        """
        self.kw_conversion_factor: float = 0.746
        self.theta: float = 1.024
        self.standard_temp: float = 20.0
        self.bottom_volume_factor: float = 0.05
        self.saturation_calc = saturation_calculator
        self.respiration_calc = respiration_calculator
        self.db_url = db_url
        self._init_database()

    def _init_database(self) -> None:
        """Initialize SQLite database and create table."""
        try:
            conn = sqlite3.connect(self.db_url)
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
            conn.close()
        except sqlite3.Error as e:
            print(f"SQLite database initialization error: {e}")
            raise RuntimeError(
                f"Failed to initialize SQLite database: {e}") from e

    def _log_comparison(
        self, inputs: Dict[str, Any], log_results: ComparisonResults
    ) -> None:
        """Log inputs and results to SQLite database.

        Args:
            inputs: Input parameters for comparison.
            log_results: Comparison results to log.

        Raises:
            RuntimeError: If database logging fails.
        """
        try:
            with sqlite3.connect(self.db_url) as conn:
                cursor = conn.cursor()
                inputs_json = json.dumps(inputs)
                results_json = json.dumps(log_results)
                cursor.execute(
                    (
                        "INSERT INTO aerator_comparisons "
                        "(inputs, results) VALUES (?, ?)"
                    ),
                    (inputs_json, results_json),
                )
                conn.commit()
        except sqlite3.Error as e:
            print(f"SQLite database error during logging: {e}")
            raise RuntimeError(f"Failed to log comparison: {e}") from e

    def log_comparison(
        self, inputs: Dict[str, Any], results: ComparisonResults
    ) -> None:
        """Public method to log comparison inputs and results."""
        self._log_comparison(inputs, results)

    def _extract_inputs(
        self, inputs: Dict[str, Any]
    ) -> AeratorComparisonInputs:
        """Extract and type-cast input parameters.

        Args:
            inputs: Raw input dictionary.

        Returns:
            Typed input parameters for aerator comparison.
        """
        farm = inputs.get("farm", {})
        oxygen = inputs.get("oxygen", {})
        financial = inputs.get("financial", {})
        aerators = inputs.get("aerators", [])

        return {
            "total_area": float(farm.get("area_ha", 0)),
            "pond_depth": float(farm.get("pond_depth_m", 0)),
            "production_kg_ha_year": float(
                farm.get("production_kg_ha_year", 0)
            ),
            "temperature": float(oxygen.get("temperature_c", 0)),
            "salinity": float(oxygen.get("salinity_ppt", 0)),
            "shrimp_weight": float(oxygen.get("shrimp_weight_g", 0)),
            "biomass_kg_ha": float(oxygen.get("biomass_kg_ha", 0)),
            "shrimp_price_usd_kg": float(
                financial.get("shrimp_price_usd_kg", 0)
            ),
            "energy_cost": float(financial.get("energy_cost_usd_kwh", 0)),
            "operating_hours": float(financial.get("operating_hours_year", 0)),
            "discount_rate": float(
                financial.get("discount_rate_percent", 0)
            ) / 100,
            "inflation_rate": float(
                financial.get("inflation_rate_percent", 0)
            ) / 100,
            "horizon": int(financial.get("analysis_horizon_years", 0)),
            "safety_margin_percent": financial.get("safety_margin_percent"),
            "aerators": aerators,
        }

    def _validate_aerator(self, aerator: Dict[str, Any]) -> None:
        """Validate a single aerator's parameters.

        Args:
            aerator: Aerator parameter dictionary.

        Raises:
            ValueError: If any parameter is invalid.
        """
        name = str(aerator.get("name", "Unknown"))
        sotr = float(aerator.get("sotr_kg_o2_h", 0))
        durability = float(aerator.get("durability_years", 0))
        power_hp = float(aerator.get("power_hp", 0))
        initial_cost = float(aerator.get("initial_cost_usd", 0))
        maintenance = float(aerator.get("maintenance_usd_year", 0))

        if sotr <= 0:
            raise ValueError(f"SOTR for {name} must be positive, got {sotr}")
        if durability <= 0:
            raise ValueError(
                f"Durability for {name} must be positive, got {durability}"
            )
        if power_hp <= 0:
            raise ValueError(
                f"Power for {name} must be positive, got {power_hp}"
            )
        if initial_cost < 0:
            raise ValueError(
                f"Initial cost for {name} must be non-negative, "
                f"got {initial_cost}"
            )
        if maintenance < 0:
            raise ValueError(
                f"Maintenance for {name} must be non-negative, "
                f"got {maintenance}"
            )

    def _validate_inputs(self, inputs: AeratorComparisonInputs) -> None:
        """Validate input parameters.

        Args:
            inputs: Typed input parameters.

        Raises:
            ValueError: If any parameter is invalid.
        """
        if not inputs["aerators"] or len(inputs["aerators"]) < 2:
            raise ValueError("At least two aerators are required")
        if inputs["discount_rate"] == inputs["inflation_rate"]:
            raise ValueError("Discount rate cannot equal inflation rate")

        positive_fields: Dict[str, float] = {
            "total_area": inputs["total_area"],
            "pond_depth": inputs["pond_depth"],
            "operating_hours": inputs["operating_hours"],
            "horizon": inputs["horizon"],
        }
        for field, param_value in positive_fields.items():
            if param_value <= 0:
                raise ValueError(
                    f"{field} must be positive, got {param_value}"
                )

        non_negative_fields = {
            "production_kg_ha_year": inputs["production_kg_ha_year"],
            "shrimp_price_usd_kg": inputs["shrimp_price_usd_kg"],
            "energy_cost": inputs["energy_cost"],
        }
        for field, param_value in non_negative_fields.items():
            if param_value < 0:
                raise ValueError(
                    f"{field} must be non-negative, got {param_value}"
                )

        for aerator in inputs["aerators"]:
            self._validate_aerator(aerator)

    def _calculate_power_kw(self, power_hp: float) -> float:
        """Convert power from HP to kW.

        Args:
            power_hp: Power in horsepower.

        Returns:
            Power in kW.
        """
        return power_hp * self.kw_conversion_factor

    def _calculate_sae(self, sotr: float, power_kw: float) -> float:
        """Calculate Specific Aeration Efficiency (SAE).

        Args:
            sotr: Standard Oxygen Transfer Rate in kg O₂/h.
            power_kw: Power in kW.

        Returns:
            SAE in kg O₂/kW.

        Raises:
            ValueError: If power is non-positive.
        """
        if power_kw <= 0:
            raise ValueError(f"Power in kW must be positive, got {power_kw}")
        return sotr / power_kw

    def _calculate_num_aerators(
        self, total_demand_kg_h: float, otrt: float
    ) -> int:
        """Calculate the number of aerators needed.

        Args:
            total_demand_kg_h: Total oxygen demand in kg O₂/h.
            otrt: Oxygen Transfer Rate in kg O₂/h.

        Returns:
            Number of aerators (minimum 1).

        Raises:
            ValueError: If OTRt is non-positive.
        """
        if otrt <= 0:
            raise ValueError(f"OTRt must be positive, got {otrt}")
        return max(1, int(total_demand_kg_h / otrt + 0.5))

    def _calculate_total_annual_cost(
        self,
        aerator_data: Dict[str, Union[float, int]],
        inputs: AeratorComparisonInputs,
    ) -> float:
        """Calculate the total annual cost of aerators.

        Args:
            aerator_data: Aerator parameters (power_kw, maintenance, etc.).
            inputs: Input parameters for comparison.

        Returns:
            Total annual cost in USD.
        """
        energy_cost = (
            aerator_data["power_kw"]
            * inputs["energy_cost"]
            * inputs["operating_hours"]
        )
        annualized_cost = (
            aerator_data["initial_cost"] / aerator_data["durability"]
        )
        return (
            energy_cost + aerator_data["maintenance"] + annualized_cost
        ) * aerator_data["num_aerators"]

    def _calculate_cost_percentage(
        self, total_annual_cost: float, annual_revenue: float
    ) -> float:
        """Calculate the cost percentage of the aerator.

        Args:
            total_annual_cost: Total annual cost in USD.
            annual_revenue: Annual revenue in USD.

        Returns:
            Cost percentage.

        Raises:
            ValueError: If annual revenue is non-positive.
        """
        if annual_revenue <= 0:
            raise ValueError(
                f"Annual revenue must be positive, got {annual_revenue}"
            )
        return (total_annual_cost / annual_revenue) * 100

    def _create_aerator_result(
        self, aerator_data: Dict[str, Union[str, float, int]]
    ) -> AeratorResult:
        """Create an AeratorResult object.

        Args:
            aerator_data: Aerator parameters (name, sae, etc.).

        Returns:
            AeratorResult dictionary.
        """
        return AeratorResult(
            name=str(aerator_data["name"]),
            sae=float(aerator_data["sae"]),
            numAerators=int(aerator_data["num_aerators"]),
            totalAnnualCost=float(aerator_data["total_annual_cost"]),
            costPercentage=float(aerator_data["cost_percentage"]),
            npv=0.0,
            irr=0.0,
            paybackPeriod=0.0,
            roi=0.0,
            profitabilityCoefficient=0.0,
        )

    def _process_single_aerator(
        self,
        aerator: Dict[str, Any],
        inputs: AeratorComparisonInputs,
        total_demand_kg_h: float,
        annual_revenue: float,
    ) -> Tuple[AeratorResult, Tuple[float, str, int, float]]:
        """Process a single aerator and calculate costs.

        Args:
            aerator: Aerator parameter dictionary.
            inputs: Input parameters for comparison.
            total_demand_kg_h: Total oxygen demand in kg O₂/h.
            annual_revenue: Annual revenue in USD.

        Returns:
            Tuple of AeratorResult and cost tuple.
        """
        aerator_params: Dict[str, Any] = {
            "name": str(aerator.get("name", "Unknown")),
            "power_hp": float(aerator.get("power_hp", 0)),
            "sotr": float(aerator.get("sotr_kg_o2_h", 0)),
            "initial_cost": float(aerator.get("initial_cost_usd", 0)),
            "durability": float(aerator.get("durability_years", 0)),
            "maintenance": float(aerator.get("maintenance_usd_year", 0)),
        }

        power_kw = self._calculate_power_kw(aerator_params["power_hp"])
        sae = self._calculate_sae(aerator_params["sotr"], power_kw)
        otrt = calculate_otrt(
            aerator_params["sotr"],
            inputs["temperature"],
            inputs["salinity"],
            self.saturation_calc,
            self.theta,
            self.standard_temp,
        )
        num_aerators = self._calculate_num_aerators(total_demand_kg_h, otrt)

        total_annual_cost = self._calculate_total_annual_cost(
            {
                "power_kw": power_kw,
                "maintenance": aerator_params["maintenance"],
                "initial_cost": aerator_params["initial_cost"],
                "durability": aerator_params["durability"],
                "num_aerators": num_aerators,
            },
            inputs,
        )

        cost_percentage = self._calculate_cost_percentage(
            total_annual_cost, annual_revenue
        )

        aerator_data: Dict[str, Union[str, float, int]] = {
            "name": aerator_params["name"],
            "sae": sae,
            "num_aerators": num_aerators,
            "total_annual_cost": total_annual_cost,
            "cost_percentage": cost_percentage,
        }

        result = self._create_aerator_result(aerator_data)
        cost_tuple = (
            total_annual_cost,
            aerator_params["name"],
            num_aerators,
            aerator_params["initial_cost"],
        )

        return result, cost_tuple

    def _process_aerators(
        self,
        inputs: AeratorComparisonInputs,
        total_demand_kg_h: float,
        annual_revenue: float,
    ) -> Tuple[List[AeratorResult], List[Tuple[float, str, float, float]]]:
        """Process each aerator and calculate costs.

        Args:
            inputs: Input parameters for comparison.
            total_demand_kg_h: Total oxygen demand in kg O₂/h.
            annual_revenue: Annual revenue in USD.

        Returns:
            Tuple of aerator results and annual costs.
        """
        aerator_results: List[AeratorResult] = []
        annual_costs: List[Tuple[float, str, float, float]] = []

        for aerator in inputs["aerators"]:
            result, cost_tuple = self._process_single_aerator(
                aerator, inputs, total_demand_kg_h, annual_revenue
            )
            aerator_results.append(result)
            annual_costs.append(cost_tuple)

        return aerator_results, annual_costs

    def _extract_baseline_and_winner_data(
        self, annual_costs: List[Tuple[float, str, float, float]]
    ) -> Tuple[
        Dict[str, Union[float, str, int]],
        Dict[str, Union[float, str, int]]
    ]:
        """Extract baseline and winner data from annual costs.

        Args:
            annual_costs: List of cost tuples.

        Returns:
            Tuple of baseline and winner data dictionaries.
        """
        baseline_data: Dict[str, Union[float, str, int]] = {
            "cost": float(max(annual_costs)[0]),
            "name": str(max(annual_costs)[1]),
            "units": int(max(annual_costs)[2]),
        }
        winner_data: Dict[str, Union[float, str, int]] = {
            "cost": min(annual_costs)[0],
            "name": min(annual_costs)[1],
            "units": min(annual_costs)[2],
            "price": min(annual_costs)[3],
        }
        return baseline_data, winner_data

    def _calculate_annual_savings(
        self, baseline_cost: float, winner_cost: float
    ) -> float:
        """Calculate annual savings.

        Args:
            baseline_cost: Baseline aerator annual cost in USD.
            winner_cost: Winner aerator annual cost in USD.

        Returns:
            Annual savings in USD.
        """
        return baseline_cost - winner_cost

    def _calculate_initial_investment(
        self, winner_units: float, winner_price: float
    ) -> float:
        """Calculate initial investment.

        Args:
            winner_units: Number of winner aerators.
            winner_price: Price per winner aerator in USD.

        Returns:
            Initial investment in USD.
        """
        return winner_units * winner_price

    def _generate_cash_flows(
        self, annual_savings: float, horizon: int
    ) -> List[float]:
        """Generate cash flows for the given horizon.

        Args:
            annual_savings: Annual savings in USD.
            horizon: Analysis horizon in years.

        Returns:
            List of cash flows.
        """
        return [annual_savings] * horizon

    def _prepare_financial_inputs(
        self,
        baseline_cost: float,
        winner_cost: float,
        winner_units: float,
        winner_price: float,
    ) -> Dict[str, float]:
        """Prepare financial inputs for metrics calculation.

        Args:
            baseline_cost: Baseline aerator annual cost in USD.
            winner_cost: Winner aerator annual cost in USD.
            winner_units: Number of winner aerators.
            winner_price: Price per winner aerator in USD.

        Returns:
            Dictionary of financial inputs.
        """
        return {
            "baseline_cost": baseline_cost,
            "winner_cost": winner_cost,
            "winner_units": winner_units,
            "winner_price": winner_price,
        }

    def _compute_financial_data(
        self,
        financial_inputs: Dict[str, float],
        inputs: AeratorComparisonInputs
    ) -> FinancialData:
        """Compute financial data for metrics calculation.

        Args:
            financial_inputs: Financial input parameters.
            inputs: Aerator comparison inputs.

        Returns:
            FinancialData dictionary.
        """
        annual_savings = self._calculate_annual_savings(
            financial_inputs["baseline_cost"], financial_inputs["winner_cost"]
        )
        initial_investment = self._calculate_initial_investment(
            financial_inputs["winner_units"], financial_inputs["winner_price"]
        )
        cash_flows = self._generate_cash_flows(
            annual_savings, inputs["horizon"]
        )

        return FinancialData(
            initial_investment=initial_investment,
            annual_savings=annual_savings,
            cash_flows=cash_flows,
            shrimp_price_usd_kg=inputs["shrimp_price_usd_kg"],
            energy_cost_usd_kwh=inputs["energy_cost"],
            operating_hours_year=inputs["operating_hours"],
            discount_rate_percent=inputs["discount_rate"] * 100,
            inflation_rate_percent=inputs["inflation_rate"] * 100,
            analysis_horizon_years=inputs["horizon"],
            safety_margin_percent=inputs["safety_margin_percent"],
            discount_rate=inputs["discount_rate"],
            inflation_rate=inputs["inflation_rate"],
            horizon=inputs["horizon"],
        )

    def _update_aerator_results(
        self,
        aerator_results: List[AeratorResult],
        baseline_name: str,
        metrics: Dict[str, float],
    ) -> None:
        """Update aerator results with financial metrics.

        Args:
            aerator_results: List of aerator results.
            baseline_name: Name of the baseline aerator.
            metrics: Financial metrics (npv, irr, etc.).
        """
        for result in aerator_results:
            if result["name"] == baseline_name:
                result.update(
                    {
                        "npv": 0.0,
                        "irr": 0.0,
                        "paybackPeriod": 0.0,
                        "roi": 0.0,
                        "profitabilityCoefficient": 0.0,
                    }
                )
            else:
                result.update(
                    {
                        "npv": metrics["npv"],
                        "irr": metrics["irr"],
                        "paybackPeriod": metrics["paybackPeriod"],
                        "roi": metrics["roi"],
                        "profitabilityCoefficient": metrics[
                            "profitabilityCoefficient"
                        ],
                    }
                )

    def _calculate_financial_metrics(
        self,
        aerator_results: List[AeratorResult],
        annual_costs: List[Tuple[float, str, float, float]],
        inputs: AeratorComparisonInputs,
    ) -> Tuple[float, str, Dict[str, float]]:
        """Calculate financial metrics for aerator comparison.

        Args:
            aerator_results: List of aerator results.
            annual_costs: List of cost tuples.
            inputs: Input parameters for comparison.

        Returns:
            Tuple of cost of opportunity, winner name, and API results.
        """
        baseline_data, winner_data = self._extract_baseline_and_winner_data(
            annual_costs
        )
        baseline_cost = float(baseline_data["cost"])
        winner_cost = float(winner_data["cost"])

        financial_inputs = self._prepare_financial_inputs(
            baseline_cost,
            winner_cost,
            float(winner_data["units"]),
            float(winner_data["price"]),
        )
        financial_data = self._compute_financial_data(financial_inputs, inputs)
        metrics = compute_financial_metrics(financial_data)

        equilibrium_price = compute_equilibrium_price(
            {"cost": baseline_cost, "units": float(baseline_data["units"])},
            {
                "cost": winner_cost,
                "units": float(winner_data["units"]),
                "price": float(winner_data["price"]),
            },
        )
        cost_of_opportunity = metrics["npv"] if metrics["npv"] > 0 else 0.0

        self._update_aerator_results(
            aerator_results, str(baseline_data["name"]), metrics
        )

        return (
            cost_of_opportunity,
            str(winner_data["name"]),
            {
                "equilibriumPriceP2": round(equilibrium_price, 2),
                "costOfOpportunity": round(cost_of_opportunity, 2),
                "annualSavings": round(financial_data.annual_savings, 2),
            },
        )

    def compare_aerators(
        self, request: AeratorComparisonRequest
    ) -> ComparisonResults:
        """Compare aerators based on survey data.

        Args:
            request: Pydantic model for aerator comparison request.

        Returns:
            Comparison results with TOD, financial metrics,
            and aerator results.

        Raises:
            ValueError: If inputs are invalid.
            TypeError: If inputs have incorrect types.
            RuntimeError: If calculations or database logging fail.
        """
        try:
            params = self._extract_inputs(request.model_dump())
            self._validate_inputs(params)

            tod_results = calculate_tod(params, self.respiration_calc)
            total_demand_kg_h = tod_results["total_demand_kg_h"]

            annual_revenue = calculate_annual_revenue(
                params["production_kg_ha_year"],
                params["total_area"],
                params["shrimp_price_usd_kg"],
            )

            aerator_results, annual_costs = self._process_aerators(
                params, total_demand_kg_h, annual_revenue
            )

            cost_of_opportunity, winner_name, api_results = (
                self._calculate_financial_metrics(
                    aerator_results, annual_costs, params
                )
            )

            results: ComparisonResults = {
                "tod": round(total_demand_kg_h, 4),
                "shrimpRespiration": round(
                    tod_results["shrimp_demand_kg_h_ha"], 4
                ),
                "pondRespiration": round(
                    tod_results["pond_demand_kg_h_ha"], 4
                ),
                "pondWaterRespiration": round(
                    tod_results["water_demand_kg_h_ha"], 4
                ),
                "pondBottomRespiration": round(
                    tod_results["bottom_demand_kg_h_ha"], 4
                ),
                "annualRevenue": round(
                    annual_revenue, 2
                ),
                "costOfOpportunity": round(
                    cost_of_opportunity, 2
                ),
                "winnerLabel": winner_name,
                "aeratorResults": aerator_results,
                "apiResults": api_results,
            }

            self.log_comparison(request.model_dump(), results)

            return results

        except (ValueError, TypeError, RuntimeError, sqlite3.Error) as e:
            print(f"Error during aerator comparison: {e}")
            raise RuntimeError(f"Aerator comparison failed: {e}") from e


if __name__ == "__main__":
    import os
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    o2_data_path = os.path.join(
        project_root, "assets", "data", "o2_temp_sal_100_sat.json")
    shrimp_data_path = os.path.join(
        project_root,
        "assets",
        "data",
        "shrimp_respiration_salinity_temperature_weight.json"
    )

    db_path = ":memory:"

    try:
        sat_calc = SaturationCalculator(data_path=o2_data_path)
        resp_calc = ShrimpRespirationCalculator(data_path=shrimp_data_path)
        comparer = AeratorComparer(
            saturation_calculator=sat_calc,
            respiration_calculator=resp_calc,
            db_url=db_path
        )
        example_input: dict[str, Any] = {
            "farm": {
                "area_ha": 1000.0,
                "production_kg_ha_year": 10000.0,
                "cycles_per_year": 3.0,
                "pond_depth_m": 1.0,
            },
            "oxygen": {
                "temperature_c": 31.5,
                "salinity_ppt": 20.0,
                "shrimp_weight_g": 10.0,
                "biomass_kg_ha": 3333.33,
            },
            "aerators": [
                {
                    "name": "Aerator 1",
                    "power_hp": 3.0,
                    "sotr_kg_o2_h": 1.4,
                    "initial_cost_usd": 500.0,
                    "durability_years": 2.0,
                    "maintenance_usd_year": 65.0,
                },
                {
                    "name": "Aerator 2",
                    "power_hp": 3.5,
                    "sotr_kg_o2_h": 2.2,
                    "initial_cost_usd": 800.0,
                    "durability_years": 4.5,
                    "maintenance_usd_year": 50.0,
                },
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.05,
                "operating_hours_year": 2920.0,
                "discount_rate_percent": 10.0,
                "inflation_rate_percent": 2.5,
                "analysis_horizon_years": 9,
                "safety_margin_percent": 0.0,
            },
        }
        comparison_request = AeratorComparisonRequest(**example_input)
        comparison_results = comparer.compare_aerators(comparison_request)
        print("\n--- Aerator Comparison Results ---")
        if hasattr(comparison_results, 'model_dump'):
            results_dict = comparison_results
        else:
            results_dict = comparison_results

        for key, value in results_dict.items():
            print(f"{key}: {value}")

    except (
        ValueError,
        TypeError,
        RuntimeError,
        FileNotFoundError,
        sqlite3.Error,
    ) as e:
        print("\n--- Error ---")
        print(f"An error occurred: {e}")
        if isinstance(e, FileNotFoundError):
            print("Please ensure data files exist at the specified paths.")
        elif isinstance(e, sqlite3.Error):
            print("Database error occurred.")

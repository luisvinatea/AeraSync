"""
AeratorComparer module for comparing aerators based on technical and financial
parameters.
"""
import json
import logging
import sqlite3
from typing import List, Tuple

import numpy as np
import numpy_financial as npf

# Import necessary types from aerator_types
from .aerator_types import (
    Aerator,
    AeratorComparisonRequest,
    AeratorResult,
    ComparisonResults,
    FinancialInput,
)
from .sotr_calculator import SaturationCalculator
from .shrimp_respiration_calculator import ShrimpRespirationCalculator

# Configure logging
logger: logging.Logger = logging.getLogger(__name__)


class AeratorComparer:
    """Compares aerators based on technical and financial parameters."""

    def __init__(
        self,
        saturation_calculator: SaturationCalculator,
        respiration_calculator: ShrimpRespirationCalculator,
        # Default to shared in-memory DB URI
        db_url: str = "file::memory:?cache=shared",
    ):
        """
        Initialize the AeratorComparer.

        Args:
            saturation_calculator: An instance of SaturationCalculator.
            respiration_calculator: An instance of ShrimpRespirationCalculator.
            db_url: Database URL for logging (defaults to shared in-memory).
        """
        self.saturation_calculator = saturation_calculator
        self.respiration_calculator = respiration_calculator
        self.db_url = db_url
        # Ensure the table exists when the instance is created
        self._create_table_if_not_exists()

    def _create_table_if_not_exists(self):
        """Create the aerator_comparisons table if it doesn't exist."""
        try:
            # Use check_same_thread=False for FastAPI/multi-threaded access
            with sqlite3.connect(self.db_url, check_same_thread=False) as conn:
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
                logger.info(
                    "Database table 'aerator_comparisons' checked/created."
                )
        except sqlite3.Error as db_err:
            logger.error("SQLite error creating table: %s", db_err)
            # Decide if this should be a critical error
            raise RuntimeError(
                f"Failed to initialize database table: {db_err}"
            ) from db_err

    def log_comparison(self, inputs: dict, results: dict) -> None:
        """Log comparison inputs and results to the database."""
        try:
            # Use check_same_thread=False for FastAPI/multi-threaded access
            with sqlite3.connect(self.db_url, check_same_thread=False) as conn:
                cursor = conn.cursor()
                # Serialize inputs and results to JSON strings
                # Use default=str to handle potential non-serializable types
                # like Decimal
                inputs_json = json.dumps(inputs, default=str)
                results_json = json.dumps(results, default=str)
                cursor.execute(
                    """
                    INSERT INTO aerator_comparisons (inputs, results)
                    VALUES (?, ?)
                    """,
                    (inputs_json, results_json),
                )
                conn.commit()
                logger.info("Comparison logged successfully to the database.")
        except sqlite3.Error as db_err:
            # Log the error but don't let DB errors crash the main comparison
            logger.error("SQLite database error during logging: %s", db_err)
            # Re-raise as a runtime error to signal logging failure
            raise RuntimeError(
                f"Failed to log comparison: {db_err}"
            ) from db_err
        except Exception as e:
            # Catch other potential errors during logging
            logger.error("Unexpected error during logging: %s", e)
            raise RuntimeError(f"Unexpected error during logging: {e}") from e

    def calculate_tod(
        self, request: AeratorComparisonRequest
    ) -> Tuple[float, float]:
        """
        Calculate Total Oxygen Demand (TOD) for the shrimp farm.

        Args:
            request: The comparison request containing farm and oxygen data.

        Returns:
            A tuple containing TOD in kg O2/hour and kg O2/day.
        """
        # Calculate shrimp respiration rate
        respiration_rate_mg_o2_kg_h: float = (
            self.respiration_calculator.get_respiration_rate(
                # Corrected parameter names
                temperature=request.oxygen.temperature_c,
                salinity=request.oxygen.salinity_ppt,
                shrimp_weight=request.oxygen.shrimp_weight_g,
            )
        )

        # Calculate Total Oxygen Demand (TOD)
        total_biomass_kg: float = (
            request.oxygen.biomass_kg_ha * request.farm.area_ha
        )
        tod_mg_o2_h: float = respiration_rate_mg_o2_kg_h * total_biomass_kg
        tod_kg_o2_h: float = tod_mg_o2_h / 1_000_000  # Convert mg to kg
        tod_kg_o2_day: float = tod_kg_o2_h * 24

        logger.info(
            "Calculated TOD: %.2f kg O2/hour, %.2f kg O2/day",
            tod_kg_o2_h,
            tod_kg_o2_day,
        )
        return tod_kg_o2_h, tod_kg_o2_day

    def calculate_aerator_performance(
        self,
        aerator: Aerator,
        tod_kg_o2_h: float,
        financial_input: FinancialInput,
        farm_area_ha: float,
    ) -> AeratorResult:
        """
        Calculate performance metrics for a single aerator.

        Args:
            aerator: The aerator data.
            tod_kg_o2_h: Total Oxygen Demand in kg O2/hour.
            financial_input: Financial parameters.
            farm_area_ha: Total farm area in hectares.

        Returns:
            An AeratorResult object containing calculated metrics.
        """
        # Constants
        hp_to_kw: float = 0.7457

        # Apply safety margin to TOD
        required_sotr_kg_o2_h: float = tod_kg_o2_h * (
            1 + financial_input.safety_margin_percent / 100
        )

        # Calculate number of aerators needed
        # Ensure division by zero is handled if SOTR is zero
        if aerator.sotr_kg_o2_h <= 0:
            num_aerators = (
                0  # Or raise an error, depending on desired behavior
            )
            logger.warning(
                "Aerator '%s' has SOTR <= 0, cannot calculate needed units.",
                aerator.name,
            )
        else:
            num_aerators_float: float = (
                required_sotr_kg_o2_h / aerator.sotr_kg_o2_h
            )
            # Round up to the nearest whole number
            num_aerators: int = int(np.ceil(num_aerators_float))

        # Calculate total power consumption
        total_power_hp: float = num_aerators * aerator.power_hp
        total_power_kw: float = total_power_hp * hp_to_kw

        # Calculate total initial cost
        total_initial_cost: float = num_aerators * aerator.initial_cost_usd

        # Calculate annual costs
        annual_energy_cost: float = (
            total_power_kw
            * financial_input.energy_cost_usd_kwh
            * financial_input.operating_hours_year
        )
        annual_maintenance_cost: float = (
            num_aerators * aerator.maintenance_usd_year
        )

        # Calculate Net Present Value (NPV) of costs over the analysis horizon
        horizon: int = financial_input.analysis_horizon_years
        discount_rate: float = financial_input.discount_rate_percent / 100
        inflation_rate: float = financial_input.inflation_rate_percent / 100

        cash_flows: List[float] = [-total_initial_cost]  # Year 0 cost

        for year in range(1, horizon + 1):
            # Inflate costs
            current_energy_cost: float = annual_energy_cost * (
                (1 + inflation_rate) ** year
            )
            current_maintenance_cost: float = annual_maintenance_cost * (
                (1 + inflation_rate) ** year
            )
            total_annual_cost: float = (
                current_energy_cost + current_maintenance_cost
            )

            # Ensure durability_years is positive before modulo operation
            if (
                aerator.durability_years > 0
                and year % int(np.ceil(aerator.durability_years)) == 0
            ):
                replacement_cost: float = total_initial_cost * (
                    (1 + inflation_rate) ** year
                )
                total_annual_cost += replacement_cost

            # Costs are negative cash flows
            cash_flows.append(-total_annual_cost)

        # Calculate NPV using numpy_financial
        npv_cost: float = npf.npv(discount_rate, cash_flows)

        # Calculate other metrics
        aerators_per_ha: float = (
            num_aerators / farm_area_ha if farm_area_ha > 0 else 0
        )
        hp_per_ha: float = (
            total_power_hp / farm_area_ha if farm_area_ha > 0 else 0
        )

        # Reformat long log message for clarity and line length
        logger.debug(
            "Calculated performance for aerator '%s': "
            "Num=%d, Power=%.2f HP, InitCost=%.2f USD, "
            "AnnEnergy=%.2f USD, AnnMaint=%.2f USD, NPV=%.2f USD, "
            "Aer/ha=%.2f, HP/ha=%.2f",
            aerator.name,
            num_aerators,
            total_power_hp,
            total_initial_cost,
            annual_energy_cost,
            annual_maintenance_cost,
            npv_cost,
            aerators_per_ha,
            hp_per_ha,
        )

        return AeratorResult(
            name=aerator.name,
            brand=aerator.brand,
            type=aerator.type,
            num_aerators=num_aerators,
            total_power_hp=total_power_hp,
            total_initial_cost=total_initial_cost,
            annual_energy_cost=annual_energy_cost,
            annual_maintenance_cost=annual_maintenance_cost,
            npv_cost=npv_cost,
            aerators_per_ha=aerators_per_ha,
            hp_per_ha=hp_per_ha,
        )

    def compare_aerators(
        self, request: AeratorComparisonRequest
    ) -> ComparisonResults:
        """
        Compare multiple aerators based on the provided request data.

        Args:
            request: The comparison request containing all input data.

        Returns:
            A ComparisonResults object containing TOD and results for each
            aerator.

        Raises:
            ValueError: If fewer than two aerators are provided for comparison.
        """
        if len(request.aerators) < 2:
            logger.error("Comparison requires at least two aerators.")
            raise ValueError("At least two aerators are required")

        logger.info(
            "Starting aerator comparison for %d aerators.",
            len(request.aerators)
        )

        # Calculate TOD
        tod_kg_o2_h, tod_kg_o2_day = self.calculate_tod(request)

        # Calculate performance for each aerator
        results: List[AeratorResult] = []
        for aerator_input in request.aerators:
            # Ensure we are working with an Aerator model instance
            # This assumes aerator_input is compatible (e.g., a dict or
            # Pydantic model)
            # If aerator_input is already an Aerator instance, this is
            # redundant but safe.
            # If it's a dict, it converts it.
            if isinstance(aerator_input, Aerator):
                aerator = aerator_input
            else:
                # Attempt conversion, assuming dict-like structure
                try:
                    aerator = Aerator(**aerator_input.model_dump())
                # Handle case where it might be a raw dict
                except AttributeError:
                    aerator = Aerator(**aerator_input)

            result = self.calculate_aerator_performance(
                aerator=aerator,
                tod_kg_o2_h=tod_kg_o2_h,
                financial_input=request.financial,
                farm_area_ha=request.farm.area_ha,
            )
            results.append(result)

        # Determine the winner based on the lowest NPV of costs
        # Handle potential empty results list although check above should
        # prevent it
        if not results:
            logger.error("No aerator results generated for comparison.")
            # Decide how to handle this - raise error or return empty/default?
            # For now, let's raise an error or return a specific state
            raise ValueError("Could not generate results for any aerator.")

        winner = min(results, key=lambda x: x.npv_cost)
        winner_label = winner.name

        logger.info(
            "Comparison complete. Winner: %s (NPV: %.2f)",
            winner_label,
            winner.npv_cost,
        )

        comparison_output = ComparisonResults(
            tod={"kg_o2_hour": tod_kg_o2_h, "kg_o2_day": tod_kg_o2_day},
            aeratorResults=results,
            winnerLabel=winner_label,
        )

        # Log the comparison attempt
        try:
            # Convert Pydantic models to dicts for logging
            request_dict = request.model_dump()
            results_dict = comparison_output.model_dump()
            self.log_comparison(request_dict, results_dict)
        except (TypeError, ValueError) as serial_err:
            # Catch potential errors during model_dump
            logger.error("Error serializing data for logging: %s", serial_err)
        except RuntimeError as e:
            logger.error(
                "Unexpected runtime error during logging setup: %s", e
            )

        return comparison_output

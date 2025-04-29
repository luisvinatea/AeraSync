"""Calculation functions for aerator comparison."""

import math  # Import math for pow
from typing import Dict, List, TypedDict
from pydantic import BaseModel

from .shrimp_respiration_calculator import ShrimpRespirationCalculator
from .sotr_calculator import ShrimpPondCalculator as SaturationCalculator


# Define input types for Total Oxygen Demand calculation
class TODInputs(TypedDict):
    """TypedDict for Total Oxygen Demand inputs."""
    biomass_kg_ha: float
    shrimp_weight: float
    salinity: float
    temperature: float
    pond_depth: float
    total_area: float
    safety_margin_percent: float


# Define Pydantic model for financial data inputs
class FinancialData(BaseModel):
    """TypedDict for financial data inputs."""
    initial_investment: float
    cash_flows: List[float]
    discount_rate: float
    inflation_rate: float
    horizon: int


# Helper function for Newton-Raphson method
def _newton_raphson(func, func_prime, x0, tol=1e-6, maxiter=100):
    """Manual implementation of Newton-Raphson root finding."""
    x = x0
    for _ in range(maxiter):
        fx = func(x)
        fpx = func_prime(x)

        # Avoid division by zero or very small numbers
        if abs(fpx) < 1e-10:
            raise ValueError("Derivative near zero during Newton's method.")

        delta_x = fx / fpx
        x = x - delta_x

        # Check for convergence
        if abs(delta_x) < tol:
            return x

    raise RuntimeError(
        f"Newton's method did not converge after {maxiter} iterations.")


def calculate_otrt(
    sotr: float,
    temperature: float,
    salinity: float,
    saturation_calc: SaturationCalculator,
    theta: float = 1.024,
    standard_temp: float = 20.0,
) -> float:
    """Calculate Oxygen Transfer Rate at temperature T (OTRt).

    Args:
        sotr: Standard Oxygen Transfer Rate in kg O₂/h.
        temperature: Water temperature in °C.
        salinity: Salinity in ppt.
        saturation_calc: Calculator for oxygen saturation.
        theta: Temperature correction factor (default: 1.024).
        standard_temp: Standard temperature in °C (default: 20.0).

    Returns:
        OTRt in kg O₂/h.

    Raises:
        ValueError: If SOTR or O2 saturation is non-positive.
    """
    if sotr <= 0:
        # Added error message
        raise ValueError(f"SOTR must be positive, got {sotr}")
    cs_20 = saturation_calc.get_o2_saturation(standard_temp, salinity)
    if cs_20 <= 0:
        # Added error message
        raise ValueError(f"Calculated Cs(20) must be positive, got {cs_20}")
    temp_corr = theta ** (temperature - standard_temp)
    # Assuming a fixed saturation correction factor for simplicity,
    # replace with actual calculation if needed.
    sat_corr = 0.5  # Placeholder: Adjust if a dynamic calculation is required
    otrt = sotr * temp_corr * sat_corr
    if otrt <= 0:
        # This should ideally not happen if inputs are valid, but check anyway
        raise ValueError(
            f"Calculated OTRt is non-positive ({otrt}), check inputs.")
    return otrt


def calculate_shrimp_demand(
    biomass_kg_ha: float,
    shrimp_weight: float,
    salinity: float,
    temperature: float,
    respiration_calc: ShrimpRespirationCalculator,
) -> float:
    """Calculate shrimp oxygen demand in kg O₂/h/ha."""
    if biomass_kg_ha < 0 or shrimp_weight <= 0:
        raise ValueError(
            "Biomass must be non-negative and shrimp weight must be positive.")
    # Respiration rate in mg O₂/g/h
    respiration_rate_mg_g_h = respiration_calc.get_respiration_rate(
        salinity, temperature, shrimp_weight
    )
    # Convert rate:
    # (mg O₂ / g shrimp / h) * (1 g shrimp / 1000 mg shrimp) *
    # (1 kg O₂ / 1,000,000 mg O₂)
    # = kg O₂ / mg shrimp / h * 1e-9 -- this seems wrong.
    # Let's rethink units:
    # Rate: mg O₂ / g_shrimp / h
    # Biomass: kg_shrimp / ha = 1000 g_shrimp / ha
    # Demand = Rate * Biomass
    # Demand = (mg O₂ / g_shrimp / h) * (Biomass_kg_ha * 1000 g_shrimp / ha)
    # Demand = (Biomass_kg_ha * 1000) mg O₂ / ha / h
    # Convert mg to kg: Divide by 1,000,000
    # Demand = (Biomass_kg_ha * 1000 / 1000000) kg O₂ / ha / h
    # Demand = (Biomass_kg_ha / 1000) kg O₂ / ha / h
    demand_kg_h_ha = respiration_rate_mg_g_h * (biomass_kg_ha / 1000.0)
    return demand_kg_h_ha


def calculate_water_demand(pond_depth: float) -> float:
    """Estimate water column oxygen demand in kg O₂/h/ha (simplified)."""
    # Placeholder: Replace with a more accurate model if available
    # Example: Assume demand is proportional to depth
    if pond_depth <= 0:
        raise ValueError("Pond depth must be positive.")
    base_demand = 0.05  # Base demand in kg O₂/h/ha for 1m depth
    return base_demand * pond_depth


def calculate_bottom_demand(
    pond_depth: float, bottom_volume_factor: float = 0.05
) -> float:
    """Estimate pond bottom oxygen demand in kg O₂/h/ha (simplified)."""
    # Placeholder: Replace with a more accurate model if available
    # Example: Assume demand is related to depth or a fixed value
    if pond_depth <= 0:
        raise ValueError("Pond depth must be positive.")
    # Simple model: fixed demand, potentially adjusted by factor
    # (though factor use here is unclear)
    fixed_bottom_demand = 0.1  # Example fixed demand in kg O₂/h/ha
    # Using bottom_volume_factor doesn't seem directly applicable here unless
    # it modifies the fixed demand
    # Example adjustment
    return fixed_bottom_demand * (1 + bottom_volume_factor)


def calculate_tod(
    inputs: TODInputs, respiration_calc: ShrimpRespirationCalculator
) -> Dict[str, float]:
    """Calculate Total Oxygen Demand (TOD) components.

    Args:
        inputs: Dictionary containing necessary parameters.
        respiration_calc: Calculator for shrimp respiration.

    Returns:
        Dictionary with TOD components in kg O₂/h/ha and total kg O₂/h.
    """
    shrimp_demand = calculate_shrimp_demand(
        inputs["biomass_kg_ha"],
        inputs["shrimp_weight"],
        inputs["salinity"],
        inputs["temperature"],
        respiration_calc,
    )
    water_demand = calculate_water_demand(inputs["pond_depth"])
    bottom_demand = calculate_bottom_demand(
        inputs["pond_depth"])  # Assuming default factor

    total_demand_ha = shrimp_demand + water_demand + bottom_demand

    # Apply safety margin if provided and valid
    safety_margin = inputs.get("safety_margin_percent", 0) or 0
    if not isinstance(safety_margin, (int, float)) or safety_margin < 0:
        safety_margin = 0  # Default to 0 if invalid
    total_demand_ha_safe = total_demand_ha * (1 + safety_margin / 100.0)

    total_demand_kg_h = total_demand_ha_safe * inputs["total_area"]

    return {
        "shrimp_demand_kg_h_ha": shrimp_demand,
        "water_demand_kg_h_ha": water_demand,
        "bottom_demand_kg_h_ha": bottom_demand,
        "pond_demand_kg_h_ha": (
            water_demand + bottom_demand
        ),  # Combined pond demand
        # Demand per hectare before safety margin
        "total_demand_kg_h_ha": total_demand_ha,
        # Demand per hectare with safety margin
        "total_demand_kg_h_ha_safe": total_demand_ha_safe,
        # Total farm demand with safety margin
        "total_demand_kg_h": total_demand_kg_h,
    }


def calculate_annual_revenue(
    production_kg_ha_year: float, total_area: float, shrimp_price_usd_kg: float
) -> float:
    """Calculate total annual revenue."""
    if production_kg_ha_year < 0 or total_area <= 0 or shrimp_price_usd_kg < 0:
        raise ValueError(
            "Production, area, and price must be non-negative, "
            "area must be positive."
        )
    return production_kg_ha_year * total_area * shrimp_price_usd_kg


def calculate_npv(
    cash_flows: List[float],
    discount_rate: float,
    inflation_rate: float,
    horizon: int
) -> float:
    """Calculate Net Present Value (NPV)."""
    if horizon <= 0 or len(cash_flows) != horizon:
        raise ValueError(
            "Horizon must be positive and match cash flow length.")
    if discount_rate == inflation_rate:
        raise ValueError("Discount rate cannot equal inflation rate.")

    real_discount_rate = (1 + discount_rate) / (1 + inflation_rate) - 1
    if real_discount_rate <= -1:
        # Avoid division by zero or negative base in power
        raise ValueError(
            "Invalid combination of discount and inflation rates.")

    npv = 0.0
    for i, cf in enumerate(cash_flows):
        npv += cf / math.pow(1 + real_discount_rate, i + 1)  # Use math.pow
    return npv


def calculate_irr(
    initial_investment: float, cash_flows: List[float], horizon: int
) -> float:
    """Calculate Internal Rate of Return (IRR) using manual Newton-Raphson.

    Args:
        initial_investment: Initial investment amount.
        cash_flows: List of annual cash flows.
        horizon: Analysis horizon in years.

    Returns:
        IRR as a percentage.

    Raises:
        ValueError: If IRR calculation fails or inputs are invalid.
    """
    if initial_investment <= 0:
        raise ValueError(
            "Initial investment must be positive for IRR calculation.")
    if not cash_flows or len(cash_flows) != horizon:
        raise ValueError("Cash flows list must match the horizon.")

    # Define the NPV function for the root finder
    def npv_func(rate: float) -> float:
        if rate <= -1.0:  # Avoid issues with the denominator
            # Return a large value to push the solver away from this region
            return float('inf')
        npv = -initial_investment
        for i, cf in enumerate(cash_flows):
            try:
                npv += cf / math.pow(1 + rate, i + 1)  # Use math.pow
            except ValueError:
                # Handle potential domain errors if 1+rate is negative
                return float('inf')
        return npv

    # Define the derivative of the NPV function
    def npv_func_prime(rate: float) -> float:
        if rate <= -1.0:  # Avoid issues with the denominator
            return 0.0  # Or raise error, derivative is ill-defined
        derivative = 0.0
        for i, cf in enumerate(cash_flows):
            try:
                denominator = math.pow(1 + rate, i + 2)  # Use math.pow
                if abs(denominator) < 1e-12:  # Avoid division by zero
                    return 0.0  # Or handle as error
                derivative -= (i + 1) * cf / denominator
            except ValueError:
                return 0.0  # Or raise error
        return derivative

    try:
        # Use manual Newton-Raphson method
        # Start with an initial guess (e.g., 10%)
        irr_rate = _newton_raphson(
            npv_func, npv_func_prime, 0.1, tol=1e-6, maxiter=100)
    except (RuntimeError, ValueError) as e:
        # Handle cases where convergence fails or derivative is zero
        # Try a different initial guess? Or indicate failure.
        # Let's try 0 as another guess
        try:
            irr_rate = _newton_raphson(
                npv_func, npv_func_prime, 0.0, tol=1e-6, maxiter=100)
        except (RuntimeError, ValueError) as e2:
            raise ValueError(f"IRR calculation failed: {e} / {e2}") from e2

    # Check if the result is reasonable (e.g., not excessively large/small)
    # Bounds can be adjusted based on expected financial scenarios
    # Allow slightly negative IRR, cap upper bound
    if not -0.99 < irr_rate < 5:
        print(
            f"Warning: IRR result ({irr_rate:.2%}) is outside typical bounds."
        )
        # Depending on requirements, might cap, return NaN, or raise error.
        # Returning as is for now, with warning.

    return irr_rate * 100  # Return as percentage


def compute_financial_metrics(
    financial_data: FinancialData
) -> Dict[str, float]:
    """Compute key financial metrics (NPV, IRR, Payback, ROI, Profitability).

    Args:
        financial_data: Pydantic model containing all necessary
            financial inputs.

    Returns:
        Dictionary containing calculated financial metrics.
    """
    if financial_data.initial_investment <= 0:
        # Handle cases with no investment (or return default metrics)
        return {
            "npv": 0.0, "irr": 0.0, "paybackPeriod": 0.0,
            "roi": 0.0, "profitabilityCoefficient": 0.0
        }

    # Calculate NPV
    npv = calculate_npv(
        financial_data.cash_flows,
        financial_data.discount_rate,
        financial_data.inflation_rate,
        financial_data.horizon
    )

    # Calculate IRR
    try:
        irr = calculate_irr(
            financial_data.initial_investment,
            financial_data.cash_flows,
            financial_data.horizon
        )
    except ValueError as e:
        print(f"IRR calculation failed: {e}. Setting IRR to -100%.")
        irr = -100.0  # Indicate failure

    # Calculate Payback Period
    cumulative_cash_flow = -financial_data.initial_investment
    payback_period = 0.0
    for i, cf in enumerate(financial_data.cash_flows):
        cumulative_cash_flow += cf
        if cumulative_cash_flow >= 0:
            # Calculate fractional year if needed
            payback_period = (i + 1) - (cumulative_cash_flow /
                                        cf) if cf != 0 else (i + 1)
            break
    else:
        payback_period = float('inf')  # Payback period exceeds horizon

    # Calculate ROI (Simple ROI for now)
    total_savings = sum(financial_data.cash_flows)
    roi = (
        ((total_savings - financial_data.initial_investment) /
         financial_data.initial_investment) * 100
        if financial_data.initial_investment else 0.0
    )

    # Calculate Profitability Coefficient (NPV / Initial Investment)
    profitability_coefficient = (
        npv / financial_data.initial_investment
        if financial_data.initial_investment else 0.0
    )

    return {
        "npv": npv,
        "irr": irr,  # Already in percentage
        "paybackPeriod": payback_period,
        "roi": roi,  # Already in percentage
        "profitabilityCoefficient": profitability_coefficient,
    }


def compute_equilibrium_price(
    baseline: Dict[str, float], winner: Dict[str, float]
) -> float:
    """Compute the equilibrium price for the winning aerator.

    Args:
        baseline: Dictionary with baseline aerator cost and units.
        winner: Dictionary with winner aerator cost, units, and current price.

    Returns:
        Equilibrium price in USD.

    Raises:
        ValueError: If winner units is zero.
    """
    baseline_cost = baseline.get("cost", 0.0)
    winner_cost_no_price = winner.get("cost", 0.0) - (winner.get(
        # Cost excluding initial purchase
        "price", 0.0) * winner.get("units", 0.0))
    winner_units = winner.get("units", 0.0)

    if winner_units <= 0:
        raise ValueError(
            "Winner units must be positive to calculate equilibrium price.")

    # Equilibrium when Baseline Annual Cost = Winner Annual Cost
    # (excluding initial price) + EqPrice * WinnerUnits
    # EqPrice = (Baseline Cost - Winner Cost (excluding initial price))
    #           / WinnerUnits
    equilibrium_price = (baseline_cost - winner_cost_no_price) / winner_units

    return max(0, equilibrium_price)  # Price cannot be negative

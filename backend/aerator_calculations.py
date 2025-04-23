"""Calculation functions for aerator comparison."""

from typing import Dict, List

from scipy.optimize import newton
from shrimp_respiration_calculator import ShrimpRespirationCalculator
from sotr_calculator import (
    ShrimpPondCalculator as SaturationCalculator
)

from aerator_types import FinancialData, TODInputs


def calculate_otrt(
    sotr: float,
    temperature: float,
    salinity: float,
    saturation_calc: SaturationCalculator,
    theta: float = 1.024,
    standard_temp: float = 20.0
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
        raise ValueError(f"SOTR must be positive, got {sotr}")
    cs_20 = saturation_calc.get_o2_saturation(standard_temp, salinity)
    if cs_20 <= 0:
        raise ValueError(f"O2 saturation at 20°C is {cs_20}")
    temp_corr = theta ** (temperature - standard_temp)
    sat_corr = 0.5
    otrt = sotr * temp_corr * sat_corr
    if otrt <= 0:
        raise ValueError(f"OTRt must be positive, got {otrt}")
    return otrt


def calculate_shrimp_demand(
    biomass_kg_ha: float,
    shrimp_weight: float,
    salinity: float,
    temperature: float,
    respiration_calc: ShrimpRespirationCalculator
) -> float:
    """Calculate shrimp oxygen demand in kg O₂/h/ha.

    Args:
        biomass_kg_ha: Biomass in kg/ha.
        shrimp_weight: Shrimp weight in grams.
        salinity: Salinity in ppt.
        temperature: Temperature in °C.
        respiration_calc: Calculator for shrimp respiration.

    Returns:
        Shrimp oxygen demand in kg O₂/h/ha.

    Raises:
        ValueError: If biomass or shrimp weight is invalid.
    """
    if biomass_kg_ha < 0:
        raise ValueError(f"Biomass must be non-negative, got {biomass_kg_ha}")
    if shrimp_weight <= 0:
        raise ValueError(
            f"Shrimp weight must be positive, got {shrimp_weight}"
        )
    resp_rate = respiration_calc.get_respiration_rate(
        salinity, temperature, shrimp_weight
    )
    return resp_rate * biomass_kg_ha * 1000.0 / 1_000_000.0


def calculate_water_demand(pond_depth: float) -> float:
    """Calculate water oxygen demand in kg O₂/h/ha.

    Args:
        pond_depth: Pond depth in meters.

    Returns:
        Water oxygen demand in kg O₂/h/ha.

    Raises:
        ValueError: If pond depth is non-positive.
    """
    if pond_depth <= 0:
        raise ValueError(f"Pond depth must be positive, got {pond_depth}")
    water_vol_ha = 10000.0 * pond_depth
    water_rate = 0.49125
    return water_rate * water_vol_ha * 1000.0 / 1_000_000.0


def calculate_bottom_demand(
    pond_depth: float, bottom_volume_factor: float = 0.05
) -> float:
    """Calculate bottom oxygen demand in kg O₂/h/ha.

    Args:
        pond_depth: Pond depth in meters.
        bottom_volume_factor: Factor for bottom volume (default: 0.05).

    Returns:
        Bottom oxygen demand in kg O₂/h/ha.

    Raises:
        ValueError: If pond depth is non-positive.
    """
    if pond_depth <= 0:
        raise ValueError(f"Pond depth must be positive, got {pond_depth}")
    water_vol_ha = 10000.0 * pond_depth
    bottom_rate = 0.245625
    return (
        bottom_rate * water_vol_ha * bottom_volume_factor * 1000.0
        / 1_000_000.0
    )


def calculate_tod(
    inputs: TODInputs,
    respiration_calc: ShrimpRespirationCalculator
) -> Dict[str, float]:
    """Calculate Total Oxygen Demand (TOD) in kg O₂/h.

    Args:
        inputs: Input parameters for TOD calculation.
        respiration_calc: Calculator for shrimp respiration.

    Returns:
        Dictionary with TOD and component demands in kg O₂/h and kg O₂/h/ha.

    Raises:
        ValueError: If total area or TOD is non-positive.
    """
    total_area = inputs['total_area']
    if total_area <= 0:
        raise ValueError(f"Total area must be positive, got {total_area}")

    shrimp_demand = calculate_shrimp_demand(
        inputs['biomass_kg_ha'], inputs['shrimp_weight'], inputs['salinity'],
        inputs['temperature'], respiration_calc
    )
    water_demand = calculate_water_demand(inputs['pond_depth'])
    bottom_demand = calculate_bottom_demand(inputs['pond_depth'])

    pond_demand = water_demand + bottom_demand
    total_per_ha = shrimp_demand + pond_demand
    total_demand = total_per_ha * total_area

    safety_margin_percent = inputs['safety_margin_percent']
    if safety_margin_percent is not None and safety_margin_percent > 0:
        total_demand *= (1 + safety_margin_percent / 100.0)

    if total_demand <= 0:
        raise ValueError(f"TOD must be positive, got {total_demand}")

    return {
        "total_demand_kg_h": total_demand,
        "shrimp_demand_kg_h_ha": shrimp_demand,
        "pond_demand_kg_h_ha": pond_demand,
        "water_demand_kg_h_ha": water_demand,
        "bottom_demand_kg_h_ha": bottom_demand
    }


def calculate_annual_revenue(
    production_kg_ha_year: float,
    total_area: float,
    shrimp_price_usd_kg: float
) -> float:
    """Calculate annual revenue.

    Args:
        production_kg_ha_year: Production in kg/ha/year.
        total_area: Total area in hectares.
        shrimp_price_usd_kg: Shrimp price in USD/kg.

    Returns:
        Annual revenue in USD.

    Raises:
        ValueError: If production, area, or price is negative.
    """
    if production_kg_ha_year < 0:
        raise ValueError(
            f"Production must be non-negative, got {production_kg_ha_year}"
        )
    if total_area < 0:
        raise ValueError(
            f"Area must be non-negative, got {total_area}"
        )
    if shrimp_price_usd_kg < 0:
        raise ValueError(
            f"Price must be non-negative, got {shrimp_price_usd_kg}"
        )
    total_yield_kg = production_kg_ha_year * total_area
    return total_yield_kg * shrimp_price_usd_kg


def calculate_npv(
    cash_flows: List[float],
    discount_rate: float,
    inflation_rate: float,
    horizon: int
) -> float:
    """Calculate NPV with growing annuity.

    Args:
        cash_flows: List of cash flows for each year.
        discount_rate: Discount rate in decimal (e.g., 0.1 for 10%).
        inflation_rate: Inflation rate in decimal (e.g., 0.025 for 2.5%).
        horizon: Analysis horizon in years.

    Returns:
        NPV in USD.

    Raises:
        ValueError: If horizon is non-positive.
    """
    if horizon <= 0:
        raise ValueError(f"Analysis horizon must be positive, got {horizon}")
    npv = 0.0
    for t in range(horizon):
        growth_factor = (1 + inflation_rate) ** t
        discount_factor = (1 + discount_rate) ** (t + 1)
        npv += (cash_flows[t] * growth_factor) / discount_factor
    return npv


def calculate_irr(
    initial_investment: float,
    cash_flows: List[float],
    horizon: int
) -> float:
    """Calculate IRR using numerical method.

    Args:
        initial_investment: Initial investment in USD.
        cash_flows: List of cash flows for each year.
        horizon: Analysis horizon in years.

    Returns:
        IRR as a percentage.

    Raises:
        ValueError: If initial investment or horizon is invalid.
    """
    if initial_investment <= 0:
        raise ValueError(
            f"Initial investment must be positive, got {initial_investment}"
        )
    if horizon <= 0:
        raise ValueError(
            f"Analysis horizon must be positive, got {horizon}"
        )
    if len(cash_flows) != horizon:
        raise ValueError(
            f"Cash flows length must match horizon, got {len(cash_flows)}"
        )
    if not cash_flows:
        raise ValueError("Cash flows list must not be empty")

    def npv_for_irr(r: float) -> float:
        npv = -initial_investment
        for t in range(horizon):
            npv += cash_flows[t] / (1 + r) ** (t + 1)
        return npv

    try:
        irr: float = float(newton(npv_for_irr, 0.1, maxiter=1000))
        return irr * 100
    except RuntimeError:
        return float('inf')


def compute_financial_metrics(
    financial_data: FinancialData
) -> Dict[str, float]:
    """Compute NPV, IRR, payback period, ROI, and profitability coefficient.

    Args:
        financial_data: Financial input parameters.

    Returns:
        Dictionary with financial metrics.
    """
    initial_investment = financial_data.initial_investment
    annual_savings = financial_data.annual_savings
    cash_flows = financial_data.cash_flows
    discount_rate = financial_data.discount_rate
    inflation_rate = financial_data.inflation_rate
    horizon = financial_data.horizon

    npv_value = (
        calculate_npv(cash_flows, discount_rate, inflation_rate, horizon)
        if initial_investment > 0
        else 0.0
    )
    irr_value = (
        calculate_irr(initial_investment, cash_flows, horizon)
        if initial_investment > 0
        else 0.0
    )
    payback_period = (
        initial_investment / annual_savings * 12
        if annual_savings > 0 and initial_investment > 0
        else float('inf')
    )
    roi = (
        npv_value / initial_investment * 100
        if initial_investment > 0
        else 0.0
    )
    k = (
        npv_value / initial_investment
        if initial_investment > 0
        else 0.0
    )

    return {
        'npv': npv_value,
        'irr': irr_value,
        'paybackPeriod': payback_period,
        'roi': roi,
        'profitabilityCoefficient': k
    }


def compute_equilibrium_price(
    baseline: Dict[str, float],
    winner: Dict[str, float]
) -> float:
    """Compute equilibrium price for the winning aerator.

    Args:
        baseline: Baseline aerator data (cost, units).
        winner: Winner aerator data (cost, units, price).

    Returns:
        Equilibrium price in USD.
    """
    equilibrium_price = float('inf')
    baseline_unit_cost = (
        baseline['cost'] / baseline['units']
        if baseline['units'] > 0 else float('inf')
    )
    if winner['units'] > 0:
        equilibrium_price = (
            baseline_unit_cost * winner['units']
            - winner['cost'] + winner['price']
        )
    return equilibrium_price

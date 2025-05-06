# /home/luisvinatea/DEVinatea/Repos/AeraSync/backend/api/core/models.py
"""
Models for aerator comparison.
Contains data structures and type definitions for the aerator comparison system.
"""

from typing import NamedTuple

class Aerator(NamedTuple):
    name: str
    sotr: float
    power_hp: float
    cost: float
    durability: float
    maintenance: float


class FinancialInput(NamedTuple):
    energy_cost: float
    hours_per_night: float
    discount_rate: float
    inflation_rate: float
    horizon: int
    safety_margin: float
    temperature: float


class FarmInput(NamedTuple):
    tod: float
    farm_area_ha: float
    shrimp_price: float
    culture_days: float
    shrimp_density_kg_m3: float
    pond_depth_m: float


class AeratorResult(NamedTuple):
    name: str
    num_aerators: int
    total_power_hp: float
    total_initial_cost: float
    annual_energy_cost: float
    annual_maintenance_cost: float
    annual_replacement_cost: float
    total_annual_cost: float
    cost_percent_revenue: float
    npv_savings: float
    payback_years: float
    roi_percent: float
    irr: float
    profitability_k: float
    aerators_per_ha: float
    hp_per_ha: float
    sae: float
    opportunity_cost: float
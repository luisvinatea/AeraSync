# /home/luisvinatea/DEVinatea/Repos/AeraSync/backend/api/core/models.py
"""
Models for aerator comparison.
Contains data structures and type definitions for the aerator comparison system.
"""

from dataclasses import dataclass
from typing import Dict, NamedTuple


@dataclass
class Aerator:
    name: str
    power_hp: float
    sotr: float
    cost: float
    durability: float
    maintenance: float

    # Additional calculated properties
    num_aerators: int = 0
    total_power_hp: float = 0
    total_initial_cost: float = 0
    annual_energy_cost: float = 0
    annual_maintenance_cost: float = 0
    annual_replacement_cost: float = 0
    total_annual_cost: float = 0
    cost_percent_revenue: float = 0
    aerators_per_ha: float = 0
    hp_per_ha: float = 0
    npv_savings: float = 0
    irr: float = 0
    payback_years: float = float("inf")
    roi_percent: float = 0
    sae: float = 0
    cost_per_kg_o2: float = 0
    profitability_k: float = 0
    opportunity_cost: float = 0

    def to_dict(self) -> Dict[str, float | str | int]:
        return {
            "name": self.name,
            "power_hp": self.power_hp,
            "sotr": self.sotr,
            "cost": self.cost,
            "durability": self.durability,
            "maintenance": self.maintenance,
            "num_aerators": self.num_aerators,
            "total_power_hp": self.total_power_hp,
            "total_initial_cost": self.total_initial_cost,
            "annual_energy_cost": self.annual_energy_cost,
            "annual_maintenance_cost": self.annual_maintenance_cost,
            "annual_replacement_cost": self.annual_replacement_cost,
            "total_annual_cost": self.total_annual_cost,
            "cost_percent_revenue": self.cost_percent_revenue,
            "aerators_per_ha": self.aerators_per_ha,
            "hp_per_ha": self.hp_per_ha,
            "npv_savings": self.npv_savings,
            "irr": self.irr,
            "payback_years": self.payback_years,
            "roi_percent": self.roi_percent,
            "sae": self.sae,
            "cost_per_kg_o2": self.cost_per_kg_o2,
            "profitability_k": self.profitability_k,
            "opportunity_cost": self.opportunity_cost,
        }


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
    cost_per_kg_o2: float

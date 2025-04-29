"""aerator_types.py
This module defines the data models
used in the aerator comparison application."""
from typing import List, Dict, Optional
from pydantic import BaseModel, Field

# Model representing an aerator's technical and cost parameters


class Aerator(BaseModel):
    """Model representing an aerator's technical and cost parameters.

    Args:
        BaseModel (_type_): _description_
    """
    name: str
    brand: Optional[str] = None  # Made optional
    type: Optional[str] = None  # Made optional
    power_hp: float
    sotr_kg_o2_h: float
    initial_cost_usd: float
    maintenance_usd_year: float
    durability_years: int

# Financial input parameters for aerator analysis


class FinancialInput(BaseModel):
    """Financial input parameters for aerator analysis.

    Args:
        BaseModel (_type_): _description_
    """
    energy_cost_usd_kwh: float
    operating_hours_year: int
    discount_rate_percent: float
    inflation_rate_percent: float
    analysis_horizon_years: int
    safety_margin_percent: float

# Farm characteristics


class FarmInput(BaseModel):
    """Farm characteristics input parameters.

    Args:
        BaseModel (_type_): _description_
    """
    area_ha: float = Field(ge=0, description="Farm area in hectares. Must be greater than or equal to 0.")

# Oxygen and stock parameters for the farm


class OxygenInput(BaseModel):
    """Oxygen and stock parameters for the farm.

    Args:
        BaseModel (_type_): _description_
    """
    temperature_c: float
    salinity_ppt: float
    shrimp_weight_g: float
    biomass_kg_ha: float

# Resulting metrics for a single aerator


class AeratorResult(BaseModel):
    """Resulting metrics for a single aerator.

    Args:
        BaseModel (_type_): _description_
    """
    name: str
    brand: str
    type: str
    num_aerators: int
    total_power_hp: float
    total_initial_cost: float
    annual_energy_cost: float
    annual_maintenance_cost: float
    npv_cost: float
    aerators_per_ha: float
    hp_per_ha: float

# Collection of comparison results including TOD and winner


class ComparisonResults(BaseModel):
    """Collection of comparison results including TOD and winner.

    Args:
        BaseModel (_type_): _description_
    """
    tod: Dict[str, float]
    aeratorResults: List[AeratorResult]
    winnerLabel: str

# Request model encapsulating all inputs for a comparison


class AeratorComparisonRequest(BaseModel):
    """Request model encapsulating all inputs for a comparison.

    Args:
        BaseModel (_type_): _description_
    """
    aerators: List[Aerator]
    financial: FinancialInput
    farm: FarmInput
    oxygen: OxygenInput

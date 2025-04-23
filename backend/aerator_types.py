"""Type definitions for the AeraSync aerator comparison module."""
from typing import Any, Dict, List, Optional, TypedDict
from pydantic import BaseModel, Field


class AeratorResult(TypedDict):
    """Result of a single aerator in the comparison."""
    name: str
    sae: float
    numAerators: int
    totalAnnualCost: float
    costPercentage: float
    npv: float
    irr: float
    paybackPeriod: float
    roi: float
    profitabilityCoefficient: float


class ComparisonResults(TypedDict):
    """Results of the aerator comparison."""
    tod: float
    shrimpRespiration: float
    pondRespiration: float
    pondWaterRespiration: float
    pondBottomRespiration: float
    annualRevenue: float
    costOfOpportunity: float
    winnerLabel: str
    aeratorResults: List[AeratorResult]
    apiResults: Dict[str, float]


class TODInputs(TypedDict):
    """Input parameters for Total Oxygen Demand (TOD) calculation."""
    total_area: float
    pond_depth: float
    temperature: float
    salinity: float
    biomass_kg_ha: float
    shrimp_weight: float
    safety_margin_percent: Optional[float]


class AeratorComparisonInputs(TypedDict):
    """Input parameters for aerator comparison."""
    total_area: float
    pond_depth: float
    production_kg_ha_year: float
    temperature: float
    salinity: float
    shrimp_weight: float
    biomass_kg_ha: float
    shrimp_price_usd_kg: float
    energy_cost: float
    operating_hours: float
    discount_rate: float
    inflation_rate: float
    horizon: int
    safety_margin_percent: Optional[float]
    aerators: List[Dict[str, Any]]


class FinancialDataDict(TypedDict):
    """Input parameters for financial metrics calculation."""
    initial_investment: float
    annual_savings: float
    cash_flows: List[float]
    discount_rate: float
    inflation_rate: float
    horizon: int


class FarmData(BaseModel):
    """Pydantic model for farm input data."""
    area_ha: float = Field(ge=0)
    production_kg_ha_year: float = Field(ge=0)
    cycles_per_year: float = Field(ge=0)
    pond_depth_m: float = Field(ge=0)


class OxygenData(BaseModel):
    """Pydantic model for oxygen input data."""
    temperature_c: float = Field(ge=-10, le=50)
    salinity_ppt: float = Field(ge=0)
    shrimp_weight_g: float = Field(ge=0)
    biomass_kg_ha: float = Field(ge=0)


class AeratorData(BaseModel):
    """Pydantic model for aerator input data."""
    name: str
    power_hp: float = Field(ge=0)
    sotr_kg_o2_h: float = Field(ge=0)
    initial_cost_usd: float = Field(ge=0)
    durability_years: float = Field(ge=0)
    maintenance_usd_year: float = Field(ge=0)
    brand: Optional[str] = None
    type: Optional[str] = None


class FinancialData(BaseModel):
    """Pydantic model for financial input data."""
    shrimp_price_usd_kg: float = Field(ge=0)
    energy_cost_usd_kwh: float = Field(ge=0)
    operating_hours_year: float = Field(ge=0)
    discount_rate_percent: float = Field(ge=0)
    inflation_rate_percent: float = Field(ge=0)
    analysis_horizon_years: int = Field(ge=1)
    safety_margin_percent: Optional[float] = Field(None, ge=0)
    initial_investment: float
    annual_savings: float
    cash_flows: List[float]
    discount_rate: float
    inflation_rate: float
    horizon: int


class AeratorComparisonRequest(BaseModel):
    """Pydantic model for aerator comparison request."""
    farm: FarmData
    oxygen: OxygenData
    aerators: List[AeratorData]
    financial: FinancialData

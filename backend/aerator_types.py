"""Type definitions for the AeraSync aerator comparison module."""

from typing import Any, Dict, List, Optional, TypedDict


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


class FinancialData(TypedDict):
    """Input parameters for financial metrics calculation."""
    initial_investment: float
    annual_savings: float
    cash_flows: List[float]
    discount_rate: float
    inflation_rate: float
    horizon: int

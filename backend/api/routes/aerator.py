"""
Aerator comparison endpoints for the AeraSync API.
"""

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, Field
from typing import List, Dict, Any

from ..core.aerator_comparer import compare_aerators

router = APIRouter()


class AeratorModel(BaseModel):
    name: str
    power_hp: float
    sotr: float
    cost: float
    durability: float
    maintenance: float


class FarmDetails(BaseModel):
    tod: float = Field(..., description="Total oxygen demand in kg O₂/h")
    farm_area_ha: float = Field(..., description="Farm area in hectares")
    shrimp_price: float = Field(..., description="Shrimp price in USD/kg")
    culture_days: int = Field(..., description="Number of culture days")
    shrimp_density_kg_m3: float = Field(
        ..., description="Shrimp density in kg/m³"
    )
    pond_depth_m: float = Field(..., description="Pond depth in meters")


class FinancialDetails(BaseModel):
    energy_cost: float = Field(..., description="Energy cost in USD/kWh")
    hours_per_night: int = Field(..., description="Operating hours per night")
    discount_rate: float = Field(..., description="Discount rate (decimal)")
    inflation_rate: float = Field(..., description="Inflation rate (decimal)")
    horizon: int = Field(..., description="Analysis horizon in years")
    safety_margin: float = Field(0.0, description="Safety margin (decimal)")
    temperature: float = Field(30.0, description="Water temperature in °C")


class AeratorComparisonRequest(BaseModel):
    farm: FarmDetails
    financial: FinancialDetails
    aerators: List[AeratorModel] = Field(description="List of aerators to compare", min_length=2)


@router.post("/compare")
async def compare_aerators_endpoint(
    data: AeratorComparisonRequest = Body(...),
) -> Dict[str, Any]:
    """Compare aerator options based on the provided survey data."""
    try:
        request_data: Dict[str, Any] = {
            "farm": data.farm.model_dump(),
            "financial": data.financial.model_dump(),
            "aerators": [a.model_dump() for a in data.aerators],
        }
        result = compare_aerators(request_data)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

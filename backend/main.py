"""FastAPI backend for AeraSync Aerator Comparison API."""
import os
from typing import Any, Dict, List, Optional

from aerator_comparer import (
    AeratorComparer,
    SaturationCalculator,
    ShrimpRespirationCalculator,
)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="AeraSync Aerator Comparison API")

# Dynamically compute data file paths
script_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.dirname(script_dir)
data_dir = os.path.join(repo_root, "assets", "data")

oxygen_saturation_path = os.path.join(
    data_dir, "o2_temp_sal_100_sat.json"
)
shrimp_respiration_path = os.path.join(
    data_dir, "shrimp_respiration_salinity_temperature_weight.json"
)

if not os.path.exists(oxygen_saturation_path):
    raise FileNotFoundError(
        f"Oxygen saturation data file not found at: {oxygen_saturation_path}"
    )
if not os.path.exists(shrimp_respiration_path):
    raise FileNotFoundError(
        f"Shrimp respiration data file not found at: {shrimp_respiration_path}"
    )

sat_calc = SaturationCalculator(data_path=oxygen_saturation_path)
resp_calc = ShrimpRespirationCalculator(data_path=shrimp_respiration_path)
comparer = AeratorComparer(
    saturation_calculator=sat_calc, respiration_calculator=resp_calc
)


class FarmData(BaseModel):
    """Pydantic model for farm input data."""
    area_ha: float
    production_kg_ha_year: float
    cycles_per_year: float
    pond_depth_m: float


class OxygenData(BaseModel):
    """Pydantic model for oxygen input data."""
    temperature_c: float
    salinity_ppt: float
    shrimp_weight_g: float
    biomass_kg_ha: float


class AeratorData(BaseModel):
    """Pydantic model for aerator input data."""
    name: str
    power_hp: float
    sotr_kg_o2_h: float
    initial_cost_usd: float
    durability_years: float
    maintenance_usd_year: float
    brand: Optional[str] = None
    type: Optional[str] = None


class FinancialData(BaseModel):
    """Pydantic model for financial input data."""
    shrimp_price_usd_kg: float
    energy_cost_usd_kwh: float
    operating_hours_year: float
    discount_rate_percent: float
    inflation_rate_percent: float
    analysis_horizon_years: int
    safety_margin_percent: Optional[float] = None


class AeratorComparisonRequest(BaseModel):
    """Pydantic model for the aerator comparison request body."""
    farm: FarmData
    oxygen: OxygenData
    aerators: List[AeratorData]
    financial: FinancialData


@app.post("/compare-aerators", response_model=Dict[str, Any])
async def compare_aerators(
    request: AeratorComparisonRequest,
) -> Dict[str, Any]:
    """Compare aerators based on the provided request data."""
    try:
        inputs = request.dict()
        results = comparer.compare_aerators(inputs)
        return results
    except ValueError as ve:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid input: {str(ve)}"
        ) from ve
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error during comparison: {str(e)}"
        ) from e


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

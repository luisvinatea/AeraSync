import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
from aerator_comparer import (
    AeratorComparer,
    SaturationCalculator,
    ShrimpRespirationCalculator,
)

app = FastAPI(title="AeraSync Aerator Comparison API")

# Dynamically compute the path to the data files
script_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.dirname(script_dir)
data_dir = os.path.join(repo_root, "assets", "data")

oxygen_saturation_path = os.path.join(
    data_dir, "oxygen_saturation.json")
shrimp_respiration_path = os.path.join(
    data_dir, "shrimp_respiration_salinity_temperature_weight.json")

if not os.path.exists(oxygen_saturation_path):
    raise FileNotFoundError(
        f"Oxygen saturation data file not found at: {oxygen_saturation_path}")
if not os.path.exists(shrimp_respiration_path):
    raise FileNotFoundError(
        f"Shrimp respiration data file not found at: "
        f"{shrimp_respiration_path}"
    )

sat_calc = SaturationCalculator(data_path=oxygen_saturation_path)
resp_calc = ShrimpRespirationCalculator(data_path=shrimp_respiration_path)
comparer = AeratorComparer(
    saturation_calculator=sat_calc, respiration_calculator=resp_calc)


# Define the request model for input validation
class AeratorComparisonRequest(BaseModel):
    temperature: float
    salinity: float
    total_area: float
    pond_depth: float
    biomass_kg_ha: float
    shrimp_weight: float
    shrimp_density_kg_ha: float
    shrimp_price_usd_kg: float
    cycles_per_year: float  # New field: Number of harvest cycles per year
    power1: float
    power2: float
    sotr1: float
    sotr2: float
    price1: float
    price2: float
    maintenance1: float
    maintenance2: float
    durability1: float
    durability2: float
    energy_cost: float
    operating_hours: float
    discount_rate_pct: float
    inflation_rate_pct: float
    analysis_horizon_years: int
    use_manual_tod: bool = False
    manual_tod_value: float = 0.0
    use_custom_shrimp: bool = False
    custom_shrimp_rate: float = 0.0
    use_custom_water: bool = False
    custom_water_rate: float = 0.0
    use_custom_bottom: bool = False
    custom_bottom_rate: float = 0.0


@app.post("/compare-aerators", response_model=Dict[str, Any])
async def compare_aerators(
    request: AeratorComparisonRequest,
) -> Dict[str, Any]:
    try:
        inputs = request.dict()
        results = comparer.compare_aerators(inputs)
        return results
    except ValueError as ve:
        raise HTTPException(
            status_code=400, detail=f"Invalid input: {str(ve)}")
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error during comparison: {str(e)}")


@app.get("/health")
async def health_check():
    return {"status": "healthy"}

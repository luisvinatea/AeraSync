"""FastAPI backend for AeraSync Aerator Comparison API."""
import os
from typing import Any, Dict
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from aerator_comparer import (
    AeratorComparer,
    SaturationCalculator,
    ShrimpRespirationCalculator,
)
from aerator_types import AeratorComparisonRequest, ComparisonResults

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('app.log')
    ]
)
logger: logging.Logger = logging.getLogger("AeraSyncAPI")

app: FastAPI = FastAPI(title="AeraSync Aerator Comparison API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:*",
        "https://*.github.io"
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"]
)

# Data file paths
script_dir: str = os.path.dirname(os.path.abspath(__file__))
repo_root: str = os.path.dirname(script_dir)
data_dir: str = os.path.join(repo_root, "assets", "data")
oxygen_path: str = os.path.join(data_dir, "o2_temp_sal_100_sat.json")
shrimp_path: str = os.path.join(
    data_dir, "shrimp_respiration_salinity_temperature_weight.json"
)

# Fallback paths for Vercel or other environments
fallback_data_dir: str = os.path.join(script_dir, "..", "..", "assets", "data")
if not os.path.exists(oxygen_path):
    oxygen_path = os.path.join(fallback_data_dir, "o2_temp_sal_100_sat.json")
if not os.path.exists(shrimp_path):
    shrimp_path = os.path.join(
        fallback_data_dir,
        "shrimp_respiration_salinity_temperature_weight.json"
    )

# Validate data files
if not os.path.exists(oxygen_path):
    raise FileNotFoundError(f"Data file not found: {oxygen_path}")
if not os.path.exists(shrimp_path):
    raise FileNotFoundError(f"Data file not found: {shrimp_path}")

sat_calc: SaturationCalculator = SaturationCalculator(data_path=oxygen_path)
resp_calc: ShrimpRespirationCalculator = ShrimpRespirationCalculator(
    data_path=shrimp_path
)
comparer: AeratorComparer = AeratorComparer(
    saturation_calculator=sat_calc, respiration_calculator=resp_calc
)


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    logger.info("Received /health request")
    response: Dict[str, str] = {
        "status": "healthy",
        "message": "Service is running smoothly."
    }
    logger.info("Sent /health response: %s", response)
    return response


@app.post("/compare")
async def compare_aerators(
    request: AeratorComparisonRequest
) -> ComparisonResults:
    """Compare aerators based on the provided request."""
    logger.info("Received /compare request with data: %s", request)
    try:
        if len(request.aerators) < 2:
            raise ValueError("At least two aerators are required")
        inputs: Dict[str, Any] = request.model_dump()
        results: ComparisonResults = comparer.compare_aerators(inputs)
        logger.info("Sent /compare response: %s", results)
        return results
    except ValueError as ve:
        logger.error("Invalid input in /compare: %s", str(ve))
        raise HTTPException(
            status_code=400,
            detail=f"Invalid input: {str(ve)}"
        ) from ve
    except Exception as e:
        logger.error("Error in /compare: %s", str(e))
        raise HTTPException(
            status_code=500,
            detail=f"Error in comparison: {str(e)}"
        ) from e

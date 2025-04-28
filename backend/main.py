"""FastAPI backend for AeraSync Aerator Comparison API."""
import logging
import os
import sys
from typing import Dict

import psycopg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .aerator_comparer import (
    AeratorComparer,
    SaturationCalculator,
    ShrimpRespirationCalculator,
)
from .aerator_types import AeratorComparisonRequest, ComparisonResults

# Ensure the backend directory is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name%s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler("app.log")],
)
logger: logging.Logger = logging.getLogger("AeraSyncAPI")

# Initialize FastAPI app
app: FastAPI = FastAPI(title="AeraSync Aerator Comparison API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:8080",
        "http://localhost:42329",  # Added for Flutter debug port
        "http://localhost:*",
        "https://*.github.io",
    ],
    allow_origin_regex=r'^http://localhost:[0-9]+$',
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
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
        "shrimp_respiration_salinity_temperature_weight.json",
    )

# Validate data files
if not os.path.exists(oxygen_path):
    raise FileNotFoundError(f"Data file not found: {oxygen_path}")
if not os.path.exists(shrimp_path):
    raise FileNotFoundError(f"Data file not found: {shrimp_path}")

# Initialize calculators
sat_calc: SaturationCalculator = SaturationCalculator(data_path=oxygen_path)
resp_calc: ShrimpRespirationCalculator = ShrimpRespirationCalculator(
    data_path=shrimp_path
)

# Initialize database connection with fallback
db_url = os.getenv("DATABASE_URL")
if not db_url:
    logger.warning(
        "DATABASE_URL env var not set, falling back to in-memory "
        "sqlite database"
    )
    db_url = ":memory:"
# Test connection only for PostgreSQL URLs
if db_url and db_url.startswith("postgres"):
    try:
        with psycopg.connect(db_url) as connection:
            with connection.execute("SELECT NOW();") as cursor:
                result = cursor.fetchone()
                logger.info(
                    "Database connection successful. Current time: %s", result
                )
    except psycopg.Error as e:
        logger.error("Failed to connect to PostgreSQL database: %s", e)
        raise ValueError(f"Failed to connect to database: {e}") from e
else:
    logger.info("Using SQLite database: %s", db_url)

# Initialize AeratorComparer with database URL
comparer: AeratorComparer = AeratorComparer(
    saturation_calculator=sat_calc,
    respiration_calculator=resp_calc,
    db_url=db_url,
)


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    logger.info("Received /health request")
    response: Dict[str, str] = {
        "status": "healthy",
        "message": "Service is running smoothly.",
    }
    logger.info("Sent /health response: %s", response)
    return response


def get_comparer() -> AeratorComparer:
    """Dependency provider for AeratorComparer, honoring any test overrides."""
    override = app.dependency_overrides.get(AeratorComparer)
    if override:
        return override()
    return comparer


@app.post("/compare", response_model=None)
async def compare_aerators(
    request: AeratorComparisonRequest,
    comparer_dep: AeratorComparer = Depends(get_comparer)
) -> ComparisonResults:
    """Compare aerators based on the provided request."""
    logger.info("Received /compare request with data: %s", request)
    try:
        if len(request.aerators) < 2:
            raise ValueError("At least two aerators are required")
        results: ComparisonResults = comparer_dep.compare_aerators(request)
        logger.info("Sent /compare response: %s", results)
        # Log comparison to database
        comparer_dep.log_comparison(request.model_dump(), results)
        return results
    except ValueError as ve:
        logger.error("Invalid input in /compare: %s", str(ve))
        raise HTTPException(
            status_code=400, detail=f"Invalid input: {str(ve)}"
        ) from ve
    except Exception as e:
        logger.error("Error in /compare: %s", str(e))
        raise HTTPException(
            status_code=500, detail=f"Error in comparison: {str(e)}"
        ) from e


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
):
    """Override default validation error handler to adjust error types."""
    _ = request  # Explicitly mark 'request' as unused
    errors = exc.errors()
    for err in errors:
        err_type = err.get("type", "")
        if "not_ge" in err_type:
            err["type"] = "greater_than_equal"
    return JSONResponse(status_code=422, content={"detail": errors})

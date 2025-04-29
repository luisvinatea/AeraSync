"""FastAPI backend for AeraSync Aerator Comparison API."""
import logging
import os
# import sys  # F401: Removed unused import
from typing import Dict

# Remove psycopg import
# import psycopg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Correct relative imports assuming main.py is run from the project root
# or the backend directory is added to PYTHONPATH
from .aerator_comparer import (
    AeratorComparer,
)
# Import the concrete implementation
from .sotr_calculator import ShrimpPondCalculator  # Corrected import
from .shrimp_respiration_calculator import ShrimpRespirationCalculator

from .aerator_types import AeratorComparisonRequest, ComparisonResults

# Ensure the backend directory is in sys.path if running main.py directly
# This might not be necessary if using uvicorn from the project root
# sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    # Corrected format string and line length
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
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
        "http://localhost:*",      # Allows any localhost port
        "https://*.github.io",     # Allows GitHub Pages deployment
        # Add your Vercel deployment URL(s) here, e.g.:
        # "https://your-project-name.vercel.app",
    ],
    # Refine regex if needed, or rely on specific origins list
    # allow_origin_regex=r'^http://localhost:[0-9]+$',
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # Allow necessary methods
    allow_headers=["Content-Type"],  # Allow necessary headers
)

# Data file paths - Determine paths relative to main.py's location
script_dir: str = os.path.dirname(os.path.abspath(__file__))
# Assume main.py is in backend/, assets/ is one level up
repo_root: str = os.path.dirname(script_dir)
data_dir: str = os.path.join(repo_root, "assets", "data")

oxygen_path: str = os.path.join(data_dir, "o2_temp_sal_100_sat.json")
shrimp_path: str = os.path.join(
    data_dir, "shrimp_respiration_salinity_temperature_weight.json"
)

# Fallback paths for Vercel or other environments where structure might differ
# Vercel often places the code in /var/task
if not os.path.exists(data_dir):
    logger.warning(
        "Primary data directory not found: %s. Trying fallback.", data_dir
    )  # W1203: Use % formatting
    # Adjust fallback based on expected deployment structure
    # Example: If main.py is in /var/task/backend/
    # Go up one level from backend/
    fallback_repo_root = os.path.join(script_dir, "..")
    fallback_data_dir = os.path.join(fallback_repo_root, "assets", "data")
    if os.path.exists(fallback_data_dir):
        logger.info(
            "Using fallback data directory: %s", fallback_data_dir
        )  # W1203: Use % formatting
        data_dir = fallback_data_dir
        oxygen_path = os.path.join(data_dir, "o2_temp_sal_100_sat.json")
        shrimp_path = os.path.join(
            data_dir, "shrimp_respiration_salinity_temperature_weight.json"
        )
    else:
        logger.error(
            "Fallback data directory also not found: %s", fallback_data_dir
        )  # W1203: Use % formatting
        # Consider raising an error if data files are critical

# Validate data files after determining paths
if not os.path.exists(oxygen_path):
    logger.error(
        "Oxygen data file not found at determined path: %s", oxygen_path
    )  # W1203: Use % formatting
    # Decide how to handle: raise error, use defaults, etc.
    # raise FileNotFoundError(f"Data file not found: {oxygen_path}")
if not os.path.exists(shrimp_path):
    logger.error(
        "Shrimp data file not found at determined path: %s", shrimp_path
    )  # W1203: Use % formatting
    # raise FileNotFoundError(f"Data file not found: {shrimp_path}")


# Initialize calculators - Handle potential FileNotFoundError during init
try:
    # Use the concrete class for instantiation
    # Instantiate the concrete saturation calculator
    sat_calc: ShrimpPondCalculator = (
        ShrimpPondCalculator(
            data_path=oxygen_path
        )
    )
    resp_calc: ShrimpRespirationCalculator = ShrimpRespirationCalculator(
        data_path=shrimp_path
    )
except FileNotFoundError as fnf_error:
    logger.critical(
        "Failed to initialize calculators due to missing data file: %s",
        fnf_error
    )  # W1203: Use % formatting
    # Exit or raise a more specific configuration error
    raise RuntimeError(
        f"Critical data file missing: {fnf_error}"
    ) from fnf_error
except ValueError as val_error:
    logger.critical(
        "Failed to initialize calculators due to invalid data format: %s",
        val_error
    )  # W1203: Use % formatting
    raise RuntimeError(
        f"Invalid data file format: {val_error}"
    ) from val_error


# Initialize database connection - Force SQLite for Vercel
db_url = os.getenv("DATABASE_URL")
# Force SQLite :memory: for Vercel deployment as psycopg is removed
logger.info("Forcing SQLite :memory: database for Vercel deployment.")
db_url = ":memory:"

# Initialize AeratorComparer with the potentially updated db_url
try:
    comparer: AeratorComparer = AeratorComparer(
        saturation_calculator=sat_calc,  # Pass the concrete instance
        respiration_calculator=resp_calc,
        db_url=db_url,  # Will be :memory:
    )
except RuntimeError as init_error:
    logger.critical(
        "Failed to initialize AeratorComparer: %s", init_error
    )  # W1203: Use % formatting
    # Exit or raise a configuration error
    raise RuntimeError(
        f"Failed to initialize AeratorComparer: {init_error}"
    ) from init_error


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    logger.info("Received /health request")
    # Add more checks if needed (e.g., database connectivity)
    response: Dict[str, str] = {
        "status": "healthy",
        "message": "Service is running smoothly.",
    }
    logger.info("Sent /health response: %s", response)
    return response


def get_comparer() -> AeratorComparer:
    """Dependency provider for AeratorComparer."""
    # This allows overriding the comparer instance during testing
    # No need to check app.dependency_overrides here, FastAPI handles it.
    return comparer


# Use response_model for validation
@app.post("/compare", response_model=ComparisonResults)
async def compare_aerators(
    request: AeratorComparisonRequest,
    # Use dependency injection
    comparer_dep: AeratorComparer = Depends(get_comparer)
) -> ComparisonResults:
    """Compare aerators based on the provided request."""
    # Avoid logging full request data by default for privacy/security
    logger.info("Received /compare request")
    try:
        # Basic validation moved to Pydantic model
        # Pydantic handles min_items

        results: ComparisonResults = (
            # type: ignore[attr-defined]
            comparer_dep.compare_aerators(request)
        )
        logger.info(
            "Comparison successful. Winner: %s",
            results.get("winnerLabel", "N/A")
        )

        # Log comparison to database
        try:
            # Logging will now only work with SQLite in this deployment
            comparer_dep.log_comparison(request.model_dump(), results)
            logger.info("Comparison results logged successfully (SQLite).")
        except RuntimeError as log_err:
            # Log the error but don't fail the request
            logger.error("Failed to log comparison results: %s", log_err)

        return results
    except ValueError as ve:
        logger.warning("Invalid input in /compare: %s", str(ve))  # Log warning
        raise HTTPException(
            status_code=400, detail=f"Invalid input: {str(ve)}"
        ) from ve
    # Catch specific runtime errors from calculations
    except RuntimeError as rte:
        logger.error("Runtime error during comparison: %s", str(rte))
        raise HTTPException(
            status_code=500, detail=f"Calculation error: {str(rte)}"
        ) from rte
    except Exception as e:  # Catch unexpected errors
        logger.exception("Unexpected error in /compare")  # Log full traceback
        raise HTTPException(
            status_code=500,
            detail="An unexpected internal server error occurred."
        ) from e


# E302: Added blank line
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    _request: Request, exc: RequestValidationError  # W0613: Unused 'request'
):
    """Custom validation error handler for Pydantic errors."""
    # Log the validation errors for debugging
    logger.warning("Request validation failed: %s", exc.errors())  # W1203
    # You can customize the response format if needed
    # errors = exc.errors()
    # Simplified error response:
    return JSONResponse(
        status_code=422,
        content={"detail": "Validation Error", "errors": exc.errors()},
    )


# Add a simple root endpoint
@app.get("/")
async def read_root():
    """
    Return a welcome message for the root endpoint.
    """  # C0116: Added docstring
    return {"message": "Welcome to the AeraSync API!"}

# Example of running with uvicorn if main.py is executed directly
# (Typically uvicorn is run from the command line)
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="0.0.0.0", port=8000)

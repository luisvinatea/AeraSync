"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .aerator_comparer import compare_aerators

# Initialize FastAPI app
app = FastAPI(title="AeraSync Aerator Comparison API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:8080",  # Local Flutter dev
        "http://localhost:8080",  # Alternative localhost
        "https://aerasync.vercel.app",  # Production URL
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"]
)


@app.get("/health")
async def health_check():
    """
    Health check endpoint to verify service status.
    """
    return {
        "status": "healthy",
        "message": "Service is running smoothly"
    }


@app.post("/compare")
async def compare_aerators_endpoint(request: dict):
    """
    Compare aerators based on provided JSON input.
    Expects TOD, farm area, financial parameters, and list of aerators.
    """
    try:
        result = compare_aerators(request)
        return result
    except ValueError as e:
        return {"error": f"Invalid input data: {str(e)}"}
    except KeyError as e:
        return {"error": f"Missing required field: {str(e)}"}
    except TypeError as e:
        return {"error": f"Type error in input data: {str(e)}"}


@app.get("/")
async def read_root():
    """
    Root endpoint with a welcome message.
    """
    return {"message": "Welcome to the AeraSync API!"}

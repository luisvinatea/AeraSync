"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""
import os
import json
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .aerator_comparer import compare_aerators

# Initialize FastAPI app
app = FastAPI(title="AeraSync Aerator Comparison API")

# Get CORS origins from environment or use default list
cors_origins = os.environ.get("CORS_ORIGINS", "").split(",")
if not cors_origins or cors_origins == [""]:
    cors_origins = [
        "http://127.0.0.1:8080",  # Local Flutter dev
        "http://localhost:8080",  # Alternative localhost
        "https://aerasync-web.vercel.app",  # Production URL
    ]

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
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


@app.api_route("/{path_name:path}", methods=["GET", "POST"])
async def catch_all(request: Request, path_name: str):
    """
    Catch-all endpoint to handle Vercel routing with query parameters.
    This enables support for both /health and /api/health style routes.
    """
    endpoint = request.query_params.get("endpoint")

    if endpoint == "health" or path_name == "api/health":
        return await health_check()
    elif (
        (endpoint == "compare" or path_name == "api/compare") and
        request.method == "POST"
    ):
        try:
            body = await request.json()
            # Call the comparison endpoint logic directly
            return await compare_aerators_endpoint(body)
        except json.JSONDecodeError as e:
            # Return a 400 Bad Request status code for JSON errors
            return {"error": f"Failed to parse JSON body: {str(e)}"}, 400
        # Let FastAPI handle other potential errors
        # for a 500 Internal Server Error
        # or add more specific exception handling if needed.
    elif path_name == "api":
        return await read_root()
    else:
        # Return a 404 Not Found status code
        return {"error": f"Endpoint not found: /{path_name}"}, 404

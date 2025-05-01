"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""
import os
import json
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
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
        "https://aerasync-web-devinatea.vercel.app",  # Development URL
    ]

# Configure CORS with appropriate preflight handling
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],  # Added OPTIONS for preflight
    allow_headers=["Content-Type"],
    max_age=86400  # Cache preflight responses for 24 hours
)


@app.options("/{path:path}")
async def options_handler(request: Request, _: str):
    """
    Handle OPTIONS preflight requests with proper CORS headers.
    """
    return JSONResponse(
        content={},
        headers={
            "Access-Control-Allow-Origin": request.headers.get("Origin", "*"),
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "86400",
        },
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
async def compare_aerators_endpoint(request: Request):
    """
    Compare aerators based on provided JSON input.
    Expects TOD, farm area, financial parameters, and list of aerators.
    """
    try:
        # Parse the request body
        body = await request.json()
        result = compare_aerators(body)
        return result
    except json.JSONDecodeError as e:
        return {"error": f"Failed to parse JSON body: {str(e)}"}
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
    elif ((endpoint == "compare" or path_name == "api/compare") and
            request.method == "POST"):
        try:
            # Call the comparison endpoint logic directly
            return await compare_aerators_endpoint(request)
        except json.JSONDecodeError as e:
            # Return a JSON response with a 400
            # Bad Request status code for JSON errors
            return JSONResponse(
                content={"error": f"Failed to parse JSON body: {str(e)}"},
                status_code=400
            )
    elif path_name == "api":
        return await read_root()
    else:
        # Return a JSON response with a 404 Not Found status code
        return JSONResponse(
            content={"error": f"Endpoint not found: /{path_name}"},
            status_code=404
        )

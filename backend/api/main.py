"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""

import os
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
        "http://127.0.0.1:*",  # Cover any local port
        "http://localhost:*",  # Cover any local port
        "https://aerasync-web.vercel.app",  # Production URL
        "https://aerasync-web-devinatea.vercel.app",  # Development URL
    ]

# Configure CORS with appropriate preflight handling
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins temporarily for debugging
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],  # Allow all headers for debugging
    max_age=86400,  # Cache preflight responses for 24 hours
)


@app.options("/{path:path}")
async def options_handler(request: Request, path: str):
    """Handle OPTIONS requests for CORS preflight."""
    return JSONResponse(content={}, status_code=200)


@app.get("/health")
async def health_check():
    """Health check endpoint to verify API is running."""
    return {"status": "healthy", "version": "1.0.0"}


@app.post("/compare")
async def compare(request: Request):
    """Compare aerators based on provided parameters and return results."""
    try:
        data = await request.json()
        results = compare_aerators(data)
        return results
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "AeraSync Aerator Comparison API",
        "version": "1.0.0",
        "docs_url": "/docs",
        "redoc_url": "/redoc",
    }


@app.api_route("/{path_name:path}", methods=["GET", "POST"])
async def catch_all(request: Request, path_name: str):
    """Catch-all route for unhandled endpoints."""
    return JSONResponse(
        content={
            "error": f"Endpoint '/{path_name}' not found",
            "available_endpoints": ["/", "/health", "/compare"],
        },
        status_code=404,
    )

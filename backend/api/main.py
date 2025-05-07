"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""

import os
from fastapi import FastAPI, Request, Body, HTTPException  # type: ignore  # noqa: F401
from fastapi.middleware.cors import CORSMiddleware  # type: ignore # noqa: F401
from fastapi.responses import JSONResponse  # type: ignore # noqa: F401
from typing import Dict, Any, List  # type: ignore # noqa: F401
from pydantic import BaseModel, Field  # type: ignore # noqa: F401

# Import routes
from .routes.health import router as health_router
from .routes.aerator import router as aerator_router
from .routes.root import router as root_router
from .core.aerator_comparer import compare_aerators

# Initialize FastAPI app
app = FastAPI(title="AeraSync Aerator Comparison API", version="1.0.0")

# Get CORS origins from environment or use default list
cors_origins = os.environ.get("CORS_ORIGINS", "").split(",")
if not cors_origins or cors_origins == [""]:
    cors_origins = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:5000",
        "http://localhost:37235/",
        "https://aerasync.vercel.app",
        "https://aerasync-mobile.vercel.app",
        "https://aerasync-web-git-v3-devinatea.vercel.app",
        "https://aerasync-web.vercel.app",
    ]

# Configure CORS with appropriate preflight handling
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Direct health check endpoint for Vercel
@app.get("/health")
async def direct_health_check():
    """Direct health check endpoint for Vercel deployments."""
    return {"status": "ok", "message": "API is healthy"}


# Direct compare endpoint for Vercel
@app.post("/compare")
async def direct_compare_endpoint(data: Dict[str, Any] = Body(...)):
    """Direct compare endpoint for Vercel deployments."""
    try:
        result = compare_aerators(data)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# Include routers
app.include_router(root_router)
app.include_router(health_router)
app.include_router(aerator_router)

# /home/luisvinatea/DEVinatea/Repos/AeraSync/backend/api/main.py
"""
FastAPI backend for AeraSync Aerator Comparison API.
Handles incoming requests for aerator comparisons and health checks.
"""

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import routes
from .routes.health import router as health_router
from .routes.aerator import router as aerator_router
from .routes.root import router as root_router

# Initialize FastAPI app
app = FastAPI(title="AeraSync Aerator Comparison API", version="1.0.0")

# Get CORS origins from environment or use default list
cors_origins = os.environ.get("CORS_ORIGINS", "").split(",")
if not cors_origins or cors_origins == [""]:
    cors_origins = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5000",
        "https://aerasync.vercel.app",
        "https://aerasync-mobile.vercel.app",
    ]

# Configure CORS with appropriate preflight handling
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(root_router)
app.include_router(health_router)
app.include_router(aerator_router)

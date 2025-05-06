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

# Include all routes
app.include_router(health_router)
app.include_router(aerator_router)
app.include_router(root_router)

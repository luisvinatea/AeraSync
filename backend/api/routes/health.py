"""
Health check endpoints for the AeraSync API.
"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """Health check endpoint to verify API is running."""
    return {"status": "healthy", "message": "Service is running smoothly"}


@router.get("/api/health")
async def api_health_check():
    """Health check endpoint with /api prefix."""
    return {"status": "healthy", "message": "Service is running smoothly"}

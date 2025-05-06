# /home/luisvinatea/DEVinatea/Repos/AeraSync/backend/api/routes/root.py
"""
Root and catch-all endpoints for the AeraSync API.
"""

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

router = APIRouter()


@router.get("/")
async def root():
    """Root endpoint with API information."""
    return {"message": "Welcome to the AeraSync API!"}


@router.options("/{path:path}")
async def options_handler(request: Request, path: str):
    """Handle OPTIONS requests for CORS preflight."""
    return JSONResponse(content={}, status_code=200)


@router.api_route("/{path_name:path}", methods=["GET", "POST"])
async def catch_all(request: Request, path_name: str):
    """Catch-all route for unhandled endpoints."""
    return JSONResponse(
        content={
            "error": "Endpoint not found",
            "path": f"/{path_name}",
            "available_endpoints": ["/", "/health", "/compare"],
        },
        status_code=404,
    )

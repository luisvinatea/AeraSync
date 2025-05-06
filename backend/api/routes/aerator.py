"""
Aerator comparison endpoints for the AeraSync API.
"""

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from ..core.aerator_comparer import compare_aerators

router = APIRouter()


@router.post("/compare")
async def compare(request: Request):
    """Compare aerators based on provided parameters and return results."""
    try:
        try:
            data = await request.json()
        except Exception:
            return JSONResponse(
                content={"error": "Failed to parse JSON body"}, status_code=200
            )
        results = compare_aerators(data)
        return results
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=200)


@router.post("/api/compare")
async def api_compare(request: Request):
    """Compare aerators endpoint with /api prefix."""
    try:
        try:
            data = await request.json()
        except Exception:
            return JSONResponse(
                content={"error": "Failed to parse JSON body"}, status_code=200
            )
        results = compare_aerators(data)
        return results
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=200)

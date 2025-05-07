# /home/luisvinatea/DEVinatea/Repos/AeraSync/backend/api/routes/root.py
"""
Root and catch-all endpoints for the AeraSync API.
"""

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, JSONResponse

router = APIRouter()


@router.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Root endpoint to check if the server is running."""
    return HTMLResponse(
        content="""
        <html>
            <head>
                <title>AeraSync API</title>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
                    h1 { color: #1e40af; }
                    pre { background: #f5f5f5; padding: 15px; border-radius: 5px; }
                    .endpoint { margin-bottom: 20px; }
                    .method { font-weight: bold; color: #1e3a8a; }
                </style>
            </head>
            <body>
                <h1>AeraSync API</h1>
                <p>This is the AeraSync API for aerator comparisons. Below are the available endpoints:</p>
                
                <div class="endpoint">
                    <p><span class="method">GET</span> /health - Check if API is running</p>
                </div>
                
                <div class="endpoint">
                    <p><span class="method">POST</span> /compare - Compare aerators with the provided data</p>
                    <pre>
{
  "farm": {
    "tod": 5440,
    "farm_area_ha": 1000,
    "shrimp_price": 5.0,
    "culture_days": 120,
    "shrimp_density_kg_m3": 0.33,
    "pond_depth_m": 1.0
  },
  "financial": {
    "energy_cost": 0.05,
    "hours_per_night": 8,
    "discount_rate": 0.10,
    "inflation_rate": 0.03,
    "horizon": 9,
    "safety_margin": 0,
    "temperature": 31.5
  },
  "aerators": [
    {
      "name": "Paddlewheel 1",
      "power_hp": 3.0,
      "sotr": 1.4,
      "cost": 500,
      "durability": 2,
      "maintenance": 65
    },
    {
      "name": "Paddlewheel 2",
      "power_hp": 3.0,
      "sotr": 2.6,
      "cost": 800,
      "durability": 4.5,
      "maintenance": 50
    }
  ]
}
                    </pre>
                </div>
            </body>
        </html>
        """,
        status_code=200,
    )


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

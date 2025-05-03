API Main Module
=============

.. automodule:: api.main
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The main module serves as the FastAPI backend for the AeraSync Aerator Comparison API.
It handles incoming requests for aerator comparisons and health checks, with CORS support
and error handling.

API Endpoints
------------

- **GET /health**: Health check endpoint to verify service status
- **POST /compare**: Main endpoint for comparing aerators based on provided JSON input
- **GET /**: Root endpoint with a welcome message
- **Catch-all handler**: Supports both direct and Vercel-style routes (/api/*)

Example Request
--------------

.. code-block:: python

   import requests
   import json

   url = "https://aerasync-api.vercel.app/compare"
   
   data = {
       'farm': {
           'tod': 5443.76,
           'farm_area_ha': 1000,
           'shrimp_price': 5.0,
           'culture_days': 120,
           'shrimp_density_kg_m3': 0.3333333,
           'pond_depth_m': 1.0
       },
       'financial': {
           'energy_cost': 0.05,
           'hours_per_night': 8,
           'discount_rate': 0.1,
           'inflation_rate': 0.025,
           'horizon': 9,
           'safety_margin': 0,
           'temperature': 31.5
       },
       'aerators': [
           {
               'name': 'Aerator 1',
               'sotr': 1.4,
               'power_hp': 3,
               'cost': 500,
               'durability': 4.5,
               'maintenance': 65
           },
           {
               'name': 'Aerator 2',
               'sotr': 2.2,
               'power_hp': 3,
               'cost': 800,
               'durability': 4.5,
               'maintenance': 50
           }
       ]
   }
   
   response = requests.post(url, json=data)
   result = response.json()
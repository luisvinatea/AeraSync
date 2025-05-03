API Reference
============

This page documents the REST API exposed by the AeraSync backend.

Endpoints
--------

Health Check
~~~~~~~~~~~

**GET /health**

Checks if the API service is up and running.

Example response:

.. code-block:: json

   {
     "status": "healthy",
     "message": "Service is running smoothly"
   }

Aerator Comparison
~~~~~~~~~~~~~~~~

**POST /compare**

Compare aerators based on specifications, farm parameters, and financial inputs.

Request body:

.. code-block:: json

   {
     "farm": {
       "tod": 5443.76,
       "farm_area_ha": 1000,
       "shrimp_price": 5.0,
       "culture_days": 120,
       "shrimp_density_kg_m3": 0.3333333,
       "pond_depth_m": 1.0
     },
     "financial": {
       "energy_cost": 0.05,
       "hours_per_night": 8,
       "discount_rate": 0.1,
       "inflation_rate": 0.025,
       "horizon": 9,
       "safety_margin": 0,
       "temperature": 31.5
     },
     "aerators": [
       {
         "name": "Aerator 1",
         "sotr": 1.4,
         "power_hp": 3,
         "cost": 500,
         "durability": 4.5,
         "maintenance": 65
       },
       {
         "name": "Aerator 2",
         "sotr": 2.2,
         "power_hp": 3,
         "cost": 800,
         "durability": 4.5,
         "maintenance": 50
       }
     ]
   }

Response body:

.. code-block:: json

   {
     "tod": 5443.76,
     "annual_revenue": 500000.00,
     "aeratorResults": [
       {
         "name": "Aerator 1",
         "num_aerators": 3884,
         "total_power_hp": 11652.00,
         "total_initial_cost": 1942000.00,
         "annual_energy_cost": 348086.50,
         "annual_maintenance_cost": 252460.00,
         "annual_replacement_cost": 431555.56,
         "total_annual_cost": 1032102.06,
         "cost_percent_revenue": 0.21,
         "npv_savings": 468423.89,
         "payback_years": 4.15,
         "roi_percent": 24.12,
         "irr": 18.94,
         "profitability_k": 1.09,
         "aerators_per_ha": 3.88,
         "hp_per_ha": 11.65,
         "sae": 0.63,
         "opportunity_cost": 0.00
       },
       {
         "name": "Aerator 2",
         "num_aerators": 2475,
         "total_power_hp": 7425.00,
         "total_initial_cost": 1980000.00,
         "annual_energy_cost": 221827.05,
         "annual_maintenance_cost": 123750.00,
         "annual_replacement_cost": 440000.00,
         "total_annual_cost": 785577.05,
         "cost_percent_revenue": 0.16,
         "npv_savings": 0.00,
         "payback_years": 0.00,
         "roi_percent": 0.00,
         "irr": 0.00,
         "profitability_k": 0.00,
         "aerators_per_ha": 2.48,
         "hp_per_ha": 7.43,
         "sae": 0.98,
         "opportunity_cost": 468423.89
       }
     ],
     "winnerLabel": "Aerator 2",
     "equilibriumPrices": {
       "Aerator 1": 624.70
     }
   }

Error Response:

.. code-block:: json

   {
     "error": "Invalid numeric value for aerator specifications"
   }

Status Codes:

- 200 OK: Successful comparison
- 400 Bad Request: Invalid input data
- 500 Internal Server Error: Server error
Aerator Comparer Module
======================

.. automodule:: api.aerator_comparer
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The aerator_comparer module compares aerators for shrimp farming based on specs
and financial metrics. It calculates OTR_T from SOTR, includes revenue from
shrimp production, and focuses on savings and opportunity cost for financial indicators.

Key Components
-------------

- **Data Structures**: Uses namedtuples for structured data handling (Aerator, FinancialInput, FarmInput, AeratorResult)
- **Financial Calculations**: NPV, IRR, ROI, payback period calculations
- **Aerator Comparison**: Compares aerators based on cost, efficiency, and performance

Example Usage
------------

.. code-block:: python

   from api.aerator_comparer import compare_aerators
   
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
   
   result = compare_aerators(data)
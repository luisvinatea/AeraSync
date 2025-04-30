Aerator Comparer Module
======================

Overview
--------

The ``aerator_comparer`` module provides functionality to compare aerators for shrimp pond aeration, calculating oxygen demand, annual costs, and financial metrics such as NPV, IRR, and payback period. It integrates with oxygen saturation and shrimp respiration calculators and logs results to a SQLite database.

Module Structure
----------------

- **backend/aerator_comparer.py**: Main class ``AeratorComparer`` for orchestrating aerator comparison.
- **backend/aerator_calculations.py**: Calculation functions for oxygen demand and financial metrics.
- **backend/aerator_types.py**: Type definitions (TypedDict) for inputs and results.
- **docs/aerator_comparer.rst**: This documentation file.

Type Definitions
----------------

Defined in ``backend/aerator_types.py``:

- **AeratorResult**: Represents a single aerator's results, including SAE, number of aerators, costs, and financial metrics.
- **ComparisonResults**: Aggregates TOD, respiration demands, revenue, cost of opportunity, and aerator results.
- **TODInputs**: Inputs for Total Oxygen Demand calculation (area, depth, temperature, etc.).
- **AeratorComparisonInputs**: Inputs for aerator comparison (farm, oxygen, financial, and aerator data).
- **FinancialData**: Inputs for financial metrics (investment, savings, cash flows, etc.).

Class: AeratorComparer
---------------------

**Description**: Compares aerators based on oxygen demand and financial performance.

**Constructor**:

.. code-block:: python

    AeratorComparer(saturation_calculator, respiration_calculator, db_path="aerasync.db")

**Parameters**:
- ``saturation_calculator``: Calculator for oxygen saturation.
- ``respiration_calculator``: Calculator for shrimp respiration.
- ``db_path``: Path to SQLite database.

**Methods**:

- **compare_aerators(inputs)**: Main method to compare aerators.
- **log_comparison(inputs, results)**: Logs comparison results to the database.
- **_extract_inputs(inputs)**: Extracts and validates input parameters.
- **_validate_inputs(inputs)**: Validates input parameters.
- **_process_aerators(inputs, total_demand_kg_h, annual_revenue)**: Processes each aerator.
- **_calculate_financial_metrics(aerator_results, annual_costs, inputs)**: Calculates financial metrics.

Calculation Functions
--------------------

Defined in ``backend/aerator_calculations.py``:

- **calculate_otrt**: Calculates Oxygen Transfer Rate at temperature T.
- **calculate_shrimp_demand**: Calculates shrimp oxygen demand in kg O₂/h/ha.
- **calculate_water_demand**: Calculates water oxygen demand in kg O₂/h/ha.
- **calculate_bottom_demand**: Calculates bottom oxygen demand in kg O₂/h/ha.
- **calculate_tod**: Calculates Total Oxygen Demand in kg O₂/h.
- **calculate_annual_revenue**: Calculates annual revenue in USD.
- **calculate_npv**: Calculates Net Present Value with growing annuity.
- **calculate_irr**: Calculates Internal Rate of Return using numerical methods.
- **compute_financial_metrics**: Computes NPV, IRR, payback period, ROI, and profitability coefficient.
- **compute_equilibrium_price**: Computes equilibrium price for the winning aerator.

Usage Example
-------------

.. code-block:: python

    from aerator_comparer import AeratorComparer
    from sotr_calculator import ShrimpPondCalculator
    from shrimp_respiration_calculator import ShrimpRespirationCalculator

    sat_calc = ShrimpPondCalculator()
    resp_calc = ShrimpRespirationCalculator()
    comparer = AeratorComparer(sat_calc, resp_calc)
    inputs = {...}  # Input dictionary
    results = comparer.compare_aerators(inputs)
    print(results)

Dependencies
------------

- ``scipy.optimize.newton``: For IRR calculation.
- ``sqlite3``: For database logging.
- ``json``: For serializing inputs and results.
- ``shrimp_respiration_calculator``: For respiration rate calculations.
- ``sotr_calculator``: For oxygen saturation calculations.

Error Handling
--------------

The module raises:
- ``ValueError``: For invalid input parameters (e.g., negative values).
- ``TypeError``: For incorrect input types.
- ``RuntimeError``: For calculation or database errors.

Testing
-------

Tests are defined in ``backend/test.py``:
- ``test_compare_aerators_valid``: Verifies successful comparison (status 200).
- ``test_compare_aerators_invalid``: Verifies error handling (status 422).

Run tests with:

.. code-block:: bash

    python backend/test.py
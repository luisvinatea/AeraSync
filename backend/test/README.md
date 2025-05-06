# AeraSync Backend Tests

This directory contains unit tests for the AeraSync backend API and calculation functions.

## Test Coverage

The tests cover:

1. **Calculation Functions**
   - Standard Aeration Efficiency (SAE)
   - Net Present Value (NPV)
   - Internal Rate of Return (IRR)
   - Payback Period
   - Return on Investment (ROI)
   - Profitability Index
   - Equilibrium Price

2. **Aerator Comparison Logic**
   - Processing individual aerators
   - Comparing multiple aerators
   - Handling edge cases (zero values, invalid inputs)

3. **API Endpoints**
   - Health check endpoint
   - Root endpoint
   - Compare aerators endpoint
     - Valid input validation
     - Invalid input handling
     - Missing field detection

## Running Tests

You can run the tests using either pytest or unittest:

### Using pytest

```bash
cd backend
pytest test/test_aerator_comparer.py -v
```

### Using unittest

```bash
cd backend
python -m unittest test/test_aerator_comparer.py
```

## Adding New Tests

When adding new functionality to the backend, please add corresponding test cases following these guidelines:

1. Place tests in the appropriate test class based on what's being tested
2. Include tests for normal operation and edge cases
3. Add docstrings explaining what each test is verifying
4. Use descriptive test method names that explain the test's purpose

"""Unit tests for the AeraSync API."""

import os
import subprocess
import sys
import warnings
import sqlite3
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient
from .main import app
from .aerator_comparer import AeratorComparer
from .sotr_calculator import SaturationCalculator
from .shrimp_respiration_calculator import ShrimpRespirationCalculator

# Suppress warnings aggressively
warnings.filterwarnings("ignore", category=Warning, module=".*")

# Test client for FastAPI app
client: TestClient = TestClient(app)

# Fixtures for testing


@pytest.fixture
def mock_saturation_calculator():
    """Fixture for a mocked SaturationCalculator."""
    mock = MagicMock(spec=SaturationCalculator)
    mock.get_o2_saturation.return_value = 8.0  # Example value
    return mock


@pytest.fixture
def mock_respiration_calculator():
    """Fixture for a mocked RespirationCalculator."""
    mock = MagicMock(spec=ShrimpRespirationCalculator)
    mock.get_respiration_rate.return_value = 300.0  # Example value mg O2/kg/h
    return mock


@pytest.fixture
def test_db_url():
    """Fixture for an in-memory SQLite database URL for testing."""
    return "file::memory:?cache=shared"  # Use shared memory


@pytest.fixture
def aerator_comparer(
    mock_saturation_calculator, mock_respiration_calculator, test_db_url
):
    """Fixture for an AeratorComparer instance with mocked dependencies."""
    comparer = AeratorComparer(
        saturation_calculator=mock_saturation_calculator,
        respiration_calculator=mock_respiration_calculator,
        db_url=test_db_url,
    )
    return comparer


class TestAeraSyncAPI:
    """Test suite for AeraSync API endpoints."""

    def test_health_endpoint(self):
        """Test the health endpoint returns status 200 and correct response."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}

    def test_compare_aerators_valid(self, aerator_comparer: AeratorComparer):
        """Test the compare endpoint with valid input."""
        valid_input = {
            "farm": {
                "area_ha": 10.0,
                "production_kg_ha_year": 5000.0,
                "cycles_per_year": 2.0,
                "pond_depth_m": 1.5,
            },
            "oxygen": {
                "temperature_c": 25.0,
                "salinity_ppt": 30.0,
                "shrimp_weight_g": 20.0,
                "biomass_kg_ha": 4000.0,
            },
            "aerators": [
                {
                    "name": "Aerator1",
                    "power_hp": 2.0,
                    "sotr_kg_o2_h": 1.5,
                    "initial_cost_usd": 1000.0,
                    "durability_years": 5,
                    "maintenance_usd_year": 200.0,
                    "brand": "BrandA",
                    "type": "TypeX",
                },
                {
                    "name": "Aerator2",
                    "power_hp": 3.0,
                    "sotr_kg_o2_h": 2.0,
                    "initial_cost_usd": 1500.0,
                    "durability_years": 6,
                    "maintenance_usd_year": 300.0,
                    "brand": "BrandB",
                    "type": "TypeY",
                },
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 0.0,
            },
        }
        response = client.post("/compare", json=valid_input)
        assert response.status_code == 200
        response_data = response.json()
        assert "tod" in response_data
        assert "aeratorResults" in response_data
        assert len(response_data["aeratorResults"]) == 2
        assert response_data["winnerLabel"] in ["Aerator1", "Aerator2"]

        try:
            with sqlite3.connect(
                aerator_comparer.db_url, uri=True, check_same_thread=False
            ) as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM aerator_comparisons")
                count = cursor.fetchone()[0]
                assert count >= 1
        except sqlite3.Error as e:
            pytest.fail(f"Database verification failed: {e}")

    def test_compare_aerators_invalid(self):
        """Test the compare endpoint with invalid input."""
        invalid_input = {
            "farm": {
                "area_ha": -10.0,
                "production_kg_ha_year": 5000.0,
                "cycles_per_year": 2.0,
                "pond_depth_m": 1.5,
            },
            "oxygen": {
                "temperature_c": 25.0,
                "salinity_ppt": 30.0,
                "shrimp_weight_g": 20.0,
                "biomass_kg_ha": 4000.0,
            },
            "aerators": [
                {
                    "name": "Aerator1",
                    "power_hp": 2.0,
                    "sotr_kg_o2_h": 1.5,
                    "initial_cost_usd": 1000.0,
                    "durability_years": 5,
                    "maintenance_usd_year": 200.0,
                    "brand": "BrandA",
                    "type": "TypeX",
                },
                {
                    "name": "Aerator2",
                    "power_hp": 3.0,
                    "sotr_kg_o2_h": 2.0,
                    "initial_cost_usd": 1500.0,
                    "durability_years": 6,
                    "maintenance_usd_year": 300.0,
                    "brand": "BrandB",
                    "type": "TypeY",
                },
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 0.0,
            },
        }
        response = client.post("/compare", json=invalid_input)
        assert response.status_code == 422
        errors = response.json().get("detail", [])
        assert isinstance(errors, list)
        assert len(errors) > 0
        area_error = next(
            (e for e in errors if e.get("loc") == ["body", "farm", "area_ha"]),
            None,
        )
        assert area_error is not None
        assert "greater than or equal to 0" in area_error.get("msg", "").lower()

    def test_compare_aerators_single_aerator(self):
        """Test the compare endpoint with only one aerator."""
        single_aerator_input = {
            "farm": {
                "area_ha": 10.0,
                "production_kg_ha_year": 5000.0,
                "cycles_per_year": 2.0,
                "pond_depth_m": 1.5,
            },
            "oxygen": {
                "temperature_c": 25.0,
                "salinity_ppt": 30.0,
                "shrimp_weight_g": 20.0,
                "biomass_kg_ha": 4000.0,
            },
            "aerators": [
                {
                    "name": "Aerator1",
                    "power_hp": 2.0,
                    "sotr_kg_o2_h": 1.5,
                    "initial_cost_usd": 1000.0,
                    "durability_years": 5,
                    "maintenance_usd_year": 200.0,
                    "brand": "BrandA",
                    "type": "TypeX",
                }
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 0.0,
            },
        }
        response = client.post("/compare", json=single_aerator_input)
        assert response.status_code == 400
        assert "at least two aerators are required" in response.json().get(
            "detail", ""
        ).lower()

    def test_health_endpoint_multiple_requests(self):
        """Test the health endpoint with multiple requests."""
        for _ in range(3):
            response = client.get("/health")
            assert response.status_code == 200
            assert response.json() == {"status": "healthy"}


if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env = os.environ.copy()
    python_path = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = f"{project_root}{os.pathsep}{python_path}"

    try:
        result = subprocess.run(
            [sys.executable, "-m", "pytest", "-v", __file__],
            check=True,
            capture_output=True,
            text=True,
            cwd=project_root,
            env=env,
        )
        print(result.stdout)
        sys.exit(result.returncode)
    except subprocess.CalledProcessError as e:
        print("Pytest execution failed:")
        print(e.stdout)
        print(e.stderr)
        sys.exit(e.returncode)
    except FileNotFoundError:
        print(f"Error: '{sys.executable} -m pytest' command not found.")
        print("Ensure pytest is installed in the Python environment.")
        sys.exit(1)

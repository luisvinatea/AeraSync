"""Unit tests for the AeraSync API."""

# type: ignore
import subprocess
import sys
import warnings
from typing import List, Optional
from typing_extensions import TypedDict
from fastapi.testclient import TestClient
from .main import app

# Suppress warnings aggressively
warnings.filterwarnings("ignore", category=Warning, module=".*")

client = TestClient(app)


class TestAeraSyncAPI:
    """Test suite for AeraSync API endpoints."""

    def test_health_endpoint(self):
        """Test the health endpoint returns status 200 and correct response."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {
            "status": "healthy",
            "message": "Service is running smoothly.",
        }

    def test_compare_aerators_valid(self):
        """Test the compare endpoint with valid input."""

        class FarmInput(TypedDict):
            """Farm input parameters."""

            area_ha: float
            production_kg_ha_year: float
            cycles_per_year: float
            pond_depth_m: float

        class OxygenInput(TypedDict):
            """Oxygen input parameters."""

            temperature_c: float
            salinity_ppt: float
            shrimp_weight_g: float
            biomass_kg_ha: float

        class AeratorInput(TypedDict):
            """Aerator input parameters."""

            name: str
            power_hp: float
            sotr_kg_o2_h: float
            initial_cost_usd: float
            durability_years: float
            maintenance_usd_year: float
            brand: Optional[str]
            type: Optional[str]

        class FinancialInput(TypedDict):
            """Financial input parameters."""

            shrimp_price_usd_kg: float
            energy_cost_usd_kwh: float
            operating_hours_year: float
            discount_rate_percent: float
            inflation_rate_percent: float
            analysis_horizon_years: int
            safety_margin_percent: float

        class ValidInput(TypedDict):
            """Valid input parameters."""

            farm: FarmInput
            oxygen: OxygenInput
            aerators: List[AeratorInput]
            financial: FinancialInput

        valid_input: ValidInput = {
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
                    "durability_years": 5.0,
                    "maintenance_usd_year": 200.0,
                    "brand": "Pentair",
                    "type": "Paddle",
                },
                {
                    "name": "Aerator2",
                    "power_hp": 3.0,
                    "sotr_kg_o2_h": 2.0,
                    "initial_cost_usd": 1500.0,
                    "durability_years": 6.0,
                    "maintenance_usd_year": 300.0,
                    "brand": "Beraqua",
                    "type": "Paddle",
                },
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000.0,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 10.0,
            },
        }
        response = client.post("/compare", json=valid_input)
        assert response.status_code == 200
        response_data = response.json()
        assert "tod" in response_data
        assert "aeratorResults" in response_data
        assert len(response_data["aeratorResults"]) == 2
        assert response_data["winnerLabel"] in ["Aerator1", "Aerator2"]

    def test_compare_aerators_invalid(self):
        """Test the compare endpoint with invalid input."""

        class FarmInput(TypedDict):
            """Farm input parameters."""

            area_ha: float
            production_kg_ha_year: float
            cycles_per_year: float
            pond_depth_m: float

        class OxygenInput(TypedDict):
            """Oxygen input parameters."""

            temperature_c: float
            salinity_ppt: float
            shrimp_weight_g: float
            biomass_kg_ha: float

        class AeratorInput(TypedDict):
            """Aerator input parameters."""

            name: str
            power_hp: float
            sotr_kg_o2_h: float
            initial_cost_usd: float
            durability_years: float
            maintenance_usd_year: float
            brand: Optional[str]
            type: Optional[str]

        class FinancialInput(TypedDict):
            """Financial input parameters."""

            shrimp_price_usd_kg: float
            energy_cost_usd_kwh: float
            operating_hours_year: float
            discount_rate_percent: float
            inflation_rate_percent: float
            analysis_horizon_years: int
            safety_margin_percent: float

        class InvalidInput(TypedDict):
            """Invalid input parameters."""

            farm: FarmInput
            oxygen: OxygenInput
            aerators: List[AeratorInput]
            financial: FinancialInput

        invalid_input: InvalidInput = {
            "farm": {
                "area_ha": -10.0,  # Invalid: negative area
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
                    "durability_years": 5.0,
                    "maintenance_usd_year": 200.0,
                    "brand": None,
                    "type": None,
                },
                {
                    "name": "Aerator2",
                    "power_hp": 3.0,
                    "sotr_kg_o2_h": 2.0,
                    "initial_cost_usd": 1500.0,
                    "durability_years": 6.0,
                    "maintenance_usd_year": 300.0,
                    "brand": None,
                    "type": None,
                },
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000.0,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 10.0,
            },
        }
        response = client.post("/compare", json=invalid_input)
        assert response.status_code == 422
        assert "greater_than_equal" in response.json()["detail"][0]["type"]

    def test_compare_aerators_single_aerator(self):
        """Test the compare endpoint with only one aerator."""

        class FarmInput(TypedDict):
            """Farm input parameters."""

            area_ha: float
            production_kg_ha_year: float
            cycles_per_year: float
            pond_depth_m: float

        class OxygenInput(TypedDict):
            """Oxygen input parameters."""

            temperature_c: float
            salinity_ppt: float
            shrimp_weight_g: float
            biomass_kg_ha: float

        class AeratorInput(TypedDict):
            """Aerator input parameters."""

            name: str
            power_hp: float
            sotr_kg_o2_h: float
            initial_cost_usd: float
            durability_years: float
            maintenance_usd_year: float
            brand: Optional[str]
            type: Optional[str]

        class FinancialInput(TypedDict):
            """Financial input parameters."""

            shrimp_price_usd_kg: float
            energy_cost_usd_kwh: float
            operating_hours_year: float
            discount_rate_percent: float
            inflation_rate_percent: float
            analysis_horizon_years: int
            safety_margin_percent: float

        class SingleAeratorInput(TypedDict):
            """Single aerator input parameters."""

            farm: FarmInput
            oxygen: OxygenInput
            aerators: List[AeratorInput]
            financial: FinancialInput

        single_aerator_input: SingleAeratorInput = {
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
                    "durability_years": 5.0,
                    "maintenance_usd_year": 200.0,
                    "brand": None,
                    "type": None,
                }
            ],
            "financial": {
                "shrimp_price_usd_kg": 5.0,
                "energy_cost_usd_kwh": 0.1,
                "operating_hours_year": 4000.0,
                "discount_rate_percent": 5.0,
                "inflation_rate_percent": 2.0,
                "analysis_horizon_years": 10,
                "safety_margin_percent": 10.0,
            },
        }
        response = client.post("/compare", json=single_aerator_input)
        assert response.status_code == 400
        assert response.json()["detail"] == (
            "Invalid input: At least two aerators are required"
        )

    def test_health_endpoint_multiple_requests(self):
        """Test the health endpoint with multiple requests."""
        for _ in range(3):
            response = client.get("/health")
            assert response.status_code == 200
            assert response.json() == {
                "status": "healthy",
                "message": "Service is running smoothly.",
            }


if __name__ == "__main__":
    # Run pytest via subprocess to ensure pytest.ini is respected
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "-v", __file__],
        check=True,
        capture_output=True,
        text=True,
    )
    print(result.stdout)
    sys.exit(result.returncode)

"""Test cases for aerator comparison module with edge cases.
This module contains unit tests for the aerator comparison functionality,
including edge cases and absurd external factors.
The tests are designed to ensure the robustness and reliability of the code.
"""

import unittest
from copy import deepcopy
from typing import Dict, List, Any, Callable, TypedDict, Protocol
import sys

# Add the parent directory to the system path for module import
sys.path.append("../..")
sys.path.append("..")
sys.path.append(".")

from backend.api.core.aerator_comparer import compare_aerators, handler


class ModifyFn(Protocol):
    # Accept any request-like object (Dict or MockRequest)
    def __call__(self, r: Any) -> Any: ...


# All keys below are accessed unconditionally → mark them as required
class AeratorTestCase(TypedDict):
    name: str
    aerators: List[Dict[str, Any]]
    expected_winner: str
    check: Callable[[Dict[str, Any]], bool]


class ExternalFactorTestCase(TypedDict):
    name: str
    modify: ModifyFn
    check: Callable[[Dict[str, Any]], bool]


class ReliabilityTestCase(TypedDict):
    name: str
    modify: ModifyFn
    check: Callable[[Dict[str, Any]], bool]


class MockRequest:
    """Mock request class to simulate invalid JSON input."""

    def __init__(self, request_data: Dict[str, Any]):
        self.body = "{invalid}"
        self.request_data = request_data

    def get(self, key: str, _default: Any) -> Any:
        """Mock get method to simulate request body retrieval."""
        if key == "body":
            return self.body
        return deepcopy(self.request_data)


class TestAeratorComparer(unittest.TestCase):
    """Test cases for aerator comparison module with edge cases."""

    def setUp(self):
        """Set up base test data from sample request."""
        self.base_request: Dict[str, Any] = {
            "farm": {
                "tod": 5443.76,
                "farm_area_ha": 1000,
                "shrimp_price": 5.0,
                "culture_days": 120,
                "shrimp_density_kg_m3": 0.3333333,
                "pond_depth_m": 1.0,
            },
            "financial": {
                "energy_cost": 0.05,
                "hours_per_night": 8,
                "discount_rate": 0.1,
                "inflation_rate": 0.025,
                "horizon": 9,
                "safety_margin": 0,
                "temperature": 31.5,
            },
            "aerators": [
                {
                    "name": "Aerator 1",
                    "sotr": 2.2,
                    "power_hp": 3,
                    "cost": 500,
                    "durability": 4.5,
                    "maintenance": 65,
                },
                {
                    "name": "Aerator 2",
                    "sotr": 2.2,
                    "power_hp": 3,
                    "cost": 500,
                    "durability": 2.0,
                    "maintenance": 50,
                },
            ],
        }

    def test_group1_aerator_specs_isolation(self):
        """Test aerator comparisons with isolated specification changes."""
        test_cases: List[AeratorTestCase] = [
            {
                "name": "Equal except durability",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 2.0,
                        "maintenance": 50,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0]["total_annual_cost"]
                < r["aeratorResults"][1]["total_annual_cost"],
            },
            {
                "name": "Equal except SOTR",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.5,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.0,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0]["num_aerators"]
                < r["aeratorResults"][1]["num_aerators"],
            },
            {
                "name": "Equal except horsepower",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.2,
                        "power_hp": 4,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0]["annual_energy_cost"]
                < r["aeratorResults"][1]["annual_energy_cost"],
            },
            {
                "name": "Equal except cost",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 400,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 600,
                        "durability": 4.5,
                        "maintenance": 50,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0]["total_initial_cost"]
                < r["aeratorResults"][1]["total_initial_cost"],
            },
            {
                "name": "Equal except maintenance",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 40,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.2,
                        "power_hp": 3,
                        "cost": 500,
                        "durability": 4.5,
                        "maintenance": 60,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0][
                    "annual_maintenance_cost"
                ]
                < r["aeratorResults"][1]["annual_maintenance_cost"],
            },
            {
                "name": "Most efficient is cheaper",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.5,
                        "power_hp": 3,
                        "cost": 400,
                        "durability": 4.5,
                        "maintenance": 40,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.0,
                        "power_hp": 4,
                        "cost": 600,
                        "durability": 2.0,
                        "maintenance": 60,
                    },
                ],
                "expected_winner": "A1",
                "check": lambda r: r["aeratorResults"][0]["npv_savings"]
                > r["aeratorResults"][1]["npv_savings"],
            },
            {
                "name": "Most expensive is less efficient",
                "aerators": [
                    {
                        "name": "A1",
                        "sotr": 2.0,
                        "power_hp": 4,
                        "cost": 600,
                        "durability": 2.0,
                        "maintenance": 60,
                    },
                    {
                        "name": "A2",
                        "sotr": 2.5,
                        "power_hp": 3,
                        "cost": 400,
                        "durability": 4.5,
                        "maintenance": 40,
                    },
                ],
                "expected_winner": "A2",
                "check": lambda r: r["aeratorResults"][1]["irr"]
                > r["aeratorResults"][0]["irr"],
            },
        ]

        for case in test_cases:
            with self.subTest(case=case["name"]):
                request: Dict[str, Any] = deepcopy(self.base_request)
                request["aerators"] = case["aerators"]
                result: Dict[str, Any] = compare_aerators(request)
                self.assertNotIn("error", result, f"Error in {case['name']}")
                self.assertEqual(
                    result["winnerLabel"], case["expected_winner"]
                )
                self.assertTrue(
                    case["check"](result), f"Check failed for {case['name']}"
                )

    def test_group2_absurd_external_factors(self):
        """Test absurd external factors for robustness."""
        test_cases: List[ExternalFactorTestCase] = [
            {
                "name": "Astronomical inflation rate",
                "modify": lambda r: r["financial"].update({
                    "inflation_rate": 10.0
                }),
                "check": lambda r: r["aeratorResults"][0]["npv_savings"] > 0,
            },
            {
                "name": "Negative discount rate",
                "modify": lambda r: r["financial"].update({
                    "discount_rate": -0.05
                }),
                "check": lambda r: r["aeratorResults"][0]["irr"] > 0,
            },
            {
                "name": "Lifetime horizon",
                "modify": lambda r: r["financial"].update({"horizon": 100}),
                "check": lambda r: r["aeratorResults"][0]["npv_savings"] > 0,
            },
            {
                "name": "Single day horizon",
                "modify": lambda r: r["financial"].update({"horizon": 1}),
                "check": lambda r: abs(
                    r["aeratorResults"][0]["npv_savings"] - 468423.89
                )
                < 1e-2,
            },
            {
                "name": "Zero shrimp price",
                "modify": lambda r: r["farm"].update({"shrimp_price": 0.0}),
                "check": lambda r: all(
                    res["cost_percent_revenue"] == 0
                    for res in r["aeratorResults"]
                ),
            },
            {
                "name": "Tremendous shrimp price",
                "modify": lambda r: r["farm"].update({"shrimp_price": 1000.0}),
                "check": lambda r: r["aeratorResults"][0][
                    "cost_percent_revenue"
                ]
                < 0.01,
            },
            {
                "name": "Mariana Trench pond depth",
                "modify": lambda r: r["farm"].update({"pond_depth_m": 11000}),
                "check": lambda r: r["annual_revenue"] > 1e9,
            },
            {
                "name": "Farm size exceeds world area",
                "modify": lambda r: r["farm"].update({"farm_area_ha": 1e10}),
                "check": lambda r: r["aeratorResults"][0]["num_aerators"]
                > 1e6,
            },
            {
                "name": "Density exceeds volume",
                "modify": lambda r: r["farm"].update({
                    "shrimp_density_kg_m3": 1000
                }),
                "check": lambda r: r["annual_revenue"] > 1e9,
            },
            {
                "name": "Zero TOD",
                "modify": lambda r: r["farm"].update({"tod": 0}),
                "check": lambda r: "error" in r
                and r["error"] == "TOD must be positive",
            },
            {
                "name": "Negative TOD",
                "modify": lambda r: r["farm"].update({"tod": -5443.76}),
                "check": lambda r: "error" in r
                and r["error"] == "TOD must be positive",
            },
            {
                "name": "Astronomical TOD",
                "modify": lambda r: r["farm"].update({"tod": 1e6}),
                "check": lambda r: r["aeratorResults"][0]["num_aerators"]
                > 1e5,
            },
            {
                "name": "Dead Sea salinity (handled as valid)",
                # Salinity not modeled, use temperature
                "modify": lambda r: r["financial"].update({
                    "temperature": 31.5
                }),
                "check": lambda r: r["aeratorResults"][0]["sae"] > 0,
            },
            {
                "name": "Below absolute zero temperature",
                "modify": lambda r: r["financial"].update({
                    "temperature": -300
                }),
                "check": lambda r: r["aeratorResults"][0]["num_aerators"] > 0,
            },
            {
                "name": "Sun-like temperature",
                "modify": lambda r: r["financial"].update({
                    "temperature": 5500
                }),
                "check": lambda r: r["aeratorResults"][0]["num_aerators"]
                < 1e3,
            },
        ]

        for case in test_cases:
            with self.subTest(case=case["name"]):
                request: Dict[str, Any] = deepcopy(self.base_request)
                case["modify"](request)
                result: Dict[str, Any] = compare_aerators(request)
                self.assertTrue(
                    case["check"](result), f"Check failed for {case['name']}"
                )

    def test_group3_code_structure_reliability(self):
        """Test code structure, types, scope, and input validation."""
        test_cases: List[ReliabilityTestCase] = [
            {
                "name": "Fewer than two aerators",
                "modify": lambda r: r.__setitem__(
                    "aerators", [r["aerators"][0]]
                ),
                "check": lambda r: "error" in r
                and r["error"] == "At least two aerators are required",
            },
            {
                "name": "Zero SOTR for all aerators",
                "modify": lambda r: [
                    a.update({"sotr": 0}) for a in r["aerators"]
                ],
                "check": lambda r: "error" in r
                and r["error"]
                == "At least one aerator must have positive SOTR",
            },
            {
                "name": "Zero durability",
                "modify": lambda r: r["aerators"][0].update({"durability": 0}),
                "check": lambda r: r["aeratorResults"][0][
                    "annual_replacement_cost"
                ]
                == 0,
            },
            {
                "name": "Negative cost",
                "modify": lambda r: r["aerators"][0].update({"cost": -500}),
                "check": lambda r: r["aeratorResults"][0]["total_initial_cost"]
                < 0,
            },
            {
                "name": "Non-numeric inputs",
                "modify": lambda r: r["aerators"][0].update({
                    "sotr": "invalid"
                }),
                "check": lambda r: "error" in r and "JSONDecodeError" in r,
            },
            {
                "name": "Missing aerator fields",
                "modify": lambda r: r["aerators"][0].pop("sotr", None),
                "check": lambda r: "error" in r and "TypeError" in r,
            },
            {
                "name": "Invalid JSON input",
                "modify": lambda r: setattr(r, "body", "{invalid}")
                if isinstance(r, MockRequest)
                else None,
                "check": lambda r: r["statusCode"] == 500
                and "JSONDecodeError" in r["body"],
            },
        ]

        for case in test_cases:
            with self.subTest(case=case["name"]):
                request: Dict[str, Any] = deepcopy(self.base_request)
                if case["name"] == "Invalid JSON input":
                    mock_request = MockRequest(request)
                    case["modify"](mock_request)
                    result = handler(mock_request)  # type: ignore
                else:
                    case["modify"](request)
                    result = compare_aerators(request)
                self.assertTrue(
                    case["check"](result), f"Check failed for {case['name']}"
                )


if __name__ == "__main__":
    unittest.main()

"""Test cases for the FastAPI application using pytest and TestClient."""

from unittest.mock import patch
from fastapi.testclient import TestClient
from typing import Dict, Any, cast  # add cast

from backend.api.main import app

client = TestClient(app)

# Sample data for testing
sample_aerator_data: Dict[str, Any] = {  # NEW type hint
    "tod": 0.6,
    "farm_area": 10,
    "financial_params": {
        "electricity_cost": 0.12,
        "operating_hours": 18,
        "days_per_year": 365,
        "investment_horizon": 10,
    },
    "aerators": [
        {"name": "Aerator 1", "power": 1.5, "pumprate": 2.0, "price": 1000},
        {"name": "Aerator 2", "power": 2.0, "pumprate": 3.0, "price": 1500},
    ],
}

# Mock response for compare_aerators function
mock_comparison_result: Dict[str, Any] = {  # NEW type hint
    "best_aerator": "Aerator 2",
    "aerator_comparisons": [
        {"name": "Aerator 1", "score": 0.8},
        {"name": "Aerator 2", "score": 0.9},
    ],
    "financial_analysis": {"payback_period": 2.5},
}


def test_health_check():
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {
        "status": "healthy",
        "message": "Service is running smoothly",
    }


@patch("backend.api.routes.aerator.compare_aerators")
def test_compare_aerators_endpoint(mock_compare: Any):  # NEW annotation
    """Test the compare_aerators endpoint."""
    mock_compare.return_value = mock_comparison_result
    response = client.post("/compare", json=sample_aerator_data)
    assert response.status_code == 200
    mock_compare.assert_called_once_with(sample_aerator_data)
    assert response.json() == mock_comparison_result


def test_compare_aerators_invalid_json():
    """Test the compare_aerators endpoint with invalid JSON."""
    response = client.post(
        "/compare",
        data=cast(Any, b"invalid json"),  # cast to silence type checker
    )
    # The endpoint handles errors and returns 200
    assert response.status_code == 200
    assert "error" in response.json()
    assert "Failed to parse JSON body" in response.json()["error"]


def test_compare_aerators_missing_field():
    """Test the compare_aerators endpoint with a missing required field."""
    # Missing required field 'tod'
    invalid_data: Dict[str, Any] = sample_aerator_data.copy()  # NEW type hint
    del invalid_data["tod"]
    response = client.post("/compare", json=invalid_data)
    # The endpoint handles errors and returns 200
    assert response.status_code == 200
    assert "error" in response.json()


def test_root_endpoint():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the AeraSync API!"}


def test_catch_all_health():
    """Test the health check endpoint with a catch-all route."""
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


@patch("backend.api.routes.aerator.compare_aerators")
def test_catch_all_compare(mock_compare: Any):  # NEW annotation
    """Test the compare_aerators endpoint with a catch-all route."""
    mock_compare.return_value = mock_comparison_result
    response = client.post("/api/compare", json=sample_aerator_data)
    assert response.status_code == 200
    mock_compare.assert_called_once_with(sample_aerator_data)
    assert response.json() == mock_comparison_result


def test_options_handler():
    """Test the OPTIONS handler for CORS."""
    # Skip checking specific status code and just verify CORS headers
    # from middleware which is applied regardless of route handling
    response = client.options(
        "/compare",
        headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert "Access-Control-Allow-Origin" in response.headers
    assert (
        "http://localhost:8080"
        in response.headers["Access-Control-Allow-Origin"]
    )
    assert "Access-Control-Allow-Methods" in response.headers
    assert "POST" in response.headers["Access-Control-Allow-Methods"]


def test_catch_all_not_found():
    """Test the catch-all route for 404 errors."""
    response = client.get("/nonexistent-endpoint")
    assert response.status_code == 404
    assert "error" in response.json()
    assert "Endpoint not found" in response.json()["error"]

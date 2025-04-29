"""test_aerator_comparer.py
Unit tests for the AeratorComparer class and its methods."""
from unittest.mock import MagicMock, patch, call
import sqlite3
import json
import math  # Import math for ceil
import pytest
from .aerator_comparer import AeratorComparer
from .sotr_calculator import SaturationCalculator
from .shrimp_respiration_calculator import ShrimpRespirationCalculator

# test_aerator_comparer.py

# Use relative imports because test file is sibling to the module
from .aerator_types import (
    Aerator,
    AeratorComparisonRequest,
    AeratorResult,
    ComparisonResults,
    FinancialInput,
    FarmInput,
    OxygenInput,
)

# --- Fixtures ---


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
    # Use shared memory for potential multi-access tests
    return "file::memory:?cache=shared"


@pytest.fixture
def aerator_comparer(
    mock_sat_calc, mock_resp_calc, db_url_for_test
):  # Renamed params
    """Fixture for an AeratorComparer instance with mocked dependencies."""
    # Ensure a clean state for each test using the fixture
    with sqlite3.connect(db_url_for_test, check_same_thread=False) as conn:
        conn.execute("DROP TABLE IF EXISTS aerator_comparisons")
    comparer = AeratorComparer(
        saturation_calculator=mock_sat_calc,
        respiration_calculator=mock_resp_calc,
        db_url=db_url_for_test,
    )
    return comparer


@pytest.fixture
def sample_aerator_1():
    """Fixture for a sample Aerator Pydantic model."""
    return Aerator(
        name="Aerator A",
        brand="Brand X",
        type="Paddlewheel",
        power_hp=2.0,
        sotr_kg_o2_h=1.5,
        initial_cost_usd=1000.0,
        maintenance_usd_year=100.0,
        durability_years=5,
    )


@pytest.fixture
def sample_aerator_2():
    """Fixture for another sample Aerator Pydantic model."""
    return Aerator(
        name="Aerator B",
        brand="Brand Y",
        type="Aspirator",
        power_hp=1.5,
        sotr_kg_o2_h=1.2,
        initial_cost_usd=800.0,
        maintenance_usd_year=80.0,
        durability_years=7,
    )


@pytest.fixture
def sample_financial_input():
    """Fixture for a sample FinancialInput Pydantic model."""
    return FinancialInput(
        energy_cost_usd_kwh=0.15,
        operating_hours_year=4000,
        discount_rate_percent=8.0,
        inflation_rate_percent=2.0,
        analysis_horizon_years=10,
        safety_margin_percent=20.0,
    )


@pytest.fixture
def sample_farm_input():
    """Fixture for a sample FarmInput Pydantic model."""
    return FarmInput(area_ha=5.0)


@pytest.fixture
def sample_oxygen_input():
    """Fixture for a sample OxygenInput Pydantic model."""
    return OxygenInput(
        temperature_c=28.0,
        salinity_ppt=15.0,
        shrimp_weight_g=10.0,
        biomass_kg_ha=3000.0,
    )


@pytest.fixture
def sample_comparison_request(
    aerator_1, aerator_2, financial_in, farm_in, oxygen_in
):  # Renamed params
    """Fixture for a sample AeratorComparisonRequest Pydantic model."""
    # Note: Pydantic models expect model instances, not dicts here
    return AeratorComparisonRequest(
        aerators=[aerator_1, aerator_2],
        financial=financial_in,
        farm=farm_in,
        oxygen=oxygen_in,
    )

# --- Test Cases ---


def test_aerator_comparer_init(
    comparer_instance, db_url_for_test
):  # Renamed params
    """Test AeratorComparer initialization and table creation."""
    assert comparer_instance.db_url == db_url_for_test
    assert isinstance(comparer_instance.saturation_calculator, MagicMock)
    assert isinstance(comparer_instance.respiration_calculator, MagicMock)

    # Verify table exists
    try:
        with sqlite3.connect(db_url_for_test, check_same_thread=False) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT name FROM sqlite_master "
                "WHERE type='table' AND name='aerator_comparisons';"
            )
            result = cursor.fetchone()
            assert result is not None
            assert result[0] == "aerator_comparisons"
    except sqlite3.Error as e:
        pytest.fail(f"Database check failed: {e}")


def test_log_comparison(comparer_instance, db_url_for_test):  # Renamed params
    """Test logging comparison data to the database."""
    inputs_data = {"input_param": "value1"}
    results_data = {"output_param": "result1"}
    inputs_json = json.dumps(inputs_data)
    results_json = json.dumps(results_data)

    comparer_instance.log_comparison(inputs_data, results_data)

    # Verify data was inserted
    try:
        with sqlite3.connect(db_url_for_test, check_same_thread=False) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT inputs, results FROM aerator_comparisons "
                "ORDER BY id DESC LIMIT 1;"
            )
            row = cursor.fetchone()
            assert row is not None
            assert row[0] == inputs_json
            assert row[1] == results_json
    except sqlite3.Error as e:
        pytest.fail(f"Database query failed: {e}")


def test_log_comparison_db_error(comparer_instance):  # Renamed param
    """Test error handling during database logging."""
    inputs_data = {"input_param": "value1"}
    results_data = {"output_param": "result1"}

    # Simulate a database error during insertion
    with patch('sqlite3.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.execute.side_effect = sqlite3.Error("Simulated DB Error")
        mock_connect.return_value.__enter__.return_value = mock_conn

        match_str = "Failed to log comparison: Simulated DB Error"
        with pytest.raises(RuntimeError, match=match_str):
            comparer_instance.log_comparison(inputs_data, results_data)


def test_calculate_tod(
    comparer_instance, req_sample, mock_sat_calc, mock_resp_calc
):  # Renamed params
    """Test the calculation of Total Oxygen Demand (TOD)."""
    # Setup mock return values
    mock_sat_calc.get_o2_saturation.return_value = 7.5  # mg/L
    mock_resp_calc.get_respiration_rate.return_value = 350.0  # mg O2/kg/h

    request = req_sample
    farm_area = request.farm.area_ha  # 5.0 ha
    biomass_density = request.oxygen.biomass_kg_ha  # 3000.0 kg/ha
    total_biomass = farm_area * biomass_density  # 15000 kg
    respiration_rate = 350.0  # mg O2/kg/h

    # 15000 * 350 = 5,250,000 mg/h
    expected_tod_mg_h = total_biomass * respiration_rate
    expected_tod_kg_h = expected_tod_mg_h / 1_000_000  # 5.25 kg/h
    expected_tod_kg_day = expected_tod_kg_h * 24  # 126.0 kg/day

    tod_kg_h, tod_kg_day = comparer_instance.calculate_tod(request)

    # Assertions
    mock_sat_calc.get_o2_saturation.assert_called_once_with(
        temperature_c=request.oxygen.temperature_c,
        salinity_ppt=request.oxygen.salinity_ppt,
    )
    mock_resp_calc.get_respiration_rate.assert_called_once_with(
        temperature=request.oxygen.temperature_c,
        salinity=request.oxygen.salinity_ppt,
        shrimp_weight=request.oxygen.shrimp_weight_g,
    )
    assert tod_kg_h == pytest.approx(expected_tod_kg_h)
    assert tod_kg_day == pytest.approx(expected_tod_kg_day)


def test_calculate_aerator_performance(
    comparer_instance, aerator_1, financial_in
):  # Renamed params
    """Test the calculation of performance metrics for a single aerator."""
    aerator = aerator_1
    financial = financial_in
    tod_kg_o2_h = 5.0  # Example TOD
    farm_area_ha = 10.0  # Example farm area
    hp_to_kw = 0.7457

    # Expected calculations
    # 5.0 * 1.2 = 6.0 kg/h
    required_sotr = tod_kg_o2_h * (1 + financial.safety_margin_percent / 100)
    # ceil(6.0 / 1.5) = 4
    num_aerators = math.ceil(required_sotr / aerator.sotr_kg_o2_h)
    total_power_hp = num_aerators * aerator.power_hp  # 4 * 2.0 = 8.0 hp
    total_power_kw = total_power_hp * hp_to_kw  # 8.0 * 0.7457 = 5.9656 kW
    # 4 * 1000 = 4000.0 USD
    total_initial_cost = num_aerators * aerator.initial_cost_usd
    # 5.9656 * 0.15 * 4000 = 3579.36 USD
    annual_energy_cost = (
        total_power_kw
        * financial.energy_cost_usd_kwh
        * financial.operating_hours_year
    )
    # 4 * 100 = 400.0 USD
    annual_maintenance_cost = num_aerators * aerator.maintenance_usd_year
    aerators_per_ha = num_aerators / farm_area_ha  # 4 / 10.0 = 0.4
    hp_per_ha = total_power_hp / farm_area_ha  # 8.0 / 10.0 = 0.8

    # NPV calculation (simplified check, exact value depends on npf.npv)
    # Let's mock npf.npv to simplify the assertion for this test unit
    with patch('numpy_financial.npv') as mock_npv:
        mock_npv.return_value = -15000.0  # Example NPV cost

        result = comparer_instance.calculate_aerator_performance(
            aerator=aerator,
            tod_kg_o2_h=tod_kg_o2_h,
            financial_input=financial,
            farm_area_ha=farm_area_ha,
        )

        # Assertions
        assert isinstance(result, AeratorResult)
        assert result.name == aerator.name
        assert result.num_aerators == num_aerators
        assert result.total_power_hp == pytest.approx(total_power_hp)
        assert result.total_initial_cost == pytest.approx(total_initial_cost)
        assert result.annual_energy_cost == pytest.approx(annual_energy_cost)
        assert result.annual_maintenance_cost == pytest.approx(
            annual_maintenance_cost
        )
        # Check against mocked value
        assert result.npv_cost == pytest.approx(-15000.0)
        assert result.aerators_per_ha == pytest.approx(aerators_per_ha)
        assert result.hp_per_ha == pytest.approx(hp_per_ha)

        # Check if npf.npv was called (basic check, args check is complex)
        mock_npv.assert_called_once()
        # Example check for cash flow structure
        # (Year 0 should be negative initial cost)
        call_args, _ = mock_npv.call_args
        assert call_args[1][0] == pytest.approx(-total_initial_cost)


def test_calculate_aerator_performance_zero_area(
    comparer_instance, aerator_1, financial_in
):  # Renamed params
    """Test aerator performance calculation with zero farm area."""
    with patch('numpy_financial.npv', return_value=-10000.0):  # Mock NPV
        result = comparer_instance.calculate_aerator_performance(
            aerator=aerator_1,
            tod_kg_o2_h=5.0,
            financial_input=financial_in,
            farm_area_ha=0.0,  # Zero area
        )
        assert result.aerators_per_ha == 0.0
        assert result.hp_per_ha == 0.0


def test_compare_aerators_success(
    comparer_instance, req_sample
):  # Renamed params
    """Test the main comparison logic finding a winner."""
    request = req_sample
    expected_tod_kg_h = 5.25  # From test_calculate_tod example
    expected_tod_kg_day = 126.0

    # Mock underlying calculations
    comparer_instance.calculate_tod = MagicMock(
        return_value=(expected_tod_kg_h, expected_tod_kg_day)
    )

    # Define mock results for each aerator
    result_a = AeratorResult(
        name="Aerator A",
        brand="Brand X",
        type="Paddlewheel",
        num_aerators=4,
        total_power_hp=8.0,
        total_initial_cost=4000.0,
        annual_energy_cost=3579.36,
        annual_maintenance_cost=400.0,
        npv_cost=-15000.0,
        aerators_per_ha=0.8,
        hp_per_ha=1.6,
    )
    result_b = AeratorResult(
        name="Aerator B",
        brand="Brand Y",
        type="Aspirator",
        num_aerators=5,
        total_power_hp=7.5,
        total_initial_cost=4000.0,
        annual_energy_cost=3355.65,
        annual_maintenance_cost=400.0,
        npv_cost=-14000.0,  # Lower NPV cost
        aerators_per_ha=1.0,
        hp_per_ha=1.5,
    )

    comparer_instance.calculate_aerator_performance = MagicMock(
        side_effect=[result_a, result_b]
    )
    comparer_instance.log_comparison = MagicMock()

    # Perform comparison
    comparison_results = comparer_instance.compare_aerators(request)

    # Assertions
    assert isinstance(comparison_results, ComparisonResults)
    assert comparison_results.tod["kg_o2_hour"] == pytest.approx(
        expected_tod_kg_h
    )
    assert comparison_results.tod["kg_o2_day"] == pytest.approx(
        expected_tod_kg_day
    )
    assert len(comparison_results.aeratorResults) == 2
    assert comparison_results.aeratorResults[0] == result_a
    assert comparison_results.aeratorResults[1] == result_b
    assert comparison_results.winnerLabel == "Aerator B"  # Lower npv_cost

    # Check mocks were called
    comparer_instance.calculate_tod.assert_called_once_with(request)
    assert comparer_instance.calculate_aerator_performance.call_count == 2
    comparer_instance.calculate_aerator_performance.assert_has_calls([
        call(
            aerator=request.aerators[0],
            tod_kg_o2_h=expected_tod_kg_h,
            financial_input=request.financial,
            farm_area_ha=request.farm.area_ha,
        ),
        call(
            aerator=request.aerators[1],
            tod_kg_o2_h=expected_tod_kg_h,
            financial_input=request.financial,
            farm_area_ha=request.farm.area_ha,
        ),
    ])
    comparer_instance.log_comparison.assert_called_once()
    # Check log arguments (basic check)
    log_args, _ = comparer_instance.log_comparison.call_args
    assert log_args[0] == request.model_dump()
    assert log_args[1] == comparison_results.model_dump()


def test_compare_aerators_insufficient_aerators(
    comparer_instance, req_sample
):  # Renamed params
    """Test ValueError when fewer than two aerators are provided."""
    request = req_sample
    request.aerators = [request.aerators[0]]  # Only one aerator

    with pytest.raises(ValueError, match="At least two aerators are required"):
        comparer_instance.compare_aerators(request)


def test_compare_aerators_logging_fails(
    comparer_instance, req_sample
):  # Renamed params
    """Test that comparison succeeds even if logging fails."""
    request = req_sample
    expected_tod_kg_h = 5.25
    expected_tod_kg_day = 126.0

    # Mock calculations
    comparer_instance.calculate_tod = MagicMock(
        return_value=(expected_tod_kg_h, expected_tod_kg_day)
    )
    result_a = AeratorResult(
        name="Aerator A",
        brand="X",
        type="T",
        num_aerators=1,
        total_power_hp=1,
        total_initial_cost=1,
        annual_energy_cost=1,
        annual_maintenance_cost=1,
        npv_cost=-150,
        aerators_per_ha=1,
        hp_per_ha=1,
    )
    result_b = AeratorResult(
        name="Aerator B",
        brand="Y",
        type="T",
        num_aerators=1,
        total_power_hp=1,
        total_initial_cost=1,
        annual_energy_cost=1,
        annual_maintenance_cost=1,
        npv_cost=-140,
        aerators_per_ha=1,
        hp_per_ha=1,
    )
    comparer_instance.calculate_aerator_performance = MagicMock(
        side_effect=[result_a, result_b]
    )

    # Mock log_comparison to raise an error
    comparer_instance.log_comparison = MagicMock(
        side_effect=RuntimeError("Simulated logging error")
    )

    # Perform comparison - should not raise the logging error
    comparison_results = comparer_instance.compare_aerators(request)

    # Assertions - verify comparison still worked
    assert comparison_results is not None
    assert comparison_results.winnerLabel == "Aerator B"
    assert len(comparison_results.aeratorResults) == 2
    # Verify log was attempted
    comparer_instance.log_comparison.assert_called_once()

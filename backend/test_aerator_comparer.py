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
    mock_saturation_calculator,
    mock_respiration_calculator,
    test_db_url,
):
    """Fixture for an AeratorComparer instance with mocked dependencies."""
    # Ensure a clean state for each test using the fixture
    with sqlite3.connect(
        test_db_url, check_same_thread=False
    ) as conn:
        conn.execute("DROP TABLE IF EXISTS aerator_comparisons")
    comparer = AeratorComparer(
        saturation_calculator=mock_saturation_calculator,
        respiration_calculator=mock_respiration_calculator,
        db_url=test_db_url,
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
    sample_aerator_1,
    sample_aerator_2,
    sample_financial_input,
    sample_farm_input,
    sample_oxygen_input,
):
    """Fixture for a sample AeratorComparisonRequest Pydantic model."""
    # Note: Pydantic models expect model instances, not dicts here
    return AeratorComparisonRequest(
        aerators=[sample_aerator_1, sample_aerator_2],
        financial=sample_financial_input,
        farm=sample_farm_input,
        oxygen=sample_oxygen_input,
    )

# --- Test Cases ---


def test_aerator_comparer_init(
    aerator_comparer, test_db_url
):
    """Test AeratorComparer initialization and table creation."""
    assert aerator_comparer.db_url == test_db_url
    assert isinstance(
        aerator_comparer.saturation_calculator, MagicMock
    )
    assert isinstance(
        aerator_comparer.respiration_calculator, MagicMock
    )

    # Verify table exists
    try:
        with sqlite3.connect(
            test_db_url, check_same_thread=False
        ) as conn:
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


def test_log_comparison(aerator_comparer, test_db_url):
    """Test logging comparison data to the database."""
    inputs_data = {"input_param": "value1"}
    results_data = {"output_param": "result1"}
    inputs_json = json.dumps(inputs_data)
    results_json = json.dumps(results_data)

    aerator_comparer.log_comparison(inputs_data, results_data)

    # Verify data was inserted
    try:
        with sqlite3.connect(
            test_db_url, check_same_thread=False
        ) as conn:
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


def test_log_comparison_db_error(aerator_comparer):
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
            aerator_comparer.log_comparison(inputs_data, results_data)


def test_calculate_tod(
    aerator_comparer,
    sample_comparison_request,
    mock_saturation_calculator,
    mock_respiration_calculator,
):
    """Test the calculation of Total Oxygen Demand (TOD)."""
    # Setup mock return values
    mock_saturation_calculator.get_o2_saturation.return_value = (
        7.5
    )  # mg/L
    mock_respiration_calculator.get_respiration_rate.return_value = (
        350.0
    )  # mg O2/kg/h

    request = sample_comparison_request
    farm_area = request.farm.area_ha  # 5.0 ha
    biomass_density = request.oxygen.biomass_kg_ha  # 3000.0 kg/ha
    total_biomass = farm_area * biomass_density  # 15000 kg

    # Calculate expected values directly using the mocked return value
    expected_respiration_rate = 350.0  # Use the mock return value directly
    expected_tod_mg_h = total_biomass * expected_respiration_rate
    expected_tod_kg_h = expected_tod_mg_h / 1_000_000  # 5.25 kg/h
    expected_tod_kg_day = expected_tod_kg_h * 24  # 126.0 kg/day

    tod_kg_h, tod_kg_day = aerator_comparer.calculate_tod(request)

    # Assertions
    mock_saturation_calculator.get_o2_saturation.assert_called_once_with(
        temperature_c=request.oxygen.temperature_c,
        salinity_ppt=request.oxygen.salinity_ppt,
    )
    mock_resp = mock_respiration_calculator
    mock_resp.get_respiration_rate.assert_called_once_with(
        temperature=request.oxygen.temperature_c,
        salinity=request.oxygen.salinity_ppt,
        shrimp_weight=request.oxygen.shrimp_weight_g,
    )
    assert tod_kg_h == pytest.approx(expected_tod_kg_h)
    assert tod_kg_day == pytest.approx(expected_tod_kg_day)


def test_calculate_aerator_performance(
    aerator_comparer,
    sample_aerator_1,
    sample_financial_input,
):
    """Test the calculation of performance metrics for a single aerator."""
    aerator = sample_aerator_1
    financial = sample_financial_input
    tod_kg_o2_h = 5.0  # Example TOD
    farm_area_ha = 10.0  # Example farm area
    hp_to_kw = 0.7457

    required_sotr = tod_kg_o2_h * (1 + financial.safety_margin_percent / 100)
    num_aerators = math.ceil(required_sotr / aerator.sotr_kg_o2_h)
    total_power_hp = num_aerators * aerator.power_hp
    total_power_kw = total_power_hp * hp_to_kw
    total_initial_cost = num_aerators * aerator.initial_cost_usd
    annual_energy_cost = (
        total_power_kw
        * financial.energy_cost_usd_kwh
        * financial.operating_hours_year
    )
    annual_maintenance_cost = num_aerators * aerator.maintenance_usd_year
    aerators_per_ha = num_aerators / farm_area_ha
    hp_per_ha = total_power_hp / farm_area_ha

    with patch('numpy_financial.npv') as mock_npv:
        mock_npv.return_value = -15000.0

        result = aerator_comparer.calculate_aerator_performance(
            aerator=aerator,
            tod_kg_o2_h=tod_kg_o2_h,
            financial_input=financial,
            farm_area_ha=farm_area_ha,
        )

        assert isinstance(result, AeratorResult)
        assert result.name == aerator.name
        assert result.num_aerators == num_aerators
        assert result.total_power_hp == pytest.approx(total_power_hp)
        assert result.total_initial_cost == pytest.approx(total_initial_cost)
        assert result.annual_energy_cost == pytest.approx(annual_energy_cost)
        assert result.annual_maintenance_cost == pytest.approx(
            annual_maintenance_cost
        )
        assert result.npv_cost == pytest.approx(-15000.0)
        assert result.aerators_per_ha == pytest.approx(aerators_per_ha)
        assert result.hp_per_ha == pytest.approx(hp_per_ha)

        mock_npv.assert_called_once()
        call_args, _ = mock_npv.call_args
        assert call_args[1][0] == pytest.approx(-total_initial_cost)


def test_calculate_aerator_performance_zero_area(
    aerator_comparer,
    sample_aerator_1,
    sample_financial_input,
):
    """Test aerator performance calculation with zero farm area."""
    with patch('numpy_financial.npv', return_value=-10000.0):
        result = aerator_comparer.calculate_aerator_performance(
            aerator=sample_aerator_1,
            tod_kg_o2_h=5.0,
            financial_input=sample_financial_input,
            farm_area_ha=0.0,
        )
        assert result.aerators_per_ha == 0.0
        assert result.hp_per_ha == 0.0


def test_compare_aerators_success(
    aerator_comparer, sample_comparison_request
):
    """Test the main comparison logic finding a winner."""
    request = sample_comparison_request
    expected_tod_kg_h = 5.25
    expected_tod_kg_day = 126.0

    aerator_comparer.calculate_tod = MagicMock(
        return_value=(expected_tod_kg_h, expected_tod_kg_day)
    )

    # Create result with lower (better) NPV cost to become the winner
    result_b = AeratorResult(
        name="Aerator B",
        brand="Brand Y",
        type="Aspirator",
        num_aerators=5,
        total_power_hp=7.5,
        total_initial_cost=4000.0,
        annual_energy_cost=3355.65,
        annual_maintenance_cost=400.0,
        npv_cost=-14000.0,  # Lower NPV cost (less negative)
        aerators_per_ha=1.0,
        hp_per_ha=1.5,
    )

    # Create result with higher (worse) NPV cost
    result_a = AeratorResult(
        name="Aerator A",
        brand="Brand X",
        type="Paddlewheel",
        num_aerators=4,
        total_power_hp=8.0,
        total_initial_cost=4000.0,
        annual_energy_cost=3579.36,
        annual_maintenance_cost=400.0,
        npv_cost=-15000.0,  # Higher NPV cost (more negative)
        aerators_per_ha=0.8,
        hp_per_ha=1.6,
    )

    aerator_comparer.calculate_aerator_performance = MagicMock(
        side_effect=[result_a, result_b]
    )
    aerator_comparer.log_comparison = MagicMock()

    comparison_results = aerator_comparer.compare_aerators(request)

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
    assert comparison_results.winnerLabel == "Aerator B"

    aerator_comparer.calculate_tod.assert_called_once_with(request)
    assert (
        aerator_comparer.calculate_aerator_performance.call_count == 2
    )
    aerator_comparer.calculate_aerator_performance.assert_has_calls([
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
    aerator_comparer.log_comparison.assert_called_once()
    log_args, _ = aerator_comparer.log_comparison.call_args
    assert log_args[0] == request.model_dump()
    assert log_args[1] == comparison_results.model_dump()


def test_compare_aerators_insufficient_aerators(
    aerator_comparer, sample_comparison_request
):
    """Test ValueError when fewer than two aerators are provided."""
    request = sample_comparison_request
    request.aerators = [request.aerators[0]]

    with pytest.raises(ValueError, match="At least two aerators are required"):
        aerator_comparer.compare_aerators(request)


def test_compare_aerators_logging_fails(
    aerator_comparer, sample_comparison_request
):
    """Test that comparison succeeds even if logging fails."""
    request = sample_comparison_request
    expected_tod_kg_h = 5.25
    expected_tod_kg_day = 126.0

    aerator_comparer.calculate_tod = MagicMock(
        return_value=(expected_tod_kg_h, expected_tod_kg_day)
    )
    # Result with worse NPV cost
    result_a = AeratorResult(
        name="Aerator A",
        brand="X",
        type="T",
        num_aerators=1,
        total_power_hp=1,
        total_initial_cost=1,
        annual_energy_cost=1,
        annual_maintenance_cost=1,
        npv_cost=-150,  # More negative NPV cost
        aerators_per_ha=1,
        hp_per_ha=1,
    )
    # Result with better NPV cost
    result_b = AeratorResult(
        name="Aerator B",
        brand="Y",
        type="T",
        num_aerators=1,
        total_power_hp=1,
        total_initial_cost=1,
        annual_energy_cost=1,
        annual_maintenance_cost=1,
        npv_cost=-140,  # Less negative NPV cost
        aerators_per_ha=1,
        hp_per_ha=1,
    )
    aerator_comparer.calculate_aerator_performance = MagicMock(
        side_effect=[result_a, result_b]
    )

    aerator_comparer.log_comparison = MagicMock(
        side_effect=RuntimeError("Simulated logging error")
    )

    comparison_results = aerator_comparer.compare_aerators(request)

    assert comparison_results is not None
    assert comparison_results.winnerLabel == "Aerator B"
    assert len(comparison_results.aeratorResults) == 2
    aerator_comparer.log_comparison.assert_called_once()

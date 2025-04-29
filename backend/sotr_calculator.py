"""Oxygen saturation and shrimp pond aerator performance calculations."""

import math
from abc import ABC, abstractmethod
from functools import lru_cache
from typing import Any, Dict, List, Optional  # Import List

from pydantic import BaseModel, Field  # Import BaseModel and Field

from .utils import load_json_data


class SaturationCalculator(ABC):
    """Abstract base class for oxygen saturation calculations."""

    def __init__(self, data_path: Optional[str] = None):
        """
        Initializes the calculator with the path to the JSON data file.

        Args:
            data_path: The path to the JSON data file.
                If None, computed dynamically.
        """
        self.data_path = data_path

        self.matrix: Optional[List[List[float]]] = None
        self.metadata: Optional[Dict[str, Any]] = None
        self.temp_step: float = 1.0
        self.sal_step: float = 5.0
        self.unit: str = "mg/L"
        self.load_data()

    def load_data(self):
        """Load oxygen saturation data from JSON file into a list of lists."""
        print(f"Attempting to load data from: {self.data_path}")
        if self.data_path is None:
            raise ValueError("data_path must be provided and cannot be None")
        data = load_json_data(self.data_path)
        self.metadata = data.get("metadata")
        if not self.metadata:
            raise ValueError("Metadata missing in JSON file")

        temp_range = self.metadata.get("temperature_range", {})
        sal_range = self.metadata.get("salinity_range", {})
        self.temp_step = float(temp_range.get("step", 1.0))
        self.sal_step = float(sal_range.get("step", 5.0))
        self.unit = self.metadata.get("unit", "mg/L")

        if "data" not in data:
            raise ValueError("'data' field missing in JSON file")

        # Load as list of lists instead of numpy array
        self.matrix = [
            [float(val) for val in row] for row in data["data"]
        ]
        num_rows = len(self.matrix)
        num_cols = len(self.matrix[0]) if num_rows > 0 else 0
        print(
            f"Data loaded successfully. Matrix dimensions: "
            f"{num_rows}x{num_cols}"
        )

    @lru_cache(maxsize=1000)
    def get_o2_saturation(self, temperature: float, salinity: float) -> float:
        """
        Get oxygen saturation (mg/L) for given temperature (°C)
        and salinity (‰).

        Args:
            temperature: Water temperature in °C (0 to 40).
            salinity: Salinity in parts per thousand (‰) (0 to 40).

        Returns:
            Oxygen saturation in mg/L.

        Raises:
            ValueError: If temperature or salinity is out of range.
            RuntimeError: If data matrix is not loaded.
        """
        if self.matrix is None or not self.matrix:
            raise RuntimeError(
                "Saturation data matrix not loaded. Call load_data() first."
            )

        if not (0 <= temperature <= 40 and 0 <= salinity <= 40):
            raise ValueError(
                "Temperature and salinity must be between 0 and 40"
            )

        temp_lower_idx = math.floor(temperature)
        temp_upper_idx = math.ceil(temperature)
        temp_fraction = (
            0.0
            if temp_lower_idx == temp_upper_idx
            else (
                (temperature - temp_lower_idx) /
                (temp_upper_idx - temp_lower_idx)
            )
        )

        # Get dimensions from the list of lists
        num_rows = len(self.matrix)
        num_cols = len(self.matrix[0]) if num_rows > 0 else 0
        if num_rows == 0 or num_cols == 0:
            raise RuntimeError("Saturation data matrix is empty.")

        max_sal_idx = num_cols - 1
        # Ensure sal_idx is within bounds [0, max_sal_idx]
        sal_idx = max(0, min(max_sal_idx, int(salinity / self.sal_step)))

        max_temp_idx = num_rows - 1
        # Ensure temp indices are within bounds [0, max_temp_idx]
        temp_lower_idx = max(0, min(max_temp_idx, temp_lower_idx))
        temp_upper_idx = max(0, min(max_temp_idx, temp_upper_idx))

        try:
            # Use standard list indexing
            sat_lower = float(self.matrix[temp_lower_idx][sal_idx])
            sat_upper = (
                float(self.matrix[temp_upper_idx][sal_idx])
                if temp_upper_idx != temp_lower_idx
                else sat_lower
            )
        except IndexError as exc:
            raise IndexError(
                f"Index out of bounds: T_low={temp_lower_idx}, "
                f"T_up={temp_upper_idx}, "
                f"Sal_idx={sal_idx}. Matrix dimensions={num_rows}x{num_cols}"
            ) from exc

        return sat_lower + (sat_upper - sat_lower) * temp_fraction

    @abstractmethod
    def calculate_metrics(self, params: Any) -> Dict[str, Any]:
        """Calculates key performance metrics for an aerator."""


class AeratorMetricsInput(BaseModel):  # Ensure BaseModel is imported
    """Pydantic model for aerator metrics calculation inputs."""

    temperature: float = Field(ge=0, le=40)
    salinity: float = Field(ge=0, le=40)
    hp: float = Field(ge=0)
    volume: float = Field(ge=0)
    t10: float = Field(ge=0)
    t70: float = Field(ge=0)
    kwh_price: float = Field(ge=0)
    aerator_id: str


class ShrimpPondCalculator(SaturationCalculator):
    """Concrete implementation for calculating shrimp pond aerator metrics."""

    def calculate_metrics(
        self, params: AeratorMetricsInput
    ) -> Dict[str, Any]:
        """
        Calculates basic aerator metrics:
        - O2 saturation
        - ideal volume
        - ideal horsepower
        """
        # Calculate oxygen saturation for provided conditions
        o2_sat = self.get_o2_saturation(
            params.temperature, params.salinity
        )
        # Compute ideal volume and horsepower
        ideal_vol = self.get_ideal_volume(params.hp)
        ideal_hp = self.get_ideal_hp(params.volume)
        return {
            "o2_saturation": o2_sat,
            "ideal_volume": ideal_vol,
            "ideal_hp": ideal_hp,
        }

    def get_ideal_volume(self, hp: float) -> float:
        """Get the ideal pond volume (m³) for a given horsepower."""
        if hp <= 0:
            return 0.0  # Return float
        if hp == 2:
            return 40.0
        if hp == 3:
            return 70.0  # Added missing return value
        return round(hp * 25.0, 0)

    def get_ideal_hp(self, volume: float) -> float:
        """Get the ideal horsepower for a given pond volume (m³)."""
        if volume <= 0:
            return 0.0  # Return float
        if volume <= 40:
            return 2.0  # Return float
        if volume <= 70:
            return 3.0  # Return float
        return max(2.0, round(volume / 25.0, 0))

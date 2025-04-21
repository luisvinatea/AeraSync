"""Shrimp respiration rate calculator with trilinear interpolation."""
import os
from typing import Any, Dict, List, Optional, Tuple

from utils import load_json_data


class ShrimpRespirationCalculator:
    """
    Calculates shrimp respiration rate based on loaded data using
    trilinear interpolation. Loads data from a JSON file structured
    similarly to the Dart version's input.
    """

    def __init__(self, data_path: Optional[str] = None):
        """
        Initializes the calculator with the path to the JSON data file.

        Args:
            data_path: The path to the JSON data file.
            If None, computed dynamically.
        """
        if data_path is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            repo_root = os.path.dirname(script_dir)
            self.data_path = os.path.join(
                repo_root, "assets", "data",
                "shrimp_respiration_salinity_temperature_weight.json"
            )
        else:
            self.data_path = data_path

        if not os.path.exists(self.data_path):
            raise FileNotFoundError(
                f"Shrimp respiration data file not found at: {self.data_path}"
            )

        self._respiration_data: Dict[str, Any] = {}
        self._salinity_values: List[float] = []
        self._temperature_values: List[float] = []
        self._biomass_values: List[float] = []
        self.load_data()

    def load_data(self) -> None:
        """Loads and parses the respiration data from the JSON file."""
        print(
            f"Attempting to load shrimp respiration data from: "
            f"{self.data_path}"
        )
        json_data = load_json_data(self.data_path)

        metadata: Dict[str, Any] = json_data.get('metadata', {})
        if not metadata:
            raise ValueError("Metadata missing or invalid in JSON")

        self._salinity_values = sorted([
            float(str(s).replace('%', ''))
            for s in metadata.get('salinity_values', [])
        ])
        self._temperature_values = sorted([
            float(str(t).replace('°C', ''))
            for t in metadata.get('temperature_values', [])
        ])
        self._biomass_values = sorted([
            float(str(b).replace('g', ''))
            for b in metadata.get('shrimp_biomass', [])
        ])

        if not all([
            self._salinity_values,
            self._temperature_values,
            self._biomass_values
        ]):
            raise ValueError(
                "Metadata arrays (salinity, temperature, biomass) "
                "cannot be empty"
            )

        self._respiration_data = json_data.get('data', {})
        if not self._respiration_data:
            raise ValueError(
                "Data grid missing or invalid in JSON"
            )

        print("Shrimp respiration data loaded successfully.")

    def _find_bounds(
        self, value: float, sorted_values: List[float]
    ) -> Tuple[float, float]:
        """Finds the lower and upper bounds for a value in a sorted list."""
        if not sorted_values:
            raise ValueError("Cannot find bounds in empty list")

        low = sorted_values[0]
        high = sorted_values[-1]

        for val in sorted_values:
            if val <= value:
                low = val
            if val >= value:
                high = val
                break

        return low, high

    def _get_value_from_data(
        self, sal_key: str, temp_key: str, weight_key: str
    ) -> float:
        """
        Safely retrieves a value from the nested respiration data dictionary.
        """
        try:
            val = self._respiration_data.get(sal_key, {}).get(temp_key, {}) \
                .get(weight_key)
            if val is None:
                raise ValueError(
                    (
                        f"Key path not found: {sal_key} -> {temp_key} -> "
                        f"{weight_key}"
                    )
                )
            return float(val)
        except (TypeError, ValueError) as e:
            raise ValueError(
                f"Could not convert value at {sal_key}.{temp_key}."
                f"{weight_key}: {e}"
            ) from e

    def _get_cube_values(
        self,
        salinity_low_key: str,
        salinity_high_key: str,
        temp_low_key: str,
        temp_high_key: str,
        weight_low_key: str,
        weight_high_key: str
    ) -> List[float]:
        """Retrieves the 8 corner values for the interpolation cube."""
        corners = [
            (salinity_low_key, temp_low_key, weight_low_key),
            (salinity_low_key, temp_low_key, weight_high_key),
            (salinity_low_key, temp_high_key, weight_low_key),
            (salinity_low_key, temp_high_key, weight_high_key),
            (salinity_high_key, temp_low_key, weight_low_key),
            (salinity_high_key, temp_low_key, weight_high_key),
            (salinity_high_key, temp_high_key, weight_low_key),
            (salinity_high_key, temp_high_key, weight_high_key)
        ]
        values = [
            self._get_value_from_data(sal, temp, weight)
            for sal, temp, weight in corners
        ]
        return values

    def _trilinear_interpolation(
        self,
        corner_values: List[float],
        s: float,
        t: float,
        w: float
    ) -> float:
        """
        Performs trilinear interpolation using the corner values and
        interpolation factors.
        """
        r000, r001, r010, r011, r100, r101, r110, r111 = corner_values
        r00 = r000 + (r001 - r000) * w
        r01 = r010 + (r011 - r010) * w
        r10 = r100 + (r101 - r100) * w
        r11 = r110 + (r111 - r110) * w
        r0 = r00 + (r01 - r00) * t
        r1 = r10 + (r11 - r10) * t
        return r0 + (r1 - r0) * s

    def get_respiration_rate(
        self, salinity: float, temperature: float, shrimp_weight: float
    ) -> float:
        """
        Calculates the respiration rate (mg O₂/g/h) using trilinear
        interpolation.

        Args:
            salinity: Water salinity in ppt.
            temperature: Water temperature in °C.
            shrimp_weight: Average shrimp weight in grams.

        Returns:
            The estimated respiration rate in mg O₂/g/h.

        Raises:
            ValueError: If data is not loaded or interpolation fails.
        """
        if not all([
            self._salinity_values,
            self._temperature_values,
            self._biomass_values
        ]):
            raise ValueError(
                "Respiration data not loaded. Call load_data() first."
            )

        # Clamp input values
        clamped_salinity = max(
            self._salinity_values[0],
            min(salinity, self._salinity_values[-1])
        )
        clamped_temperature = max(
            self._temperature_values[0],
            min(temperature, self._temperature_values[-1])
        )
        clamped_weight = max(
            self._biomass_values[0],
            min(shrimp_weight, self._biomass_values[-1])
        )

        # Find bounds
        salinity_low, salinity_high = self._find_bounds(
            clamped_salinity, self._salinity_values
        )
        temp_low, temp_high = self._find_bounds(
            clamped_temperature, self._temperature_values
        )
        weight_low, weight_high = self._find_bounds(
            clamped_weight, self._biomass_values
        )

        # Convert to JSON keys
        salinity_low_key = f'{int(salinity_low)}%'
        salinity_high_key = f'{int(salinity_high)}%'
        temp_low_key = f'{int(temp_low)}°C'
        temp_high_key = f'{int(temp_high)}°C'
        weight_low_key = f'{int(weight_low)}g'
        weight_high_key = f'{int(weight_high)}g'

        # Get corner values
        corner_values = self._get_cube_values(
            salinity_low_key, salinity_high_key, temp_low_key, temp_high_key,
            weight_low_key, weight_high_key
        )

        # Calculate interpolation factors
        sal_diff = salinity_high - salinity_low
        temp_diff = temp_high - temp_low
        weight_diff = weight_high - weight_low
        s = 0.0 if sal_diff == 0 else (
            clamped_salinity - salinity_low
        ) / sal_diff
        t = 0.0 if temp_diff == 0 else (
            clamped_temperature - temp_low
        ) / temp_diff
        w = 0.0 if weight_diff == 0 else (
            clamped_weight - weight_low
        ) / weight_diff

        # Perform interpolation
        return self._trilinear_interpolation(corner_values, s, t, w)


if __name__ == '__main__':
    try:
        calculator = ShrimpRespirationCalculator()
        SAL1, TEMP1, WEIGHT1 = 20.0, 28.0, 12.0
        rate1 = calculator.get_respiration_rate(SAL1, TEMP1, WEIGHT1)
        print(
            f"Respiration Rate at S={SAL1}‰, T={TEMP1}°C, W={WEIGHT1}g: "
            f"{rate1:.4f} mg O₂/g/h"
        )

        SAL2, TEMP2, WEIGHT2 = 25.0, 30.0, 15.0
        rate2 = calculator.get_respiration_rate(SAL2, TEMP2, WEIGHT2)
        print(
            f"Respiration Rate at S={SAL2}‰, T={TEMP2}°C, W={WEIGHT2}g: "
            f"{rate2:.4f} mg O₂/g/h"
        )

        SAL3, TEMP3, WEIGHT3 = 50.0, 5.0, 1.0
        rate3 = calculator.get_respiration_rate(SAL3, TEMP3, WEIGHT3)
        print(
            f"Respiration Rate at S={SAL3}‰, T={TEMP3}°C, W={WEIGHT3}g "
            f"(clamped): {rate3:.4f} mg O₂/g/h"
        )
    except (FileNotFoundError, ValueError, TypeError) as exc:
        print(f"An error occurred: {exc}")

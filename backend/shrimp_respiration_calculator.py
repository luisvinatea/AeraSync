import json
import math
import os
import sys
from typing import List, Dict, Optional, Any

class ShrimpRespirationCalculator:
    """
    Calculates shrimp respiration rate based on loaded data using trilinear interpolation.
    Loads data from a JSON file structured similarly to the Dart version's input.
    """

    def __init__(self, data_path: str = None):
        """
        Initializes the calculator with the path to the JSON data file.
        If no data_path is provided, it will be computed dynamically relative to the script location.

        Args:
            data_path (str, optional): The path to the JSON data file. If None, computed dynamically.
        """
        # Dynamically compute the default data path if not provided
        if data_path is None:
            # Get the directory of the current script (backend/shrimp_respiration_calculator.py)
            script_dir = os.path.dirname(os.path.abspath(__file__))
            # Navigate to the repo root (one level up from backend/)
            repo_root = os.path.dirname(script_dir)
            # Define the path to assets/data/
            self.data_path = os.path.join(repo_root, "assets", "data", "shrimp_respiration_salinity_temperature_weight.json")
        else:
            self.data_path = data_path

        # Verify that the data file exists
        if not os.path.exists(self.data_path):
            raise FileNotFoundError(f"Shrimp respiration data file not found at: {self.data_path}")

        self._respiration_data: Optional[Dict[str, Any]] = None
        self._salinity_values: List[float] = []
        self._temperature_values: List[float] = []
        self._biomass_values: List[float] = []
        self.load_data()  # Load data immediately on initialization

    def load_data(self) -> None:
        """Loads and parses the respiration data from the JSON file."""
        print(f"Attempting to load shrimp respiration data from: {self.data_path}")
        try:
            with open(self.data_path, 'r', encoding='utf-8') as f:
                json_data: Dict[str, Any] = json.load(f)

            # Extract metadata
            metadata = json_data.get('metadata')
            if not isinstance(metadata, dict):
                raise ValueError("Metadata missing or invalid in JSON")

            # Parse and store the discrete values for each dimension, ensuring they are sorted
            self._salinity_values = sorted([
                float(str(s).replace('%', '')) for s in metadata.get('salinity_values', [])
            ])
            self._temperature_values = sorted([
                float(str(t).replace('°C', '')) for t in metadata.get('temperature_values', [])
            ])
            self._biomass_values = sorted([
                float(str(b).replace('g', '')) for b in metadata.get('shrimp_biomass', [])
            ])

            if not all([self._salinity_values, self._temperature_values, self._biomass_values]):
                raise ValueError("Metadata arrays (salinity, temperature, biomass) cannot be empty")

            # Store the main data grid
            self._respiration_data = json_data.get('data')
            if not isinstance(self._respiration_data, dict):
                raise ValueError("Data grid missing or invalid in JSON")

            print("Shrimp respiration data loaded successfully.")

        except FileNotFoundError:
            print(f"Error: Data file not found at {self.data_path}")
            raise Exception(f"Data file not found at {self.data_path}")
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON format in data file: {self.data_path}")
            raise Exception(f"Invalid JSON format in data file: {self.data_path}")
        except (KeyError, ValueError, TypeError) as e:
            print(f"Error parsing JSON data or metadata: {e}")
            raise Exception(f"Error parsing JSON data or metadata: {e}")
        except Exception as e:
            print(f"An unexpected error occurred during data loading: {e}")
            raise  # Re-raise other exceptions

    def _find_bounds(self, value: float, sorted_values: List[float]) -> tuple[float, float]:
        """Finds the lower and upper bounds for a value in a sorted list."""
        if not sorted_values:
            raise ValueError("Cannot find bounds in empty list")

        # Simple linear search for bounds (similar to Dart's lastWhere/firstWhere logic)
        low = sorted_values[0]
        high = sorted_values[-1]

        for i in range(len(sorted_values)):
            if sorted_values[i] <= value:
                low = sorted_values[i]
            if sorted_values[i] >= value:
                high = sorted_values[i]
                break  # Found the upper bound

        return low, high

    def _get_value_from_data(self, sal_key: str, temp_key: str, weight_key: str) -> Optional[float]:
        """Safely retrieves a value from the nested respiration data dictionary."""
        try:
            val = None
            if self._respiration_data:
                val = self._respiration_data.get(sal_key, {}).get(temp_key, {}).get(weight_key)
            if val is None:
                print(f"Warning: Key path not found: {sal_key} -> {temp_key} -> {weight_key}")
                return None
            # Ensure the value is treated as a number (float)
            return float(val)
        except (TypeError, ValueError) as e:
            print(f"Warning: Could not convert value to float at {sal_key}.{temp_key}.{weight_key}: {e}")
            return None

    def get_respiration_rate(self, salinity: float, temperature: float, shrimp_weight: float) -> float:
        """
        Calculates the respiration rate (mg O₂/g/h) for the given conditions
        using trilinear interpolation based on the loaded data.

        Args:
            salinity (float): Water salinity in ppt (parts per thousand).
            temperature (float): Water temperature in °C.
            shrimp_weight (float): Average shrimp weight in grams.

        Returns:
            float: The estimated respiration rate in mg O₂/g/h.

        Raises:
            Exception: If data is not loaded or interpolation fails.
        """
        if self._respiration_data is None or not all([self._salinity_values, self._temperature_values, self._biomass_values]):
            raise Exception('Respiration data not loaded or invalid. Call load_data() first.')

        # 1. Clamp input values to the range covered by the data
        clamped_salinity = max(self._salinity_values[0], min(salinity, self._salinity_values[-1]))
        clamped_temperature = max(self._temperature_values[0], min(temperature, self._temperature_values[-1]))
        clamped_weight = max(self._biomass_values[0], min(shrimp_weight, self._biomass_values[-1]))

        # 2. Find the surrounding grid points (lower and upper bounds)
        salinity_low, salinity_high = self._find_bounds(clamped_salinity, self._salinity_values)
        temp_low, temp_high = self._find_bounds(clamped_temperature, self._temperature_values)
        weight_low, weight_high = self._find_bounds(clamped_weight, self._biomass_values)

        # 3. Convert boundary values to the string keys used in the JSON data
        salinity_low_key = f'{int(salinity_low)}%'
        salinity_high_key = f'{int(salinity_high)}%'
        temp_low_key = f'{int(temp_low)}°C'
        temp_high_key = f'{int(temp_high)}°C'
        weight_low_key = f'{int(weight_low)}g'
        weight_high_key = f'{int(weight_high)}g'

        # 4. Retrieve the respiration rate values at the 8 corners of the interpolation cube.
        r000 = self._get_value_from_data(salinity_low_key, temp_low_key, weight_low_key)
        r001 = self._get_value_from_data(salinity_low_key, temp_low_key, weight_high_key)
        r010 = self._get_value_from_data(salinity_low_key, temp_high_key, weight_low_key)
        r011 = self._get_value_from_data(salinity_low_key, temp_high_key, weight_high_key)
        r100 = self._get_value_from_data(salinity_high_key, temp_low_key, weight_low_key)
        r101 = self._get_value_from_data(salinity_high_key, temp_low_key, weight_high_key)
        r110 = self._get_value_from_data(salinity_high_key, temp_high_key, weight_low_key)
        r111 = self._get_value_from_data(salinity_high_key, temp_high_key, weight_high_key)

        # Check if any corner value could not be retrieved
        corner_values = [r000, r001, r010, r011, r100, r101, r110, r111]
        if any(r is None for r in corner_values):
            raise Exception(f"Missing respiration data for interpolation corner points near S={salinity}, T={temperature}, W={shrimp_weight}. Check JSON structure and keys.")

        # Cast checked values to float (mypy compatibility)
        r000, r001, r010, r011, r100, r101, r110, r111 = map(float, (val for val in corner_values if val is not None))

        # 5. Calculate interpolation factors (s, t, w) - relative position within the cube [0, 1]
        sal_diff = salinity_high - salinity_low
        temp_diff = temp_high - temp_low
        weight_diff = weight_high - weight_low

        # Avoid division by zero if bounds are the same (input matches a grid point)
        s = 0.0 if sal_diff == 0 else (clamped_salinity - salinity_low) / sal_diff
        t = 0.0 if temp_diff == 0 else (clamped_temperature - temp_low) / temp_diff
        w = 0.0 if weight_diff == 0 else (clamped_weight - weight_low) / weight_diff

        # 6. Perform trilinear interpolation
        #    Interpolate along weight axis (w)
        r00 = r000 + (r001 - r000) * w
        r01 = r010 + (r011 - r010) * w
        r10 = r100 + (r101 - r100) * w
        r11 = r110 + (r111 - r110) * w

        #    Interpolate along temperature axis (t)
        r0 = r00 + (r01 - r00) * t
        r1 = r10 + (r11 - r10) * t

        #    Interpolate along salinity axis (s)
        respiration_rate = r0 + (r1 - r0) * s

        return respiration_rate

if __name__ == '__main__':
    try:
        calculator = ShrimpRespirationCalculator()

        # Test case 1: Inside the data range
        sal = 20.0
        temp = 28.0
        weight = 12.0
        rate1 = calculator.get_respiration_rate(sal, temp, weight)
        print(f"Respiration Rate at S={sal}‰, T={temp}°C, W={weight}g: {rate1:.4f} mg O₂/g/h")

        # Test case 2: Values matching grid points
        sal = 25.0
        temp = 30.0
        weight = 15.0
        rate2 = calculator.get_respiration_rate(sal, temp, weight)
        print(f"Respiration Rate at S={sal}‰, T={temp}°C, W={weight}g: {rate2:.4f} mg O₂/g/h")

        # Test case 3: Values outside the range (will be clamped)
        sal = 50.0
        temp = 5.0
        weight = 1.0
        rate3 = calculator.get_respiration_rate(sal, temp, weight)
        print(f"Respiration Rate at S={sal}‰, T={temp}°C, W={weight}g (clamped): {rate3:.4f} mg O₂/g/h")

    except Exception as e:
        print(f"An error occurred: {e}")
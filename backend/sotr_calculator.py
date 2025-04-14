from abc import ABC, abstractmethod
import json
import math
import numpy as np
from functools import lru_cache
import os
import sys
from typing import Dict, Any

class SaturationCalculator(ABC):
    """Abstract base class for oxygen saturation calculations."""
    def __init__(self, data_path: str = None):
        """
        Initializes the calculator with the path to the JSON data file.
        If no data_path is provided, it will be computed dynamically relative to the script location.

        Args:
            data_path (str, optional): The path to the JSON data file. If None, computed dynamically.
        """
        # Dynamically compute the default data path if not provided
        if data_path is None:
            # Get the directory of the current script (backend/sotr_calculator.py)
            script_dir = os.path.dirname(os.path.abspath(__file__))
            # Navigate to the repo root (one level up from backend/)
            repo_root = os.path.dirname(script_dir)
            # Define the path to assets/data/
            self.data_path = os.path.join(repo_root, "assets", "data", "oxygen_saturation.json")
        else:
            self.data_path = data_path

        # Verify that the data file exists
        if not os.path.exists(self.data_path):
            raise FileNotFoundError(f"Oxygen saturation data file not found at: {self.data_path}")

        self.matrix = None
        self.metadata = None
        self.temp_step = 1.0  # Default
        self.sal_step = 5.0   # Default
        self.unit = "mg/L"    # Default
        self.load_data()      # Load data upon initialization

    def load_data(self):
        """Load oxygen saturation data from a JSON file into a NumPy array."""
        print(f"Attempting to load data from: {self.data_path}")
        try:
            with open(self.data_path, 'r', encoding='utf-8') as f:  # Specify encoding
                data = json.load(f)
                self.metadata = data.get("metadata")
                if not self.metadata:
                    raise ValueError("Metadata missing in JSON file")

                # Validate metadata structure before accessing keys
                temp_range = self.metadata.get("temperature_range", {})
                sal_range = self.metadata.get("salinity_range", {})

                self.temp_step = float(temp_range.get("step", 1.0))
                self.sal_step = float(sal_range.get("step", 5.0))
                self.unit = self.metadata.get("unit", "mg/L")

                if "data" not in data:
                    raise ValueError("'data' field missing in JSON file")

                # Use NumPy for potential performance benefits, ensure float type
                self.matrix = np.array(data["data"], dtype=np.float32)
                print(f"Data loaded successfully. Matrix shape: {self.matrix.shape}")

        except FileNotFoundError:
            print(f"Error: Data file not found at {self.data_path}")
            raise Exception(f"Data file not found at {self.data_path}")
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON format in data file: {self.data_path}")
            raise Exception(f"Invalid JSON format in data file: {self.data_path}")
        except KeyError as e:
            print(f"Error: Missing expected key in JSON metadata: {e}")
            raise Exception(f"Missing expected key in JSON metadata: {e}")
        except Exception as e:
            print(f"An unexpected error occurred during data loading: {e}")
            raise  # Re-raise the exception after logging

    @lru_cache(maxsize=1000)  # Cache results for faster subsequent lookups
    def get_o2_saturation(self, temperature: float, salinity: float) -> float:
        """
        Get oxygen saturation (mg/L) for given temperature (°C) and salinity (‰).
        Uses linear interpolation for temperature based on the loaded data grid.

        Args:
            temperature (float): Water temperature in °C (0 to 40).
            salinity (float): Salinity in parts per thousand (‰) (0 to 40).

        Returns:
            float: Oxygen saturation in mg/L.

        Raises:
            ValueError: If temperature or salinity is out of range.
            Exception: If data matrix is not loaded.
        """
        if self.matrix is None:
            raise Exception("Saturation data matrix not loaded. Call load_data() first.")

        if not (0 <= temperature <= 40 and 0 <= salinity <= 40):
            raise ValueError("Temperature and salinity must be between 0 and 40")

        # --- Interpolation Logic ---
        # Temperature bounds (using floor/ceil for linear interpolation)
        temp_lower_idx = math.floor(temperature)
        temp_upper_idx = math.ceil(temperature)

        # Handle edge case: If temperature is an integer, no interpolation needed
        if temp_lower_idx == temp_upper_idx:
            temp_fraction = 0.0
        else:
            temp_fraction = (temperature - temp_lower_idx)  # / (temp_upper_idx - temp_lower_idx) which is 1

        # Salinity index (direct lookup based on steps)
        # Ensure index stays within bounds [0, num_salinity_steps - 1]
        max_sal_idx = self.matrix.shape[1] - 1
        sal_idx = min(max_sal_idx, int(salinity / self.sal_step))

        # Ensure temperature indices are within bounds [0, num_temp_steps - 1]
        max_temp_idx = self.matrix.shape[0] - 1
        temp_lower_idx = min(max_temp_idx, temp_lower_idx)
        # Handle edge case where temp_upper might exceed 40
        temp_upper_idx = min(max_temp_idx, temp_upper_idx)

        # Get saturation values at the lower and upper temperature bounds for the given salinity index
        try:
            sat_lower = float(self.matrix[temp_lower_idx, sal_idx])
            # If upper temp index is same as lower, or exceeds bounds, use lower value
            sat_upper = float(self.matrix[temp_upper_idx, sal_idx]) if temp_upper_idx != temp_lower_idx else sat_lower

        except IndexError:
            raise IndexError(f"Index out of bounds when accessing matrix. T_low={temp_lower_idx}, T_up={temp_upper_idx}, Sal_idx={sal_idx}. Matrix shape={self.matrix.shape}")

        # Linear interpolation along the temperature axis
        interpolated_saturation = sat_lower + (sat_upper - sat_lower) * temp_fraction
        return interpolated_saturation

    @abstractmethod
    def calculate_metrics(self, temperature: float, salinity: float, hp: float, volume: float, t10: float, t70: float, kwh_price: float, aerator_id: str) -> Dict[str, Any]:
        """Calculates key performance metrics for an aerator."""
        pass

class ShrimpPondCalculator(SaturationCalculator):
    """Concrete implementation for calculating shrimp pond aerator metrics."""

    BRAND_NORMALIZATION = {
        "pentair": "Pentair", "beraqua": "Beraqua", "maof madam": "Maof Madam",
        "maofmadam": "Maof Madam", "cosumisa": "Cosumisa", "pioneer": "Pioneer",
        "ecuasino": "Ecuasino", "diva": "Diva", "gps": "GPS", "wangfa": "WangFa",
        "akva": "AKVA", "xylem": "Xylem", "newterra": "Newterra", "tsurumi": "TSURUMI",
        "oxyguard": "OxyGuard", "linn": "LINN", "hunan": "Hunan", "sagar": "Sagar",
        "hcp": "HCP", "yiyuan": "Yiyuan", "generic": "Generic",
        "pentairr": "Pentair", "beraqua1": "Beraqua", "maof-madam": "Maof Madam",
        "cosumissa": "Cosumisa", "pionner": "Pioneer", "ecuacino": "Ecuasino",
        "divva": "Diva", "wang fa": "WangFa", "oxy guard": "OxyGuard", "lin": "LINN",
        "sagr": "Sagar", "hcpp": "HCP", "yiyuan1": "Yiyuan",
    }

    def __init__(self, data_path: str = None):
        super().__init__(data_path)

    def normalize_brand(self, brand: str) -> str:
        """
        Normalize the brand name to a standard format.

        Args:
            brand (str): The brand name to normalize.

        Returns:
            str: The normalized brand name, or "Generic" if the input is empty or None.
        """
        if not brand or not brand.strip():  # Check for None or empty/whitespace string
            return "Generic"
        brand_lower = brand.lower().strip()
        # Return normalized name or the original (title-cased) if not found
        return self.BRAND_NORMALIZATION.get(brand_lower, brand.title())

    def calculate_metrics(self, temperature: float, salinity: float, hp: float, volume: float, t10: float, t70: float, kwh_price: float, aerator_id: str) -> Dict[str, Any]:
        """
        Calculate performance metrics for an aerator in a shrimp pond.
        Note: This method is not used by aerator_comparer.py, which only needs get_o2_saturation.
        Retained for potential future use or standalone calculations.

        Args:
            temperature (float): Water temperature in °C.
            salinity (float): Salinity in ‰.
            hp (float): Horsepower of the aerator.
            volume (float): Pond volume in m³.
            t10 (float): Time to reach 10% saturation deficit (minutes). - Reference only
            t70 (float): Time to reach 70% saturation deficit (minutes).
            kwh_price (float): Electricity cost in e.g., USD/kWh.
            aerator_id (str): Identifier for the aerator (e.g., "Pentair Paddlewheel").

        Returns:
            dict: A dictionary containing the calculated metrics.

        Raises:
            ValueError: If t70 is not positive or other calculation issues occur.
        """
        # --- Input Processing & Normalization ---
        try:
            # Split aerator_id into brand and type, handle cases with no type
            parts = aerator_id.split(" ", 1)
            brand = parts[0] if parts else "Generic"
            aerator_type = parts[1] if len(parts) > 1 else "Unknown"
        except Exception:  # Catch potential errors if aerator_id is not a string
            brand = "Generic"
            aerator_type = "Unknown"

        normalized_brand = self.normalize_brand(brand)
        normalized_aerator_id = f"{normalized_brand} {aerator_type}".strip()  # Ensure no trailing space if type is Unknown

        # --- Intermediate Calculations ---
        power_kw = round(hp * 0.746, 2)  # Use round() for standard rounding
        cs = self.get_o2_saturation(temperature, salinity)  # mg/L at T, Sal
        cs20 = self.get_o2_saturation(20, salinity)         # mg/L at 20°C, Sal
        cs20_kg_m3 = cs20 * 0.001                           # kg/m³ at 20°C, Sal

        # --- KLa Calculation ---
        # KLaT = -ln(1 - fraction_deficit_covered) / time_hours
        # Using T70 means fraction covered is 0.7
        if t70 <= 0:
            raise ValueError("T70 must be positive to calculate KLa.")
        t70_hours = t70 / 60.0
        # Using math.log (natural logarithm)
        kla_t = -math.log(1 - 0.7) / t70_hours  # Correct formula (h⁻¹)

        # KLa at standard temperature 20°C (h⁻¹)
        theta = 1.024  # Standard temperature correction factor
        kla20 = kla_t * (theta ** (20.0 - temperature))

        # --- Core Metrics Calculation ---
        # SOTR (Standard Oxygen Transfer Rate) in kg O₂/h
        # Formula: SOTR = KLa20 * Cs20(kg/m³) * Volume(m³)
        sotr = round(kla20 * cs20_kg_m3 * volume, 2)

        # SAE (Standard Aeration Efficiency) in kg O₂/kWh
        sae = round(sotr / power_kw, 2) if power_kw > 0 else 0.0

        # Cost per kg O2 (e.g., USD/kg O₂)
        cost_per_kg = round(kwh_price / sae, 2) if sae > 0 else float('inf')

        # Annual Energy Cost (assuming 24/7 operation)
        annual_energy_cost = round(power_kw * kwh_price * 24 * 365, 2)

        # --- Return Results ---
        return {
            "Pond Volume (m³)": volume,
            "Cs (mg/L)": round(cs, 2),
            "KlaT (h⁻¹)": round(kla_t, 2),
            "Kla20 (h⁻¹)": round(kla20, 2),
            "SOTR (kg O₂/h)": sotr,
            "SAE (kg O₂/kWh)": sae,
            "Cost per kg O₂ (USD/kg O₂)": cost_per_kg,  # Renamed key for clarity
            "Power (kW)": power_kw,
            "Annual Energy Cost (USD/year)": annual_energy_cost,
            "Aerator ID": normalized_aerator_id  # Use the normalized ID
        }

    def get_ideal_volume(self, hp: float) -> float:
        """
        Get the ideal pond volume (m³) for a given horsepower based on simple rules.

        Args:
            hp (float): Horsepower of the aerator.

        Returns:
            float: Ideal pond volume in m³.
        """
        if hp <= 0: return 0  # Handle non-positive HP
        if hp == 2: return 40.0
        if hp == 3: return 70.0
        # General rule for other HP values
        return round(hp * 25.0, 0)  # Return as float

    def get_ideal_hp(self, volume: float) -> float:
        """
        Get the ideal horsepower for a given pond volume (m³) based on simple rules.

        Args:
            volume (float): Pond volume in m³.

        Returns:
            float: Ideal horsepower.
        """
        if volume <= 0: return 0.0  # Handle non-positive volume
        if volume <= 40: return 2.0
        if volume <= 70: return 3.0
        # General rule, ensure minimum HP (e.g., 2) and return as float
        return max(2.0, round(volume / 25.0, 0))
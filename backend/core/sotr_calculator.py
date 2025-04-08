from abc import ABC, abstractmethod
import json
import math
import numpy as np # type: ignore
from functools import lru_cache

class SaturationCalculator(ABC):
    def __init__(self, data_path):
        self.data_path = data_path
        self.matrix = None
        self.temp_step = None
        self.sal_step = None
        self.unit = None
        self.load_data()
        
    def load_data(self):
        """Load oxygen saturation data from a JSON file into a NumPy array."""
        try:
            with open(self.data_path, 'r') as f:
                data = json.load(f)
                self.metadata = data["metadata"]
                self.matrix = np.array(data["data"], dtype=np.float32)  # Use NumPy for faster lookups
                self.temp_step = self.metadata["temperature_range"]["step"]
                self.sal_step = self.metadata["salinity_range"]["step"]
                self.unit = self.metadata["unit"]
        except FileNotFoundError:
            raise Exception(f"Data file not found at {self.data_path}")
        except json.JSONDecodeError:
            raise Exception("Invalid JSON format in data file")

    @lru_cache(maxsize=1000)
    def get_o2_saturation(self, temperature, salinity):
        """
        Get oxygen saturation (mg/L) for given temperature (°C) and salinity (‰).

        Args:
            temperature (float): Water temperature in °C (0 to 40).
            salinity (float): Salinity in parts per thousand (‰) (0 to 40).

        Returns:
            float: Oxygen saturation in mg/L.

        Raises:
            ValueError: If temperature or salinity is out of range.
        """
        if not (0 <= temperature <= 40 and 0 <= salinity <= 40):
            raise ValueError("Temperature and salinity must be between 0 and 40")

        # Linear interpolation for temperature
        temp_lower = math.floor(temperature)
        temp_upper = math.ceil(temperature)
        temp_fraction = temperature - temp_lower

        sal_idx = int(salinity / self.sal_step)

        # Get saturation values at the lower and upper temperature bounds
        sat_lower = self.matrix[temp_lower, sal_idx]
        sat_upper = self.matrix[temp_upper, sal_idx] if temp_upper <= 40 else sat_lower

        # Interpolate
        return sat_lower + (sat_upper - sat_lower) * temp_fraction

    @abstractmethod
    def calculate_sotr(self, temperature, salinity, *args, **kwargs):
        pass

class ShrimpPondCalculator(SaturationCalculator):
    SOTR_PER_HP = {
        "Generic Paddlewheel": 1.8
    }

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

    def __init__(self, data_path):
        super().__init__(data_path)
    
    def normalize_brand(self, brand):
        """
        Normalize the brand name to a standard format.

        Args:
            brand (str): The brand name to normalize.

        Returns:
            str: The normalized brand name, or "Generic" if the input is empty.
        """
        if not brand or brand.strip() == "":
            return "Generic"
        brand_lower = brand.lower().strip()
        return self.BRAND_NORMALIZATION.get(brand_lower, brand)

    def calculate_sotr(self, temperature, salinity, volume, efficiency=0.9):
        """
        Calculate the Standard Oxygen Transfer Rate (SOTR) for a pond.

        Args:
            temperature (float): Water temperature in °C.
            salinity (float): Salinity in ‰.
            volume (float): Pond volume in m³.
            efficiency (float, optional): Efficiency factor (default: 0.9).

        Returns:
            float: SOTR in kg O₂/h, truncated to 2 decimals.
        """
        saturation = self.get_o2_saturation(temperature, salinity)
        saturation_kg_m3 = saturation * 0.001
        return int(saturation_kg_m3 * volume * efficiency * 100) / 100

    def calculate_metrics(self, temperature, salinity, hp, volume, t10, t70, kwh_price, aerator_id):
        """
        Calculate performance metrics for an aerator in a shrimp pond.

        Args:
            temperature (float): Water temperature in °C.
            salinity (float): Salinity in ‰.
            hp (float): Horsepower of the aerator.
            volume (float): Pond volume in m³.
            t10 (float): Time to reach 10% oxygen saturation in minutes.
            t70 (float): Time to reach 70% oxygen saturation in minutes.
            kwh_price (float): Electricity cost in USD/kWh.
            aerator_id (str): Identifier for the aerator (e.g., "Pentair Paddlewheel").

        Returns:
            dict: A dictionary containing the calculated metrics.

        Raises:
            ValueError: If t70 equals t10, causing a division by zero.
        """
        # Split aerator_id into brand and type
        try:
            brand, aerator_type = aerator_id.split(" ", 1)
        except ValueError:
            brand = aerator_id
            aerator_type = "Unknown"

        normalized_brand = self.normalize_brand(brand)
        normalized_aerator_id = f"{normalized_brand} {aerator_type}"

        power_kw = int(hp * 0.746 * 100) / 100  # Truncate to 2 decimals
        cs = self.get_o2_saturation(temperature, salinity)
        cs20 = self.get_o2_saturation(20, salinity)
        cs20_kg_m3 = cs20 * 0.001

        # Prevent division by zero
        if t70 == t10:
            raise ValueError("T70 must be greater than T10 to calculate KlaT")

        kla_t = 1.0 / ((t70 - t10) / 60)  # No 1.1 factor, keep t10/t70 as fractions
        kla20 = kla_t * (1.024 ** (20 - temperature))

        sotr = int(kla20 * cs20_kg_m3 * volume * 100) / 100  # Truncate to 2 decimals
        sae = sotr / power_kw if power_kw > 0 else 0
        sae = int(sae * 100) / 100  # Truncate to 2 decimals

        # Calculate annual energy cost
        annual_energy_cost = power_kw * kwh_price * 24 * 365  # Annual cost in USD
        annual_energy_cost = int(annual_energy_cost * 100) / 100  # Truncate to 2 decimals

        return {
            "Pond Volume (m³)": volume,
            "Cs (mg/L)": cs,
            "KlaT (h⁻¹)": kla_t,
            "Kla20 (h⁻¹)": kla20,
            "SOTR (kg O₂/h)": sotr,
            "SAE (kg O₂/kWh)": sae,
            "Annual Energy Cost (USD/year)": annual_energy_cost,
            "Power (kW)": power_kw,
            "Aerator ID": normalized_aerator_id
        }

    def get_ideal_volume(self, hp):
        """
        Get the ideal pond volume for a given horsepower.

        Args:
            hp (float): Horsepower of the aerator.

        Returns:
            float: Ideal pond volume in m³.
        """
        if hp == 2:
            return 40
        elif hp == 3:
            return 70
        else:
            return hp * 25

    def get_ideal_hp(self, volume):
        """
        Get the ideal horsepower for a given pond volume.

        Args:
            volume (float): Pond volume in m³.

        Returns:
            float: Ideal horsepower.
        """
        if volume <= 40:
            return 2
        elif volume <= 70:
            return 3
        else:
            return max(2, int(volume / 25))
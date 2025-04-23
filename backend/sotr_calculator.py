"""Oxygen saturation and shrimp pond aerator performance calculations."""

import math
import os
from abc import ABC, abstractmethod
from functools import lru_cache
from typing import Any, Dict, Optional

import numpy as np
from pydantic import BaseModel, Field

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
        if data_path is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            repo_root = os.path.dirname(script_dir)
            self.data_path = os.path.join(
                repo_root, "assets", "data", "o2_temp_sal_100_sat.json"
            )
        else:
            self.data_path = data_path

        if not os.path.exists(self.data_path):
            raise FileNotFoundError(
                f"Oxygen saturation data file not found at: {self.data_path}"
            )

        self.matrix = None
        self.metadata = None
        self.temp_step = 1.0
        self.sal_step = 5.0
        self.unit = "mg/L"
        self.load_data()

    def load_data(self):
        """Load oxygen saturation data from a JSON file into a NumPy array."""
        print(f"Attempting to load data from: {self.data_path}")
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

        self.matrix = np.array(data["data"], dtype=np.float32)
        print(f"Data loaded successfully. Matrix shape: {self.matrix.shape}")

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
        if self.matrix is None:
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

        max_sal_idx = self.matrix.shape[1] - 1
        sal_idx = min(max_sal_idx, int(salinity / self.sal_step))

        max_temp_idx = self.matrix.shape[0] - 1
        temp_lower_idx = min(max_temp_idx, temp_lower_idx)
        temp_upper_idx = min(max_temp_idx, temp_upper_idx)

        try:
            sat_lower = float(self.matrix[temp_lower_idx, sal_idx])
            sat_upper = (
                float(self.matrix[temp_upper_idx, sal_idx])
                if temp_upper_idx != temp_lower_idx
                else sat_lower
            )
        except IndexError as exc:
            raise IndexError(
                f"Index out of bounds: T_low={temp_lower_idx}, "
                f"T_up={temp_upper_idx}, "
                f"Sal_idx={sal_idx}. Matrix shape={self.matrix.shape}"
            ) from exc

        return sat_lower + (sat_upper - sat_lower) * temp_fraction

    @abstractmethod
    def calculate_metrics(self, params: Any) -> Dict[str, Any]:
        """Calculates key performance metrics for an aerator."""


class AeratorMetricsInput(BaseModel):
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

    BRAND_NORMALIZATION = {
        "pentair": "Pentair",
        "beraqua": "Beraqua",
        "maof madam": "Maof Madam",
        "maofmadam": "Maof Madam",
        "cosumisa": "Cosumisa",
        "pioneer": "Pioneer",
        "ecuasino": "Ecuasino",
        "diva": "Diva",
        "gps": "GPS",
        "wangfa": "WangFa",
        "akva": "AKVA",
        "xylem": "Xylem",
        "newterra": "Newterra",
        "tsurumi": "TSURUMI",
        "oxyguard": "OxyGuard",
        "linn": "LINN",
        "hunan": "Hunan",
        "sagar": "Sagar",
        "hcp": "HCP",
        "yiyuan": "Yiyuan",
        "generic": "Generic",
        "pentairr": "Pentair",
        "beraqua1": "Beraqua",
        "maof-madam": "Maof Madam",
        "cosumissa": "Cosumisa",
        "pionner": "Pioneer",
        "ecuacino": "Ecuasino",
        "divva": "Diva",
        "wang fa": "WangFa",
        "oxy guard": "OxyGuard",
        "lin": "LINN",
        "sagr": "Sagar",
        "hcpp": "HCP",
        "yiyuan1": "Yiyuan",
    }

    def normalize_brand(self, brand: str) -> str:
        """Normalize the brand name to a standard format."""
        if not brand or not brand.strip():
            return "Generic"
        brand_lower = brand.lower().strip()
        return self.BRAND_NORMALIZATION.get(brand_lower, brand.title())

    def _calculate_kla(
        self, t70: float, temperature: float
    ) -> tuple[float, float]:
        """Calculate KLa at temperature T and standard 20°C."""
        if t70 <= 0:
            raise ValueError("T70 must be positive to calculate KLa.")
        t70_hours = t70 / 60.0
        kla_t = -math.log(1 - 0.7) / t70_hours
        theta = 1.024
        kla20 = kla_t * (theta ** (20.0 - temperature))
        return kla_t, kla20

    def _calculate_sotr_and_sae(
        self, kla20: float, cs20: float, volume: float, power_kw: float
    ) -> tuple[float, float]:
        """Calculate SOTR and SAE."""
        cs20_kg_m3 = cs20 * 0.001
        sotr = round(kla20 * cs20_kg_m3 * volume, 2)
        sae = round(sotr / power_kw, 2) if power_kw > 0 else 0.0
        return sotr, sae

    def calculate_metrics(self, params: AeratorMetricsInput) -> Dict[str, Any]:
        """
        Calculate performance metrics for an aerator in a shrimp pond.

        Args:
            params: Input parameters for metrics calculation.

        Returns:
            A dictionary containing the calculated metrics.
        """
        parts = params.aerator_id.split(" ", 1)
        brand = parts[0] if parts else "Generic"
        aerator_type = parts[1] if len(parts) > 1 else "Unknown"
        normalized_brand = self.normalize_brand(brand)
        normalized_aerator_id = f"{normalized_brand} {aerator_type}".strip()

        power_kw = round(params.hp * 0.746, 2)
        cs = self.get_o2_saturation(params.temperature, params.salinity)
        cs20 = self.get_o2_saturation(20, params.salinity)

        kla_t, kla20 = self._calculate_kla(params.t70, params.temperature)
        sotr, sae = self._calculate_sotr_and_sae(
            kla20, cs20, params.volume, power_kw
        )

        cost_per_kg = (
            round(params.kwh_price / sae, 2) if sae > 0 else float("inf")
        )
        annual_energy_cost = round(power_kw * params.kwh_price * 24 * 365, 2)

        return {
            "Pond Volume (m³)": params.volume,
            "Cs (mg/L)": round(cs, 2),
            "KlaT (h⁻¹)": round(kla_t, 2),
            "Kla20 (h⁻¹)": round(kla20, 2),
            "SOTR (kg O₂/h)": sotr,
            "SAE (kg O₂/kWh)": sae,
            "Cost per kg O₂ (USD/kg O₂)": cost_per_kg,
            "Power (kW)": power_kw,
            "Annual Energy Cost (USD/year)": annual_energy_cost,
            "Aerator ID": normalized_aerator_id,
        }

    def get_ideal_volume(self, hp: float) -> float:
        """Get the ideal pond volume (m³) for a given horsepower."""
        if hp <= 0:
            return 0
        if hp == 2:
            return 40.0
        if hp == 3:
            return 70.0
        return round(hp * 25.0, 0)

    def get_ideal_hp(self, volume: float) -> float:
        """Get the ideal horsepower for a given pond volume (m³)."""
        if volume <= 0:
            return 0.0
        if volume <= 40:
            return 2.0
        if volume <= 70:
            return 3.0
        return max(2.0, round(volume / 25.0, 0))

import { API_URL } from "../config.js";

/**
 * Service for making API calls to AeraSync backend
 */
export const apiService = {
  /**
   * Fetch available aerator templates from the API
   * @returns {Promise<Object[]>} - List of aerator templates
   */
  async getAeratorTemplates() {
    try {
      const response = await fetch(
        `${API_URL.replace(/\/api$/, "")}/aerator-templates`
      );

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error("Error fetching aerator templates:", error);
      return [];
    }
  },

  /**
   * Submit survey data and get comparison results
   * @param {Object} data - The survey form data
   * @returns {Promise<Object>} - API response with analysis results
   */
  async submitSurvey(data) {
    try {
      console.log("Submitting survey data to API...", data);

      const apiUrl = `${API_URL.replace(/\/api$/, "")}/compare`;
      console.log(`Connecting to: ${apiUrl}`);

      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API error: ${response.status} - ${errorText}`);
      }

      const result = await response.json();

      // Check for API errors
      if (result.error) {
        throw new Error(`API error: ${result.error}`);
      }

      // Add original survey data for reporting
      result.surveyData = {
        farm: data.farm,
        financial: data.financial,
        aerator1: data.aerators[0],
        aerator2: data.aerators[1],
      };

      console.log("API response received:", result);
      return result;
    } catch (error) {
      console.error("Error submitting survey data:", error);

      // For development and demo purposes, return mock data if API is unreachable
      if (
        process.env.NODE_ENV !== "production" ||
        window.location.hostname === "localhost"
      ) {
        console.log("Returning mock data for development");
        return getMockResults(data);
      }

      throw error;
    }
  },

  /**
   * Check if the API is healthy
   * @returns {Promise<boolean>} - True if API is healthy
   */
  async checkHealth() {
    try {
      const response = await fetch(`${API_URL.replace(/\/api$/, "")}/health`, {
        method: "GET",
        headers: {
          Accept: "application/json",
        },
      });

      return response.ok;
    } catch (error) {
      console.error("API health check failed:", error);
      return false;
    }
  },
};

// Updated mock results function with complete survey data
function getMockResults(data) {
  const aerator1 = data.aerators[0];
  const aerator2 = data.aerators[1];

  // Determine which aerator is better based on SOTR/cost ratio
  const winner =
    aerator1.sotr / aerator1.cost > aerator2.sotr / aerator2.cost
      ? aerator1
      : aerator2;
  const loser = winner === aerator1 ? aerator2 : aerator1;
  const winnerLabel = winner.name;

  // Calculate mock equilibrium price similar to the API algorithm
  const mockEquilibriumPrice = Math.round(
    (winner.sotr / loser.sotr) * loser.cost * 0.9
  );

  // Create equilibrium prices object with the same structure as API response
  const equilibriumPrices = {};
  equilibriumPrices[loser.name] = mockEquilibriumPrice;

  return {
    tod: data.farm.tod,
    annual_revenue: 500000,
    aeratorResults: [
      {
        name: aerator1.name,
        power_hp: aerator1.power_hp,
        sotr: aerator1.sotr,
        cost: aerator1.cost,
        durability: aerator1.durability,
        maintenance: aerator1.maintenance,
        num_aerators: Math.ceil(data.farm.tod / aerator1.sotr),
        total_power_hp:
          Math.ceil(data.farm.tod / aerator1.sotr) * aerator1.power_hp,
        total_initial_cost:
          Math.ceil(data.farm.tod / aerator1.sotr) * aerator1.cost,
        annual_energy_cost: 25000,
        annual_maintenance_cost:
          Math.ceil(data.farm.tod / aerator1.sotr) * aerator1.maintenance,
        annual_replacement_cost:
          (Math.ceil(data.farm.tod / aerator1.sotr) * aerator1.cost) /
          aerator1.durability,
        total_annual_cost: 50000,
        cost_percent_revenue: 10,
        aerators_per_ha:
          Math.ceil(data.farm.tod / aerator1.sotr) / data.farm.farm_area_ha,
        hp_per_ha:
          (Math.ceil(data.farm.tod / aerator1.sotr) * aerator1.power_hp) /
          data.farm.farm_area_ha,
        npv_savings: aerator1.name === winnerLabel ? 0 : 150000,
        irr: aerator1.name === winnerLabel ? -100 : 12,
        payback_years: aerator1.name === winnerLabel ? 0 : 3.5,
        roi_percent: aerator1.name === winnerLabel ? 0 : 25,
        sae: aerator1.sotr / (aerator1.power_hp * 0.746),
        profitability_k: aerator1.name === winnerLabel ? 0 : 1.5,
        opportunity_cost: aerator1.name === winnerLabel ? 0 : 10000,
      },
      {
        name: aerator2.name,
        power_hp: aerator2.power_hp,
        sotr: aerator2.sotr,
        cost: aerator2.cost,
        durability: aerator2.durability,
        maintenance: aerator2.maintenance,
        num_aerators: Math.ceil(data.farm.tod / aerator2.sotr),
        total_power_hp:
          Math.ceil(data.farm.tod / aerator2.sotr) * aerator2.power_hp,
        total_initial_cost:
          Math.ceil(data.farm.tod / aerator2.sotr) * aerator2.cost,
        annual_energy_cost: 20000,
        annual_maintenance_cost:
          Math.ceil(data.farm.tod / aerator2.sotr) * aerator2.maintenance,
        annual_replacement_cost:
          (Math.ceil(data.farm.tod / aerator2.sotr) * aerator2.cost) /
          aerator2.durability,
        total_annual_cost: 40000,
        cost_percent_revenue: 8,
        aerators_per_ha:
          Math.ceil(data.farm.tod / aerator2.sotr) / data.farm.farm_area_ha,
        hp_per_ha:
          (Math.ceil(data.farm.tod / aerator2.sotr) * aerator2.power_hp) /
          data.farm.farm_area_ha,
        npv_savings: aerator2.name === winnerLabel ? 0 : 120000,
        irr: aerator2.name === winnerLabel ? -100 : 15,
        payback_years: aerator2.name === winnerLabel ? 0 : 2.8,
        roi_percent: aerator2.name === winnerLabel ? 0 : 30,
        sae: aerator2.sotr / (aerator2.power_hp * 0.746),
        profitability_k: aerator2.name === winnerLabel ? 0 : 1.8,
        opportunity_cost: aerator2.name === winnerLabel ? 0 : 8000,
      },
    ],
    winnerLabel: winnerLabel,
    equilibriumPrices: equilibriumPrices,
    surveyData: {
      farm: data.farm,
      financial: data.financial,
      aerator1: data.aerators[0],
      aerator2: data.aerators[1],
    },
  };
}

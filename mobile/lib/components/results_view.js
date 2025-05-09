import { t } from "../utils/i18n.js";
import {
  formatCurrency,
  formatPercent,
  formatPaybackPeriod,
} from "../utils/formatters.js";

/**
 * Initialize the results view
 * @param {Object} app - The main application object
 */
export function initResultsView(app) {
  const { results, translations } = app;

  if (!results) {
    app.navigate("survey");
    return;
  }

  // Render each part of the results page
  renderSummary(results, translations);
  renderAeratorComparisonCards(results, translations);
  renderEquilibriumPrices(results, translations);
  renderCostBreakdownChart(results, translations);
  renderCostEvolutionChart(results, translations);
  setupPdfExport(results, translations);
}

/**
 * Render the summary section of results
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function renderSummary(results, translations) {
  const summaryContainer = document.querySelector(".summary-data");
  if (!summaryContainer) return;

  const tod = results.tod || 0;
  const annualRevenue = results.annual_revenue || 0;
  const winner = results.winnerLabel || "";

  summaryContainer.innerHTML = `
    <div class="summary-item">
      <span class="label">${t(translations, "totalDemandLabel")}</span>
      <span class="value">${tod.toFixed(2)} kg O₂/h/ha</span>
    </div>
    <div class="summary-item">
      <span class="label">${t(translations, "annualRevenueLabel")}</span>
      <span class="value">$${formatCurrency(annualRevenue)}</span>
    </div>
    <div class="summary-item">
      <span class="label">${t(translations, "recommendedAerator")}</span>
      <span class="value winner">${winner}</span>
    </div>
  `;
}

/**
 * Render the aerator comparison cards
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function renderAeratorComparisonCards(results, translations) {
  const container = document.getElementById("aerator-cards");
  if (!container) return;

  container.innerHTML = "";

  // Get the aerator results array
  const aerators = results.aeratorResults || [];
  if (!aerators.length) {
    container.innerHTML = `<p class="no-data">${t(
      translations,
      "noDataAvailable"
    )}</p>`;
    return;
  }

  // Create a card for each aerator
  aerators.forEach((aerator) => {
    const isRecommended = aerator.name === results.winnerLabel;
    const card = document.createElement("div");
    card.className = `aerator-card ${isRecommended ? "recommended" : ""}`;

    // Render card header
    let cardHTML = `
      <div class="card-header">
        <h3>${aerator.name}</h3>
        ${
          isRecommended
            ? `<span class="badge">${t(translations, "recommended")}</span>`
            : ""
        }
      </div>
      <div class="metrics-group">
        <h4>${t(translations, "mainMetrics")}</h4>
        <div class="metric">
          <span class="metric-label">${t(translations, "unitsRequired")}</span>
          <span class="metric-value">${aerator.num_aerators}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "unitsPerHectare"
          )}</span>
          <span class="metric-value">${aerator.units_per_ha.toFixed(2)}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "initialCostLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.total_initial_cost
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "annualCostLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.total_annual_cost
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(translations, "saeLabel")}</span>
          <span class="metric-value">${aerator.sae.toFixed(2)}</span>
        </div>
      </div>
    `;

    // Render financial metrics
    cardHTML += `
      <div class="metrics-group">
        <h4>${t(translations, "financialMetrics")}</h4>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "costPercentRevenueLabel"
          )}</span>
          <span class="metric-value">${formatPercent(
            aerator.cost_percent_revenue
          )}</span>
        </div>`;

    // NPV savings only apply to non-recommended aerators
    if (!isRecommended) {
      cardHTML += `
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "npvSavingsLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.npv_savings
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(translations, "paybackPeriod")}</span>
          <span class="metric-value">${formatPaybackPeriod(
            aerator.payback_years,
            translations
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(translations, "roiLabel")}</span>
          <span class="metric-value">${formatPercent(
            aerator.roi_percent
          )}</span>
        </div>`;
    } else {
      cardHTML += `
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "profitabilityIndexLabel"
          )}</span>
          <span class="metric-value">${
            aerator.profitability_index?.toFixed(2) ||
            t(translations, "notApplicable")
          }</span>
        </div>`;
    }

    // Close the metrics group
    cardHTML += `</div>`;

    // Add annual cost breakdown
    cardHTML += `
      <div class="metrics-group">
        <h4>${t(translations, "annualCostLabel")} ${t(
      translations,
      "costBreakdownVisualization"
    ).toLowerCase()}</h4>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "energyCostLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.annual_energy_cost
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "maintenanceLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.annual_maintenance_cost
          )}</span>
        </div>
        <div class="metric">
          <span class="metric-label">${t(
            translations,
            "replacementCostLabel"
          )}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.annual_replacement_cost
          )}</span>
        </div>
        <div class="metric total">
          <span class="metric-label">${t(translations, "totalLabel")}</span>
          <span class="metric-value">$${formatCurrency(
            aerator.total_annual_cost
          )}</span>
        </div>
      </div>
    `;

    // Set the HTML and append the card
    card.innerHTML = cardHTML;
    container.appendChild(card);
  });
}

/**
 * Render the equilibrium prices section
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function renderEquilibriumPrices(results, translations) {
  const container = document.getElementById("equilibrium-prices");
  if (!container) return;

  const equilibriumPrices = results.equilibriumPrices || {};

  if (Object.keys(equilibriumPrices).length === 0) {
    container.innerHTML = `<p class="no-data">${t(
      translations,
      "noEquilibriumPrices"
    )}</p>`;
    return;
  }

  let html = '<div class="equilibrium-price-table">';

  for (const [name, price] of Object.entries(equilibriumPrices)) {
    html += `
      <div class="equilibrium-price-item">
        <div class="aerator-name">${name}</div>
        <div class="price-value">$${price.toFixed(2)}</div>
        <div class="price-explanation">${t(
          translations,
          "equilibriumPriceExplanation"
        )}</div>
      </div>
    `;
  }

  html += "</div>";
  container.innerHTML = html;
}

/**
 * Render the cost breakdown chart
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function renderCostBreakdownChart(results, translations) {
  const container = document.getElementById("comparison-chart");
  if (!container) return;

  const aerators = results.aeratorResults || [];
  if (!aerators.length) {
    container.innerHTML = `<p class="no-data">${t(
      translations,
      "noDataAvailable"
    )}</p>`;
    return;
  }

  // Create simple bars for cost breakdown
  let html = "";

  aerators.forEach((aerator) => {
    const totalAnnualCost = aerator.total_annual_cost || 0;
    if (totalAnnualCost <= 0) return;

    const energyCost = aerator.annual_energy_cost || 0;
    const maintenanceCost = aerator.annual_maintenance_cost || 0;
    const replacementCost = aerator.annual_replacement_cost || 0;

    // Calculate percentages
    const energyPercent = (energyCost / totalAnnualCost) * 100;
    const maintenancePercent = (maintenanceCost / totalAnnualCost) * 100;
    const replacementPercent = (replacementCost / totalAnnualCost) * 100;

    html += `
      <div class="cost-bar-container">
        <div class="cost-bar-label">${aerator.name}</div>
        <div class="cost-bar">
          <div class="cost-bar-segment energy-color" style="width: ${energyPercent}%" 
               title="${t(translations, "energyCostLabel")}: $${formatCurrency(
      energyCost
    )}"></div>
          <div class="cost-bar-segment maintenance-color" style="width: ${maintenancePercent}%" 
               title="${t(translations, "maintenanceLabel")}: $${formatCurrency(
      maintenanceCost
    )}"></div>
          <div class="cost-bar-segment replacement-color" style="width: ${replacementPercent}%" 
               title="${t(
                 translations,
                 "replacementCostLabel"
               )}: $${formatCurrency(replacementCost)}"></div>
        </div>
        <div class="cost-bar-value">$${formatCurrency(totalAnnualCost)}</div>
      </div>
    `;
  });

  container.innerHTML = html;
}

/**
 * Render the cost evolution chart
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function renderCostEvolutionChart(results, translations) {
  const container = document.getElementById("evolution-chart");
  if (!container) return;

  // TODO: Implement cost evolution chart when data is available
  container.innerHTML = `<div class="placeholder-chart">
    <p>${t(translations, "cummulativeCostExplanation")}</p>
  </div>`;
}

/**
 * Set up the PDF export functionality
 * @param {Object} results - The results data
 * @param {Object} translations - Translation dictionary
 */
function setupPdfExport(results, translations) {
  const exportButton = document.getElementById("export-pdf");
  if (!exportButton) return;

  exportButton.addEventListener("click", async () => {
    try {
      exportButton.disabled = true;
      exportButton.textContent = t(translations, "generating");

      // Show toast message
      const toast = document.getElementById("error-toast");
      toast.className = "toast info";
      toast.textContent = t(translations, "generating");
      toast.style.display = "block";

      setTimeout(() => {
        toast.style.display = "none";
      }, 3000);

      // Dynamically import the PDF module
      const pdfModule = await import("../utils/pdf_generator.js");

      // Download the PDF
      const success = await pdfModule.downloadPdf(results);

      if (success) {
        toast.className = "toast success";
        toast.textContent = t(translations, "success");
      } else {
        toast.className = "toast error";
        toast.textContent = t(translations, "exportFailed");
      }

      toast.style.display = "block";
      setTimeout(() => {
        toast.style.display = "none";
      }, 3000);
    } catch (error) {
      console.error("PDF export failed:", error);

      const toast = document.getElementById("error-toast");
      toast.className = "toast error";
      toast.textContent = t(translations, "exportFailed");
      toast.style.display = "block";

      setTimeout(() => {
        toast.style.display = "none";
      }, 5000);
    } finally {
      exportButton.disabled = false;
      exportButton.textContent = t(translations, "exportToPdf");
    }
  });
}

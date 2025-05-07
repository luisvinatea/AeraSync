import Chart from "chart.js/auto";
import { jsPDF } from "jspdf";
import "jspdf-autotable";

export function initResultsView(app) {
  const { results } = app;

  if (!results) {
    app.navigate("survey");
    return;
  }

  // Render each part of the results page
  renderSummary(results);
  renderAeratorComparisonCards(results);
  renderEquilibriumPrices(results);
  renderCostBreakdownChart(results);
  renderCostEvolutionChart(results);
  setupPdfExport(results);
}

function renderSummary(results) {
  const summaryContainer = document.getElementById("summary-container");
  if (!summaryContainer) return;

  const surveyData = results.surveyData || {};
  const farm = surveyData.farm || {};
  const financial = surveyData.financial || {};
  const aerator1 = surveyData.aerator1 || {};
  const aerator2 = surveyData.aerator2 || {};
  const tod = results.tod || 0;
  const annualRevenue = results.annual_revenue || 0;
  const winnerLabel = results.winnerLabel || "None";

  const summaryData = document.querySelector(".summary-data");
  if (summaryData) {
    summaryData.innerHTML = `
      <div class="summary-item">
        <span class="summary-label">Total Oxygen Demand:</span>
        <span class="summary-value">${tod.toFixed(2)} kg O₂/h</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">Annual Revenue:</span>
        <span class="summary-value">$${formatCurrencyK(annualRevenue)}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">Recommended Aerator:</span>
        <span class="summary-value highlighted">${winnerLabel}</span>
      </div>
      <div class="divider"></div>
      <h4>Survey Inputs</h4>
      
      <h5>Farm Specifications</h5>
      <div class="summary-subsection">
        <div class="summary-item">
          <span class="summary-label">Farm Area:</span>
          <span class="summary-value">${farm.farm_area_ha || "N/A"} ha</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Shrimp Price:</span>
          <span class="summary-value">$${farm.shrimp_price || "N/A"}/kg</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Culture Days:</span>
          <span class="summary-value">${farm.culture_days || "N/A"}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Shrimp Density:</span>
          <span class="summary-value">${
            farm.shrimp_density_kg_m3 || "N/A"
          } kg/m³</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Pond Depth:</span>
          <span class="summary-value">${farm.pond_depth_m || "N/A"} m</span>
        </div>
      </div>

      <h5>Financial Aspects</h5>
      <div class="summary-subsection">
        <div class="summary-item">
          <span class="summary-label">Energy Cost:</span>
          <span class="summary-value">$${
            financial.energy_cost || "N/A"
          }/kWh</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Hours Per Night:</span>
          <span class="summary-value">${
            financial.hours_per_night || "N/A"
          }</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Discount Rate:</span>
          <span class="summary-value">${
            financial.discount_rate
              ? (financial.discount_rate * 100).toFixed(1)
              : "N/A"
          }%</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Inflation Rate:</span>
          <span class="summary-value">${
            financial.inflation_rate
              ? (financial.inflation_rate * 100).toFixed(1)
              : "N/A"
          }%</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Analysis Horizon:</span>
          <span class="summary-value">${financial.horizon || "N/A"} years</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Safety Margin:</span>
          <span class="summary-value">${
            financial.safety_margin
              ? (financial.safety_margin * 100).toFixed(1)
              : "N/A"
          }%</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Temperature:</span>
          <span class="summary-value">${
            financial.temperature || "N/A"
          } °C</span>
        </div>
      </div>

      <h5>Aerator 1</h5>
      <div class="summary-subsection">
        <div class="summary-item">
          <span class="summary-label">Name:</span>
          <span class="summary-value">${aerator1.name || "N/A"}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Power:</span>
          <span class="summary-value">${aerator1.power_hp || "N/A"} HP</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">SOTR:</span>
          <span class="summary-value">${aerator1.sotr || "N/A"} kg O₂/h</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Cost:</span>
          <span class="summary-value">$${aerator1.cost || "N/A"}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Durability:</span>
          <span class="summary-value">${
            aerator1.durability || "N/A"
          } years</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Maintenance:</span>
          <span class="summary-value">$${
            aerator1.maintenance || "N/A"
          }/year</span>
        </div>
      </div>

      <h5>Aerator 2</h5>
      <div class="summary-subsection">
        <div class="summary-item">
          <span class="summary-label">Name:</span>
          <span class="summary-value">${aerator2.name || "N/A"}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Power:</span>
          <span class="summary-value">${aerator2.power_hp || "N/A"} HP</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">SOTR:</span>
          <span class="summary-value">${aerator2.sotr || "N/A"} kg O₂/h</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Cost:</span>
          <span class="summary-value">$${aerator2.cost || "N/A"}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Durability:</span>
          <span class="summary-value">${
            aerator2.durability || "N/A"
          } years</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Maintenance:</span>
          <span class="summary-value">$${
            aerator2.maintenance || "N/A"
          }/year</span>
        </div>
      </div>
    `;
  }
}

function renderAeratorComparisonCards(results) {
  const aeratorCardsContainer = document.getElementById("aerator-cards");
  if (!aeratorCardsContainer) return;

  const aerators = results.aeratorResults || [];
  const winnerLabel = results.winnerLabel;

  aeratorCardsContainer.innerHTML = "";

  aerators.forEach((aerator) => {
    const isRecommended = aerator.name === winnerLabel;
    const card = document.createElement("div");
    card.className = `aerator-card${isRecommended ? " recommended" : ""}`;

    card.innerHTML = `
      <div class="aerator-header">
        <h4>${aerator.name}</h4>
        ${
          isRecommended
            ? '<span class="recommended-badge">Recommended</span>'
            : ""
        }
      </div>
      <div class="divider"></div>
      <div class="detail-grid">
        <div class="detail-row">
          <span class="detail-label">Units Required</span>
          <span class="detail-value">${aerator.num_aerators}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Units per Hectare</span>
          <span class="detail-value">${aerator.aerators_per_ha.toFixed(
            2
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">HP per Ha</span>
          <span class="detail-value">${aerator.hp_per_ha.toFixed(
            2
          )} hp/ha</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Initial Cost</span>
          <span class="detail-value">$${formatCurrencyK(
            aerator.total_initial_cost
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Annual Cost</span>
          <span class="detail-value">$${formatCurrencyK(
            aerator.total_annual_cost
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Cost/Revenue</span>
          <span class="detail-value">${aerator.cost_percent_revenue.toFixed(
            2
          )}%</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Energy Cost</span>
          <span class="detail-value">$${formatCurrencyK(
            aerator.annual_energy_cost
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Maintenance Cost</span>
          <span class="detail-value">$${formatCurrencyK(
            aerator.annual_maintenance_cost
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">NPV Savings</span>
          <span class="detail-value">$${formatCurrencyK(
            aerator.npv_savings
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Payback Period</span>
          <span class="detail-value">${formatPaybackPeriod(
            aerator.payback_years
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">ROI</span>
          <span class="detail-value">${aerator.roi_percent.toFixed(2)}%</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Profitability Index</span>
          <span class="detail-value">${formatProfitabilityK(
            aerator.profitability_k
          )}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">SAE</span>
          <span class="detail-value">${aerator.sae.toFixed(2)} kg O₂/kWh</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Cost per kg O₂</span>
          <span class="detail-value">$${aerator.cost_per_kg_o2.toFixed(
            3
          )}/kg O₂</span>
        </div>
      </div>
    `;

    aeratorCardsContainer.appendChild(card);
  });
}

function renderEquilibriumPrices(results) {
  const equilibriumContainer = document.getElementById("equilibrium-prices");
  if (!equilibriumContainer) return;

  const equilibriumPrices = results.equilibriumPrices || {};

  equilibriumContainer.innerHTML = "";

  if (Object.keys(equilibriumPrices).length === 0) {
    equilibriumContainer.innerHTML =
      "<p class='no-data'>No equilibrium prices available</p>";
    return;
  }

  Object.entries(equilibriumPrices).forEach(([name, price]) => {
    const priceItem = document.createElement("div");
    priceItem.className = "equilibrium-item";
    priceItem.innerHTML = `
      <span>${name}</span>
      <span class="equilibrium-value">$${formatCurrencyK(price)}</span>
    `;
    equilibriumContainer.appendChild(priceItem);
  });
}

function renderCostBreakdownChart(results) {
  const chartContainer = document.getElementById("comparison-chart");
  if (!chartContainer) return;

  const aerators = results.aeratorResults || [];
  const winnerLabel = results.winnerLabel || "";

  // Create canvas element for chart
  const canvas = document.createElement("canvas");
  canvas.id = "cost-breakdown-chart";
  chartContainer.innerHTML = "";
  chartContainer.appendChild(canvas);

  // Prepare data for chart
  const labels = aerators.map((a) => a.name);
  const energyCosts = aerators.map((a) => a.annual_energy_cost);
  const maintenanceCosts = aerators.map((a) => a.annual_maintenance_cost);
  const replacementCosts = aerators.map((a) => a.annual_replacement_cost);

  const recommendedIndices = aerators
    .map((a, i) => (a.name === winnerLabel ? i : -1))
    .filter((i) => i !== -1);

  // Create chart
  new Chart(canvas, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Energy Cost",
          data: energyCosts,
          backgroundColor: "rgba(30, 64, 175, 0.7)",
          stack: "Stack 0",
        },
        {
          label: "Maintenance Cost",
          data: maintenanceCosts,
          backgroundColor: "rgba(96, 165, 250, 0.7)",
          stack: "Stack 0",
        },
        {
          label: "Replacement Cost",
          data: replacementCosts,
          backgroundColor: "rgba(147, 197, 253, 0.7)",
          stack: "Stack 0",
        },
      ],
    },
    options: {
      responsive: true,
      scales: {
        x: {
          stacked: true,
        },
        y: {
          stacked: true,
          title: {
            display: true,
            text: "Annual Cost (USD)",
          },
        },
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          callbacks: {
            label: function (context) {
              const label = context.dataset.label || "";
              const value = context.parsed.y;
              return `${label}: $${formatCurrencyK(value)}`;
            },
          },
        },
      },
    },
  });
}

function renderCostEvolutionChart(results) {
  const chartContainer = document.getElementById("evolution-chart");
  if (!chartContainer) return;

  const aerators = results.aeratorResults || [];
  const winnerLabel = results.winnerLabel || "";
  const surveyData = results.surveyData || {};
  const horizon = surveyData.financial?.horizon || 10;

  // Find the recommended aerator
  const winnerAerator =
    aerators.find((a) => a.name === winnerLabel) || aerators[0];

  // Create canvas element for chart
  const canvas = document.createElement("canvas");
  canvas.id = "cost-evolution-chart";
  chartContainer.innerHTML = "";
  chartContainer.appendChild(canvas);

  // Prepare datasets for each aerator compared to winner
  const datasets = [];

  aerators.forEach((aerator, index) => {
    if (aerator.name !== winnerLabel) {
      // Calculate cumulative cost difference for each year
      const points = [];
      let cumulativeDiff =
        aerator.total_initial_cost - winnerAerator.total_initial_cost;
      points.push({ x: 0, y: cumulativeDiff });

      for (let year = 1; year <= horizon; year++) {
        cumulativeDiff +=
          aerator.total_annual_cost - winnerAerator.total_annual_cost;
        points.push({ x: year, y: cumulativeDiff });
      }

      datasets.push({
        label: aerator.name,
        data: points,
        borderColor: getChartColor(index),
        backgroundColor: getChartColor(index, 0.2),
        fill: true,
        tension: 0.3,
      });
    }
  });

  // Create chart
  new Chart(canvas, {
    type: "line",
    data: {
      datasets: datasets,
    },
    options: {
      responsive: true,
      scales: {
        x: {
          type: "linear",
          title: {
            display: true,
            text: "Years",
          },
          ticks: {
            stepSize: 1,
          },
        },
        y: {
          title: {
            display: true,
            text: "Cumulative Cost Difference ($)",
          },
        },
      },
      plugins: {
        legend: {
          position: "bottom",
        },
        tooltip: {
          callbacks: {
            label: function (context) {
              const label = context.dataset.label || "";
              const value = context.parsed.y;
              return `${label}: $${formatCurrencyK(value)}`;
            },
          },
        },
      },
    },
  });
}

function setupPdfExport(results) {
  const exportButton = document.getElementById("export-pdf");
  if (!exportButton) return;

  exportButton.addEventListener("click", async () => {
    try {
      exportButton.disabled = true;
      exportButton.textContent = "Generating PDF...";

      // Generate PDF using jsPDF
      const pdf = await generatePdf(results);

      // Save the PDF
      pdf.save(`aerasync_results_${new Date().toISOString().slice(0, 10)}.pdf`);

      exportButton.textContent = "Export PDF";
      exportButton.disabled = false;
    } catch (error) {
      console.error("PDF generation error:", error);
      exportButton.textContent = "Export Failed";
      setTimeout(() => {
        exportButton.textContent = "Export PDF";
        exportButton.disabled = false;
      }, 3000);
    }
  });
}

async function generatePdf(results) {
  // Create PDF document
  const pdf = new jsPDF({
    orientation: "portrait",
    unit: "mm",
    format: "a4",
  });

  const surveyData = results.surveyData || {};
  const farm = surveyData.farm || {};
  const financial = surveyData.financial || {};
  const aerator1 = surveyData.aerator1 || {};
  const aerator2 = surveyData.aerator2 || {};

  // Add title and date
  pdf.setFontSize(20);
  pdf.setTextColor(30, 64, 175);
  pdf.text("AeraSync Aerator Comparison Results", 15, 15);

  pdf.setFontSize(10);
  pdf.setTextColor(100, 100, 100);
  pdf.text(`Generated on ${new Date().toLocaleDateString()}`, 15, 22);

  // Summary section
  pdf.setFontSize(16);
  pdf.setTextColor(0, 0, 0);
  pdf.text("Summary", 15, 35);

  pdf.setFontSize(11);
  pdf.text(
    `Total Oxygen Demand: ${(results.tod || 0).toFixed(2)} kg O₂/h`,
    20,
    45
  );
  pdf.text(
    `Annual Revenue: $${formatCurrencyK(results.annual_revenue || 0)}`,
    20,
    52
  );
  pdf.text(`Recommended Aerator: ${results.winnerLabel || "None"}`, 20, 59);

  // Aerator comparison table
  pdf.setFontSize(16);
  pdf.text("Aerator Comparison", 15, 75);

  const aerators = results.aeratorResults || [];
  const tableData = aerators.map((aerator) => [
    aerator.name === results.winnerLabel
      ? `${aerator.name} (Recommended)`
      : aerator.name,
    aerator.num_aerators,
    `$${formatCurrencyK(aerator.total_initial_cost)}`,
    `$${formatCurrencyK(aerator.total_annual_cost)}`,
    `$${formatCurrencyK(aerator.npv_savings)}`,
    `${aerator.roi_percent.toFixed(2)}%`,
    formatPaybackPeriod(aerator.payback_years),
  ]);

  pdf.autoTable({
    startY: 80,
    head: [
      [
        "Name",
        "Units",
        "Initial Cost",
        "Annual Cost",
        "NPV Savings",
        "ROI",
        "Payback",
      ],
    ],
    body: tableData,
    theme: "grid",
    headStyles: { fillColor: [30, 64, 175], textColor: [255, 255, 255] },
    styles: { fontSize: 10 },
    columnStyles: {
      0: { cellWidth: 40 },
    },
  });

  // Cost breakdown for each aerator
  pdf.setFontSize(16);
  let yPosition = pdf.lastAutoTable.finalY + 15;
  pdf.text("Cost Breakdown", 15, yPosition);
  yPosition += 10;

  aerators.forEach((aerator) => {
    pdf.setFontSize(12);
    pdf.text(aerator.name, 20, yPosition);
    yPosition += 6;

    pdf.setFontSize(10);
    pdf.text(
      `Energy Cost: $${formatCurrencyK(aerator.annual_energy_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Maintenance Cost: $${formatCurrencyK(aerator.annual_maintenance_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Replacement Cost: $${formatCurrencyK(aerator.annual_replacement_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Total Annual Cost: $${formatCurrencyK(aerator.total_annual_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(`SAE: ${aerator.sae.toFixed(2)} kg O₂/kWh`, 25, yPosition);
    yPosition += 5;
    pdf.text(
      `Cost per kg O₂: $${aerator.cost_per_kg_o2.toFixed(3)}/kg O₂`,
      25,
      yPosition
    );
    yPosition += 10;
  });

  // Equilibrium prices
  if (yPosition > 250) {
    pdf.addPage();
    yPosition = 20;
  }

  pdf.setFontSize(16);
  pdf.text("Equilibrium Prices", 15, yPosition);
  yPosition += 10;

  const equilibriumPrices = results.equilibriumPrices || {};

  if (Object.keys(equilibriumPrices).length === 0) {
    pdf.setFontSize(10);
    pdf.text("No equilibrium prices available", 20, yPosition);
    yPosition += 10;
  } else {
    Object.entries(equilibriumPrices).forEach(([name, price]) => {
      pdf.setFontSize(10);
      pdf.text(`${name}: $${formatCurrencyK(price)}`, 20, yPosition);
      yPosition += 7;
    });
    yPosition += 5;
  }

  // Survey inputs
  if (yPosition > 230) {
    pdf.addPage();
    yPosition = 20;
  }

  pdf.setFontSize(16);
  pdf.text("Survey Inputs", 15, yPosition);
  yPosition += 10;

  // Farm specifications
  pdf.setFontSize(12);
  pdf.text("Farm Specifications", 15, yPosition);
  yPosition += 8;

  pdf.setFontSize(10);
  pdf.text(`Farm Area: ${farm.farm_area_ha || "N/A"} ha`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Shrimp Price: $${farm.shrimp_price || "N/A"}/kg`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Culture Days: ${farm.culture_days || "N/A"}`, 20, yPosition);
  yPosition += 5;
  pdf.text(
    `Shrimp Density: ${farm.shrimp_density_kg_m3 || "N/A"} kg/m³`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(`Pond Depth: ${farm.pond_depth_m || "N/A"} m`, 20, yPosition);
  yPosition += 10;

  // Financial aspects
  pdf.setFontSize(12);
  pdf.text("Financial Aspects", 15, yPosition);
  yPosition += 8;

  pdf.setFontSize(10);
  pdf.text(
    `Energy Cost: $${financial.energy_cost || "N/A"}/kWh`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(
    `Hours Per Night: ${financial.hours_per_night || "N/A"}`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(
    `Discount Rate: ${
      financial.discount_rate
        ? (financial.discount_rate * 100).toFixed(1)
        : "N/A"
    }%`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(
    `Inflation Rate: ${
      financial.inflation_rate
        ? (financial.inflation_rate * 100).toFixed(1)
        : "N/A"
    }%`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(
    `Analysis Horizon: ${financial.horizon || "N/A"} years`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(
    `Safety Margin: ${
      financial.safety_margin
        ? (financial.safety_margin * 100).toFixed(1)
        : "N/A"
    }%`,
    20,
    yPosition
  );
  yPosition += 5;
  pdf.text(`Temperature: ${financial.temperature || "N/A"} °C`, 20, yPosition);
  yPosition += 10;

  if (yPosition > 250) {
    pdf.addPage();
    yPosition = 20;
  }

  // Aerator specifications
  pdf.setFontSize(12);
  pdf.text(`Aerator 1: ${aerator1.name || "N/A"}`, 15, yPosition);
  yPosition += 8;

  pdf.setFontSize(10);
  pdf.text(`Power: ${aerator1.power_hp || "N/A"} HP`, 20, yPosition);
  yPosition += 5;
  pdf.text(`SOTR: ${aerator1.sotr || "N/A"} kg O₂/h`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Cost: $${aerator1.cost || "N/A"}`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Durability: ${aerator1.durability || "N/A"} years`, 20, yPosition);
  yPosition += 5;
  pdf.text(
    `Maintenance: $${aerator1.maintenance || "N/A"}/year`,
    20,
    yPosition
  );
  yPosition += 10;

  pdf.setFontSize(12);
  pdf.text(`Aerator 2: ${aerator2.name || "N/A"}`, 15, yPosition);
  yPosition += 8;

  pdf.setFontSize(10);
  pdf.text(`Power: ${aerator2.power_hp || "N/A"} HP`, 20, yPosition);
  yPosition += 5;
  pdf.text(`SOTR: ${aerator2.sotr || "N/A"} kg O₂/h`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Cost: $${aerator2.cost || "N/A"}`, 20, yPosition);
  yPosition += 5;
  pdf.text(`Durability: ${aerator2.durability || "N/A"} years`, 20, yPosition);
  yPosition += 5;
  pdf.text(
    `Maintenance: $${aerator2.maintenance || "N/A"}/year`,
    20,
    yPosition
  );
  yPosition += 10;

  // Add footer
  const totalPages = pdf.internal.getNumberOfPages();
  for (let i = 1; i <= totalPages; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.setTextColor(150, 150, 150);
    pdf.text(
      `AeraSync Report | Page ${i} of ${totalPages}`,
      pdf.internal.pageSize.getWidth() / 2,
      pdf.internal.pageSize.getHeight() - 10,
      { align: "center" }
    );
  }

  return pdf;
}

// Utility functions
function formatCurrencyK(value) {
  if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `${(value / 1000).toFixed(1)}K`;
  return value.toFixed(2);
}

function formatProfitabilityK(value) {
  if (value === null || value === undefined || value < 0) return "N/A";
  return value.toFixed(2);
}

function formatPaybackPeriod(years) {
  if (years === null || years === undefined || years < 0) return "N/A";
  if (!isFinite(years)) return "Never";
  if (years > 100) return ">100 years";

  // For very short payback periods (less than 30 days)
  if (years < 0.08) {
    const days = Math.round(years * 365);
    return `${days} ${days === 1 ? "day" : "days"}`;
  }

  // For periods less than a year - show months and days
  if (years < 1) {
    const monthsTotal = years * 12;
    const months = Math.floor(monthsTotal);
    const days = Math.round((monthsTotal - months) * 30);

    if (days > 0) {
      return `${months} ${months === 1 ? "month" : "months"}, ${days} ${
        days === 1 ? "day" : "days"
      }`;
    } else {
      return `${months} ${months === 1 ? "month" : "months"}`;
    }
  }

  // More than a year - show years and months
  const wholeYears = Math.floor(years);
  const months = Math.round((years - wholeYears) * 12);

  if (months > 0) {
    return `${wholeYears} ${wholeYears === 1 ? "year" : "years"}, ${months} ${
      months === 1 ? "month" : "months"
    }`;
  } else {
    return `${wholeYears} ${wholeYears === 1 ? "year" : "years"}`;
  }
}

function getChartColor(index, alpha = 1) {
  const colors = [
    `rgba(30, 64, 175, ${alpha})`,
    `rgba(220, 38, 38, ${alpha})`,
    `rgba(16, 185, 129, ${alpha})`,
    `rgba(217, 119, 6, ${alpha})`,
    `rgba(124, 58, 237, ${alpha})`,
    `rgba(6, 182, 212, ${alpha})`,
    `rgba(79, 70, 229, ${alpha})`,
  ];

  return colors[index % colors.length];
}

import Chart from "chart.js/auto";

export function initResultsView(app) {
  const { results } = app;

  if (!results) {
    app.navigate("survey");
    return;
  }

  // Render summary data
  renderSummary();

  // Render comparison chart
  renderComparisonChart();

  // Render aerator cards
  renderAeratorCards();

  function renderSummary() {
    const summaryEl = document.getElementById("summary-container");
    if (!summaryEl) return;

    const { survey_data } = results;

    // Basic summary details
    summaryEl.innerHTML = `
      <div class="summary-card">
        <h3>${app.translations?.results?.summary || "Summary"}</h3>
        <div class="summary-data">
          <div class="summary-item">
            <span class="summary-label">Pond area:</span>
            <span class="summary-value">${survey_data?.pond_area || 0} ha</span>
          </div>
          <div class="summary-item">
            <span class="summary-label">Aeration rate:</span>
            <span class="summary-value">${
              survey_data?.aeration_rate || 0
            } HP/ha</span>
          </div>
          <div class="summary-item">
            <span class="summary-label">Energy source:</span>
            <span class="summary-value">${
              survey_data?.energy_source || "Unknown"
            }</span>
          </div>
        </div>
      </div>
    `;
  }

  function renderComparisonChart() {
    const chartContainer = document.getElementById("comparison-chart");
    if (!chartContainer || !results.ranked_aerators) return;

    // Create canvas
    const canvas = document.createElement("canvas");
    canvas.id = "aerator-chart";
    chartContainer.appendChild(canvas);

    // Prepare data
    const aerators = results.ranked_aerators.slice(0, 5); // Top 5
    const labels = aerators.map((a) => a.type);
    const costData = aerators.map((a) => a.total_cost);
    const efficiencyData = aerators.map((a) => a.aeration_efficiency * 100); // Convert to percentage

    // Create chart
    new Chart(canvas, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Total Cost ($)",
            data: costData,
            backgroundColor: "rgba(30, 64, 175, 0.7)",
            borderColor: "rgba(30, 64, 175, 1)",
            borderWidth: 1,
            yAxisID: "y",
          },
          {
            label: "Efficiency (%)",
            data: efficiencyData,
            backgroundColor: "rgba(96, 165, 250, 0.7)",
            borderColor: "rgba(96, 165, 250, 1)",
            borderWidth: 1,
            type: "line",
            yAxisID: "y1",
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            type: "linear",
            display: true,
            position: "left",
            title: {
              display: true,
              text: "Total Cost ($)",
            },
          },
          y1: {
            type: "linear",
            display: true,
            position: "right",
            title: {
              display: true,
              text: "Efficiency (%)",
            },
            grid: {
              drawOnChartArea: false,
            },
          },
        },
      },
    });
  }

  function renderAeratorCards() {
    const cardsContainer = document.getElementById("aerator-cards");
    if (!cardsContainer || !results.ranked_aerators) return;

    // Clear existing cards
    cardsContainer.innerHTML = "";

    // Create cards for aerators
    results.ranked_aerators.forEach((aerator, index) => {
      const card = document.createElement("div");
      card.className = "aerator-card";
      if (index === 0) card.classList.add("recommended");

      card.innerHTML = `
        <div class="aerator-header">
          <h3>${aerator.type}</h3>
          ${
            index === 0
              ? '<span class="recommended-badge">Recommended</span>'
              : ""
          }
        </div>
        <div class="aerator-details">
          <div class="detail-row">
            <span class="detail-label">Total Cost:</span>
            <span class="detail-value">$${aerator.total_cost.toFixed(2)}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Initial Investment:</span>
            <span class="detail-value">$${aerator.initial_investment.toFixed(
              2
            )}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Operation Cost:</span>
            <span class="detail-value">$${aerator.operation_cost.toFixed(
              2
            )}/year</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Efficiency:</span>
            <span class="detail-value">${(
              aerator.aeration_efficiency * 100
            ).toFixed(1)}%</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Energy Consumption:</span>
            <span class="detail-value">${aerator.energy_consumption.toFixed(
              2
            )} kWh</span>
          </div>
        </div>
      `;

      cardsContainer.appendChild(card);
    });
  }
}

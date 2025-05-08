import { jsPDF } from "jspdf";
// Import and apply the autotable plugin
import autoTable from "jspdf-autotable";

// Formatter functions
function formatCurrencyK(value) {
  if (!value && value !== 0) return "0.00";
  if (value >= 1000000) return `${(value / 1000000).toFixed(2)}M`;
  if (value >= 1000) return `${(value / 1000).toFixed(2)}K`;
  return value.toFixed(2);
}

function formatPaybackPeriod(years) {
  if (years === null || years === undefined || years < 0) return "N/A";
  if (!isFinite(years)) return "Never";
  if (years > 100) return "> 100 years";

  if (years < 0.08) {
    const days = Math.round(years * 365);
    return `${days} day${days !== 1 ? "s" : ""}`;
  }

  if (years < 1) {
    const months = Math.floor(years * 12);
    const days = Math.round((years * 365) % 30);
    if (days > 0)
      return `${months} month${months !== 1 ? "s" : ""} ${days} day${
        days !== 1 ? "s" : ""
      }`;
    return `${months} month${months !== 1 ? "s" : ""}`;
  }

  const wholeYears = Math.floor(years);
  const months = Math.round((years - wholeYears) * 12);
  if (months > 0)
    return `${wholeYears} year${wholeYears !== 1 ? "s" : ""} ${months} month${
      months !== 1 ? "s" : ""
    }`;
  return `${wholeYears} year${wholeYears !== 1 ? "s" : ""}`;
}

/**
 * Generates a PDF report of aerator comparison results
 * @param {Object} results - The results data object
 * @returns {Promise<jsPDF>} - The PDF document
 */
export async function generatePdf(results) {
  // Create PDF document
  const pdf = new jsPDF({
    orientation: "portrait",
    unit: "mm",
    format: "a4",
  });

  // Add plugin to jsPDF instance
  autoTable(pdf);

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
    yPosition += 7;

    pdf.setFontSize(10);
    pdf.text(
      `Energy: $${formatCurrencyK(aerator.annual_energy_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Maintenance: $${formatCurrencyK(aerator.annual_maintenance_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Replacement: $${formatCurrencyK(aerator.annual_replacement_cost)}`,
      25,
      yPosition
    );
    yPosition += 5;
    pdf.text(
      `Total Annual Cost: $${formatCurrencyK(aerator.total_annual_cost)}`,
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
      pdf.text(`${name}: $${price.toFixed(2)}`, 20, yPosition);
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
  yPosition += 5;
  pdf.text(`Temperature: ${farm.temperature || "N/A"} °C`, 20, yPosition);
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

  // Add footer
  const totalPages = pdf.internal.getNumberOfPages();
  for (let i = 1; i <= totalPages; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.setTextColor(100, 100, 100);
    pdf.text(
      `AeraSync Report - Page ${i} of ${totalPages}`,
      pdf.internal.pageSize.width / 2,
      pdf.internal.pageSize.height - 10,
      { align: "center" }
    );
  }

  return pdf;
}

/**
 * Downloads the PDF with a specified filename
 * @param {Object} results - The results data object
 * @returns {Promise<boolean>} - Promise resolving to success status
 */
export async function downloadPdf(results) {
  try {
    const pdf = await generatePdf(results);
    pdf.save(`aerasync-report-${new Date().toISOString().split("T")[0]}.pdf`);
    return true;
  } catch (err) {
    console.error("PDF generation failed:", err);
    return false;
  }
}

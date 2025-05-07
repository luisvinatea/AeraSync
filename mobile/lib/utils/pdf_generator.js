import { jsPDF } from "jspdf";
import "jspdf-autotable";
import { formatCurrencyK, formatPaybackPeriod } from "./formatting_utils.js";

/**
 * Generates PDF export of comparison results
 * @param {Object} results - The comparison results data
 * @returns {Promise<Blob>} - PDF file as a Blob
 */
export async function generatePdf(results) {
  try {
    const surveyData = results.surveyData || {};
    const aeratorResults = results.aeratorResults || [];
    const winnerLabel = results.winnerLabel || "Unknown";

    // Create PDF document
    const pdf = new jsPDF({
      orientation: "portrait",
      unit: "mm",
      format: "a4",
      compress: true,
    });

    // Set consistent fonts
    pdf.setFont("helvetica", "normal");

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
      `Annual Revenue: ${formatCurrencyK(results.annual_revenue || 0)}`,
      20,
      52
    );
    pdf.text(`Recommended Aerator: ${winnerLabel}`, 20, 59);

    // Aerator comparison table
    pdf.setFontSize(16);
    pdf.text("Aerator Comparison", 15, 75);

    const tableData = aeratorResults.map((aerator) => [
      aerator.name === winnerLabel
        ? `${aerator.name} (Recommended)`
        : aerator.name,
      aerator.num_aerators,
      formatCurrencyK(aerator.total_initial_cost),
      formatCurrencyK(aerator.total_annual_cost),
      formatCurrencyK(aerator.npv_savings),
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
      theme: "striped",
      headStyles: { fillColor: [30, 64, 175], textColor: [255, 255, 255] },
      styles: { fontSize: 9, cellPadding: 2 },
      columnStyles: {
        0: { cellWidth: 35 },
        1: { cellWidth: 15, halign: "center" },
        2: { cellWidth: 25, halign: "right" },
        3: { cellWidth: 25, halign: "right" },
        4: { cellWidth: 25, halign: "right" },
        5: { cellWidth: 20, halign: "right" },
        6: { cellWidth: 25, halign: "right" },
      },
      margin: { left: 15, right: 15 },
    });

    // Cost breakdown for each aerator
    let yPosition = pdf.lastAutoTable.finalY + 15;
    pdf.setFontSize(16);
    pdf.text("Cost Breakdown", 15, yPosition);
    yPosition += 10;

    const costBreakdownData = aeratorResults.map((aerator) => [
      aerator.name === winnerLabel
        ? `${aerator.name} (Recommended)`
        : aerator.name,
      formatCurrencyK(aerator.annual_energy_cost),
      formatCurrencyK(aerator.annual_maintenance_cost),
      formatCurrencyK(aerator.annual_replacement_cost),
      formatCurrencyK(aerator.total_annual_cost),
    ]);

    pdf.autoTable({
      startY: yPosition,
      head: [
        [
          "Aerator",
          "Energy Cost",
          "Maintenance",
          "Replacement",
          "Total Annual",
        ],
      ],
      body: costBreakdownData,
      theme: "striped",
      headStyles: { fillColor: [30, 64, 175], textColor: [255, 255, 255] },
      styles: { fontSize: 9, cellPadding: 2 },
      columnStyles: {
        0: { cellWidth: 35 },
        1: { cellWidth: 25, halign: "right" },
        2: { cellWidth: 25, halign: "right" },
        3: { cellWidth: 25, halign: "right" },
        4: { cellWidth: 30, halign: "right" },
      },
      margin: { left: 15, right: 15 },
    });

    // Equilibrium prices
    yPosition = pdf.lastAutoTable.finalY + 15;

    const equilibriumPrices = results.equilibriumPrices || {};

    if (Object.keys(equilibriumPrices).length > 0) {
      pdf.setFontSize(16);
      pdf.text("Equilibrium Prices", 15, yPosition);
      yPosition += 10;

      const equilibriumData = Object.entries(equilibriumPrices).map(
        ([name, price]) => [name, formatCurrencyK(price)]
      );

      pdf.autoTable({
        startY: yPosition,
        head: [["Aerator", "Equilibrium Price"]],
        body: equilibriumData,
        theme: "striped",
        headStyles: { fillColor: [30, 64, 175], textColor: [255, 255, 255] },
        styles: { fontSize: 9, cellPadding: 2 },
        columnStyles: {
          0: { cellWidth: 60 },
          1: { cellWidth: 40, halign: "right" },
        },
        margin: { left: 15, right: 15 },
      });

      yPosition = pdf.lastAutoTable.finalY + 15;
    }

    // If we're close to the bottom of the page, add a new one
    if (yPosition > 240) {
      pdf.addPage();
      yPosition = 20;
    }

    // Survey inputs
    pdf.setFontSize(16);
    pdf.text("Survey Inputs", 15, yPosition);
    yPosition += 10;

    // Farm details
    const farmData = [
      ["Farm Area", `${surveyData.farm?.farm_area_ha || "N/A"} ha`],
      ["Shrimp Price", `$${surveyData.farm?.shrimp_price || "N/A"}/kg`],
      ["Culture Days", `${surveyData.farm?.culture_days || "N/A"} days`],
      [
        "Shrimp Density",
        `${surveyData.farm?.shrimp_density_kg_m3 || "N/A"} kg/m³`,
      ],
      ["Pond Depth", `${surveyData.farm?.pond_depth_m || "N/A"} m`],
    ];

    pdf.autoTable({
      startY: yPosition,
      head: [["Farm Specifications", "Value"]],
      body: farmData,
      theme: "plain",
      headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
      styles: { fontSize: 9, cellPadding: 2 },
      margin: { left: 15, right: 15 },
    });

    yPosition = pdf.lastAutoTable.finalY + 10;

    // Financial details
    const financialData = [
      ["Energy Cost", `$${surveyData.financial?.energy_cost || "N/A"}/kWh`],
      ["Hours Per Night", `${surveyData.financial?.hours_per_night || "N/A"}`],
      [
        "Discount Rate",
        `${
          surveyData.financial?.discount_rate
            ? (surveyData.financial.discount_rate * 100).toFixed(1)
            : "N/A"
        }%`,
      ],
      [
        "Inflation Rate",
        `${
          surveyData.financial?.inflation_rate
            ? (surveyData.financial.inflation_rate * 100).toFixed(1)
            : "N/A"
        }%`,
      ],
      ["Analysis Horizon", `${surveyData.financial?.horizon || "N/A"} years`],
      [
        "Safety Margin",
        `${
          surveyData.financial?.safety_margin
            ? (surveyData.financial.safety_margin * 100).toFixed(1)
            : "N/A"
        }%`,
      ],
      ["Temperature", `${surveyData.financial?.temperature || "N/A"} °C`],
    ];

    pdf.autoTable({
      startY: yPosition,
      head: [["Financial Aspects", "Value"]],
      body: financialData,
      theme: "plain",
      headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
      styles: { fontSize: 9, cellPadding: 2 },
      margin: { left: 15, right: 15 },
    });

    yPosition = pdf.lastAutoTable.finalY + 10;

    // If we're close to the bottom of the page, add a new one
    if (yPosition > 220) {
      pdf.addPage();
      yPosition = 20;
    }

    // Aerator 1 & 2 details (side by side if possible)
    const aerator1 = surveyData.aerator1 || {};
    const aerator2 = surveyData.aerator2 || {};

    const aerator1Data = [
      ["Name", aerator1.name || "N/A"],
      ["Power", `${aerator1.power_hp || "N/A"} HP`],
      ["SOTR", `${aerator1.sotr || "N/A"} kg O₂/h`],
      ["Cost", `$${aerator1.cost || "N/A"}`],
      ["Durability", `${aerator1.durability || "N/A"} years`],
      ["Maintenance", `$${aerator1.maintenance || "N/A"}/year`],
    ];

    const aerator2Data = [
      ["Name", aerator2.name || "N/A"],
      ["Power", `${aerator2.power_hp || "N/A"} HP`],
      ["SOTR", `${aerator2.sotr || "N/A"} kg O₂/h`],
      ["Cost", `$${aerator2.cost || "N/A"}`],
      ["Durability", `${aerator2.durability || "N/A"} years`],
      ["Maintenance", `$${aerator2.maintenance || "N/A"}/year`],
    ];

    // Determine if we can fit both tables side by side
    const pageWidth = pdf.internal.pageSize.getWidth();
    if (pageWidth >= 150) {
      // Two columns layout
      pdf.autoTable({
        startY: yPosition,
        head: [["Aerator 1", "Value"]],
        body: aerator1Data,
        theme: "plain",
        headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
        styles: { fontSize: 9, cellPadding: 2 },
        margin: { left: 15, right: pageWidth / 2 + 5 },
      });

      pdf.autoTable({
        startY: yPosition,
        head: [["Aerator 2", "Value"]],
        body: aerator2Data,
        theme: "plain",
        headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
        styles: { fontSize: 9, cellPadding: 2 },
        margin: { left: pageWidth / 2 + 5, right: 15 },
      });
    } else {
      // One column layout (stacked)
      pdf.autoTable({
        startY: yPosition,
        head: [["Aerator 1", "Value"]],
        body: aerator1Data,
        theme: "plain",
        headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
        styles: { fontSize: 9, cellPadding: 2 },
        margin: { left: 15, right: 15 },
      });

      yPosition = pdf.lastAutoTable.finalY + 10;

      pdf.autoTable({
        startY: yPosition,
        head: [["Aerator 2", "Value"]],
        body: aerator2Data,
        theme: "plain",
        headStyles: { fillColor: [200, 220, 255], textColor: [0, 0, 0] },
        styles: { fontSize: 9, cellPadding: 2 },
        margin: { left: 15, right: 15 },
      });
    }

    // Add footer on all pages
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

    return pdf.output("blob");
  } catch (error) {
    console.error("Error generating PDF:", error);
    throw error;
  }
}

/**
 * Downloads the generated PDF
 * @param {Blob} pdfBlob - The PDF file as a Blob
 * @param {string} filename - The filename for the downloaded file
 */
export function downloadPdf(pdfBlob, filename = "aerasync-comparison.pdf") {
  // Create a download link and trigger it
  const url = URL.createObjectURL(pdfBlob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

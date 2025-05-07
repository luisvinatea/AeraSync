/**
 * Generates PDF export of comparison results
 * @param {Object} results - The comparison results data
 * @returns {Promise<Blob>} - PDF file as a Blob
 */
export async function generatePdf(results) {
  try {
    // This is just a placeholder function - in a real implementation,
    // we would integrate with a PDF generation library

    // For the mobile web version, we'd likely call an API endpoint
    // that generates the PDF since client-side PDF generation is resource-intensive

    // Fetch the PDF from API
    const response = await fetch(`/api/generate-pdf`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(results),
    });

    if (!response.ok) {
      throw new Error("Failed to generate PDF");
    }

    return await response.blob();
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

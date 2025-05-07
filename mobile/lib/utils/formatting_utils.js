/**
 * Format currency value with K/M suffix for better readability
 * @param {number} value - The currency value to format
 * @returns {string} Formatted currency string
 */
export function formatCurrencyK(value) {
  if (value >= 1000000) return `$${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `$${(value / 1000).toFixed(1)}K`;
  return `$${value.toFixed(2)}`;
}

/**
 * Format payback period based on years value
 * @param {number} paybackYears - Payback period in years
 * @returns {string} Formatted payback period string
 */
export function formatPaybackPeriod(paybackYears) {
  if (paybackYears === null || paybackYears === undefined || paybackYears < 0)
    return "N/A";
  if (!isFinite(paybackYears)) return "Never";
  if (paybackYears > 100) return ">100 years";

  // For very short payback periods (less than 30 days)
  if (paybackYears < 0.08) {
    const days = Math.round(paybackYears * 365);
    return `${days} ${days === 1 ? "day" : "days"}`;
  }

  // For periods less than a year - show months and days
  if (paybackYears < 1) {
    const monthsTotal = paybackYears * 12;
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
  const years = Math.floor(paybackYears);
  const months = Math.round((paybackYears - years) * 12);

  if (months > 0) {
    return `${years} ${years === 1 ? "year" : "years"}, ${months} ${
      months === 1 ? "month" : "months"
    }`;
  } else {
    return `${years} ${years === 1 ? "year" : "years"}`;
  }
}

/**
 * Format ROI percentage with proper suffixes
 * @param {number} roi - Return on investment percentage
 * @param {boolean} isWinner - Whether this is the recommended option
 * @returns {string} Formatted ROI string
 */
export function formatROI(roi, isWinner = false) {
  if (roi <= 0 && !isWinner) {
    return "N/A";
  }

  if (roi >= 1000) {
    if (roi >= 1000000) {
      return `${(roi / 1000000).toFixed(2)}M%`;
    }
    return `${(roi / 1000).toFixed(2)}K%`;
  }

  return `${roi.toFixed(2)}%`;
}

/**
 * Format profitability index with K/M suffix
 * @param {number} k - Profitability index
 * @returns {string} Formatted profitability index
 */
export function formatProfitabilityK(k) {
  if (k >= 1000000) return `${(k / 1000000).toFixed(2)}M`;
  if (k >= 1000) return `${(k / 1000).toFixed(2)}K`;
  return k.toFixed(2);
}

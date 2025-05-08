/**
 * Formats a currency value with K/M suffix for large numbers
 * @param {number} value - The value to format
 * @returns {string} - Formatted currency string
 */
export function formatCurrencyK(value) {
  if (!value && value !== 0) return "0.00";

  if (value >= 1000000) {
    return `${(value / 1000000).toFixed(2)}M`;
  }
  if (value >= 1000) {
    return `${(value / 1000).toFixed(2)}K`;
  }
  return value.toFixed(2);
}

/**
 * Formats a profitability value with special handling for negative values
 * @param {number} value - The profitability value
 * @returns {string} - Formatted profitability string
 */
export function formatProfitabilityK(value) {
  if (value === null || value === undefined || value < 0) {
    return "N/A";
  }
  return value.toFixed(2);
}

/**
 * Formats a payback period in years to a readable format
 * @param {number} years - Payback period in years
 * @returns {string} - Formatted payback period
 */
export function formatPaybackPeriod(years) {
  if (years === null || years === undefined || years < 0) {
    return "N/A";
  }

  if (!isFinite(years)) {
    return "Never";
  }

  if (years > 100) {
    return "> 100 years";
  }

  // For very short payback periods (less than 30 days)
  if (years < 0.08) {
    const days = Math.round(years * 365);
    return `${days} day${days !== 1 ? "s" : ""}`;
  }

  // For periods less than a year - show months and days
  if (years < 1) {
    const months = Math.floor(years * 12);
    const days = Math.round((years * 365) % 30);

    if (days > 0) {
      return `${months} month${months !== 1 ? "s" : ""} ${days} day${
        days !== 1 ? "s" : ""
      }`;
    } else {
      return `${months} month${months !== 1 ? "s" : ""}`;
    }
  }

  // More than a year - show years and months
  const wholeYears = Math.floor(years);
  const months = Math.round((years - wholeYears) * 12);

  if (months > 0) {
    return `${wholeYears} year${wholeYears !== 1 ? "s" : ""} ${months} month${
      months !== 1 ? "s" : ""
    }`;
  } else {
    return `${wholeYears} year${wholeYears !== 1 ? "s" : ""}`;
  }
}

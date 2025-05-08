/**
 * Formats a currency value for display
 * @param {number} value - The value to format
 * @returns {string} - Formatted currency string
 */
export function formatCurrency(value) {
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
 * Formats a percentage value for display
 * @param {number} value - The percentage value
 * @returns {string} - Formatted percentage string
 */
export function formatPercent(value) {
  if (!value && value !== 0) return "0.00%";
  return `${value.toFixed(2)}%`;
}

/**
 * Formats a payback period in years to a readable string
 * @param {number} years - The payback period in years
 * @param {Object} translations - Translation dictionary for i18n support
 * @returns {string} - Formatted payback period
 */
export function formatPaybackPeriod(years, translations = {}) {
  const t = (key) => translations[key] || key;

  if (years === null || years === undefined || years < 0) {
    return t("notApplicable");
  }

  if (!isFinite(years)) {
    return "Never";
  }

  if (years > 100) {
    return "> 100 " + t("years");
  }

  // For very short payback periods (less than 30 days)
  if (years < 0.08) {
    const days = Math.round(years * 365);
    return `${days} ${days !== 1 ? t("days") : t("day")}`;
  }

  // For periods less than a year - show months and days
  if (years < 1) {
    const months = Math.floor(years * 12);
    const days = Math.round((years * 365) % 30);

    if (days > 0) {
      return `${months} ${months !== 1 ? t("months") : t("month")} ${days} ${
        days !== 1 ? t("days") : t("day")
      }`;
    } else {
      return `${months} ${months !== 1 ? t("months") : t("month")}`;
    }
  }

  // More than a year - show years and months
  const wholeYears = Math.floor(years);
  const months = Math.round((years - wholeYears) * 12);

  if (months > 0) {
    return `${wholeYears} ${
      wholeYears !== 1 ? t("years") : t("year")
    } ${months} ${months !== 1 ? t("months") : t("month")}`;
  } else {
    return `${wholeYears} ${wholeYears !== 1 ? t("years") : t("year")}`;
  }
}

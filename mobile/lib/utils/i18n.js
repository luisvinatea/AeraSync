// Available languages
const LANGUAGES = {
  en: "English",
  es: "Español",
};

// Default language
const DEFAULT_LANG = "en";

/**
 * Gets translations for the specified language
 * @param {string} lang - Language code (e.g., 'en', 'es')
 * @returns {Promise<Object>} - Translation dictionary
 */
export async function getTranslations(lang = DEFAULT_LANG) {
  try {
    const response = await fetch(`/i18n/${lang}.json`);
    if (!response.ok) {
      console.warn(
        `Could not load translations for ${lang}, falling back to English`
      );
      const fallback = await fetch(`/i18n/en.json`);
      return await fallback.json();
    }
    return await response.json();
  } catch (error) {
    console.error("Error loading translations:", error);
    return getDefaultTranslations();
  }
}

/**
 * Initializes language detection and setting
 * @returns {string} - Detected or saved language code
 */
export function initLanguage() {
  // Check for stored language preference
  let lang = localStorage.getItem("aerasync_lang") || "";

  // If no stored preference, try to detect from browser
  if (!lang) {
    const browserLang = navigator.language.split("-")[0];
    lang = Object.keys(LANGUAGES).includes(browserLang)
      ? browserLang
      : DEFAULT_LANG;
    localStorage.setItem("aerasync_lang", lang);
  }

  return lang;
}

/**
 * Sets up language toggle functionality
 * @param {Object} app - The main application object
 */
export function setupLanguageToggle(app) {
  const langToggle = document.getElementById("language-toggle");
  if (!langToggle) return;

  // Display current language
  langToggle.textContent = app.lang.toUpperCase();

  // Toggle between available languages
  langToggle.addEventListener("click", () => {
    const currentLang = app.lang;
    const langs = Object.keys(LANGUAGES);
    const currentIndex = langs.indexOf(currentLang);
    const nextIndex = (currentIndex + 1) % langs.length;
    const newLang = langs[nextIndex];

    localStorage.setItem("aerasync_lang", newLang);
    app.lang = newLang;
    langToggle.textContent = newLang.toUpperCase();

    // Reload translations and update UI
    app.loadTranslations(newLang).then(() => app.updateUI());
  });
}

/**
 * Provides default English translations in case loading fails
 * @returns {Object} - English translations
 */
function getDefaultTranslations() {
  return {
    // General
    appName: "AeraSync",
    loading: "Loading...",
    back: "Back",
    next: "Next",
    submit: "Submit",
    results: "Results",
    error: "Error",
    success: "Success",

    // Navigation
    home: "Home",
    survey: "Survey",

    // Survey sections
    farmSpecs: "Farm Specifications",
    aeratorDetails: "Aerator Details",
    financialAspects: "Financial Aspects",

    // Results
    summaryMetrics: "Summary Metrics",
    aeratorComparisonResults: "Aerator Comparison Results",
    equilibriumPrices: "Equilibrium Prices",
    costBreakdownVisualization: "Cost Breakdown",
    costEvolutionVisualization: "Cost Evolution",
    newComparison: "New Comparison",
    exportToPdf: "Export to PDF",
    recommended: "Recommended",

    // Error messages
    submissionFailed: "Submission failed. Please try again.",
    networkError: "Network error. Please check your connection.",
    invalidInput: "Please check your inputs and try again.",
  };
}

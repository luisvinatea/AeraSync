// Available languages
const LANGUAGES = {
  en: "English",
  es: "Español",
  pt: "Português",
};

// Default language
const DEFAULT_LANG = "en";

/**
 * Gets translations for the specified language
 * @param {string} lang - Language code (e.g., 'en', 'es', 'pt')
 * @returns {Promise<Object>} - Translation dictionary
 */
export async function getTranslations(lang = DEFAULT_LANG) {
  try {
    const response = await fetch(`/i18n/${lang}.json`);
    if (!response.ok) {
      console.warn(
        `Could not load translations for ${lang}, falling back to English`
      );
      return getDefaultTranslations();
    }

    // Get the response as text first to check for HTML errors
    const text = await response.text();

    // Check if the response is HTML (error page) instead of JSON
    if (text.trim().startsWith("<!")) {
      console.warn(
        `Received HTML instead of JSON for ${lang}, falling back to default translations`
      );
      return getDefaultTranslations();
    }

    // Parse the JSON if it's valid
    try {
      return JSON.parse(text);
    } catch (parseError) {
      console.error("Error parsing JSON:", parseError);
      return getDefaultTranslations();
    }
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
 * Applies translations to all elements with data-i18n attributes
 * @param {Object} translations - Translation dictionary
 */
export function applyTranslations(translations) {
  const elements = document.querySelectorAll("[data-i18n]");

  elements.forEach((element) => {
    const key = element.getAttribute("data-i18n");
    if (translations[key]) {
      // For input placeholders
      if (element.hasAttribute("placeholder")) {
        element.setAttribute("placeholder", translations[key]);
      }
      // For buttons, labels, etc.
      else {
        element.textContent = translations[key];
      }
    }
  });
}

/**
 * Gets translated text for a specific key
 * @param {Object} translations - Translation dictionary
 * @param {string} key - Translation key
 * @param {string} defaultText - Fallback text if key not found
 * @returns {string} - Translated text
 */
export function t(translations, key, defaultText = key) {
  return translations[key] || defaultText;
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
    welcomeToAeraSync: "Welcome to AeraSync",
    startComparison: "Start Comparison",
    appDescription:
      "Compare aerators for shrimp farming with a step-by-step survey and view ranked results.",

    // Survey sections
    farmSpecs: "Farm Specifications",
    aeratorDetails: "Aerator Details",
    financialAspects: "Financial Aspects",

    // Farm specs fields
    totalOxygenDemand: "Total Oxygen Demand (kg O₂/h)",
    farmArea: "Farm Area (ha)",
    shrimpPrice: "Shrimp Price (USD/kg)",
    cultureDays: "Culture Days",
    shrimpDensity: "Shrimp Density (kg/m³)",
    pondDepth: "Pond Depth (m)",
    temperature: "Temperature (°C)",

    // Aerator fields
    aeratorName: "Aerator Name",
    power: "Power (HP)",
    sotr: "SOTR (kg O₂/h)",
    price: "Price (USD)",
    durability: "Durability (years)",
    maintenanceCost: "Maintenance Cost (USD/year)",

    // Financial fields
    energyCost: "Energy Cost (USD/kWh)",
    hoursPerNight: "Hours Per Night",
    discountRate: "Discount Rate (%)",
    inflationRate: "Inflation Rate (%)",
    analysisHorizon: "Analysis Horizon (years)",
    safetyMargin: "Safety Margin (%)",

    // Validation
    requiredField: "This field is required",
    invalidInput: "Please enter a valid value",

    // Results page
    summaryMetrics: "Summary Metrics",
    aeratorComparisonResults: "Aerator Comparison Results",
    equilibriumPrices: "Equilibrium Prices",
    costBreakdownVisualization: "Cost Breakdown",
    costEvolutionVisualization: "Cost Evolution",
    newComparison: "New Comparison",
    exportToPdf: "Export to PDF",
    recommended: "Recommended",

    // Summary section
    surveyInputs: "Survey Inputs",
    annualRevenue: "Annual Revenue",
    recommendedAerator: "Recommended Aerator",

    // Comparison metrics
    unitsRequired: "Units Required",
    unitsPerHectare: "Units per Hectare",
    hpPerHa: "HP per Ha",
    initialCost: "Initial Cost",
    annualCost: "Annual Cost",
    costPercentRevenue: "Cost/Revenue",
    energyCostLabel: "Energy Cost",
    maintenanceLabel: "Maintenance Cost",
    npvSavings: "NPV Savings",
    paybackPeriod: "Payback Period",
    roi: "ROI",
    profitabilityIndex: "Profitability Index",
    sae: "SAE",
    costPerKgO2: "Cost per kg O₂",

    // Time units
    year: "year",
    years: "years",
    month: "month",
    months: "months",
    day: "day",
    days: "days",
    notApplicable: "N/A",

    // Other
    noEquilibriumPrices: "No equilibrium prices available",
    generating: "Generating PDF...",
    exportFailed: "Export Failed",
  };
}

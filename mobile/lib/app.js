import { initSurveyForm } from "./components/survey.js";
import { initResultsView } from "./components/results.js";
import { getTranslations } from "./utils/i18n.js";
import { apiService } from "./utils/api.js";
import { applyDeviceOptimizations } from "./utils/device.js";
import { API_URL } from "./config.js";

export function initApp() {
  // Apply mobile optimizations
  applyDeviceOptimizations();

  const app = {
    currentPage: "home",
    lang: "en",
    translations: {},
    surveyData: {},
    results: null,
    apiUrl: API_URL,

    async init() {
      this.translations = await getTranslations(this.lang);
      this.setupEventListeners();
      this.renderApp();
      this.checkApiHealth();
      this.hideLoading();
    },

    setupEventListeners() {
      window.addEventListener("popstate", () => this.handleRouting());
      document.addEventListener("click", (e) => {
        if (e.target.matches("[data-nav]")) {
          e.preventDefault();
          this.navigate(e.target.getAttribute("data-nav"));
        }
      });
    },

    handleRouting() {
      const path = window.location.hash.substring(1) || "home";
      this.showPage(path);
    },

    navigate(page) {
      window.history.pushState(null, "", `#${page}`);
      this.showPage(page);
    },

    showPage(page) {
      this.currentPage = page;
      document
        .querySelectorAll(".page")
        .forEach((p) => (p.style.display = "none"));
      const currentPage = document.getElementById(`${page}-page`);
      if (currentPage) {
        currentPage.style.display = "block";

        if (page === "survey") {
          initSurveyForm(this);
        } else if (page === "results" && this.results) {
          initResultsView(this);
        }
      }
    },

    renderApp() {
      this.handleRouting();
    },

    hideLoading() {
      const loader = document.getElementById("loading-screen");
      if (loader) {
        loader.style.opacity = "0";
        setTimeout(() => (loader.style.display = "none"), 500);
      }
    },

    async checkApiHealth() {
      try {
        const isHealthy = await apiService.checkHealth();
        if (!isHealthy) {
          console.warn("API health check failed");
        }
      } catch (error) {
        console.error("Error checking API health:", error);
      }
    },

    async submitSurvey(formData) {
      try {
        this.surveyData = formData;

        // Use API service
        this.results = await apiService.submitSurvey(formData);
        this.navigate("results");
        return this.results;
      } catch (error) {
        console.error("Error submitting survey:", error);
        this.showError(error.message || "Failed to submit survey data");
      }
    },

    showError(message) {
      const errorEl = document.getElementById("error-toast");
      if (errorEl) {
        errorEl.textContent = message;
        errorEl.classList.add("show");
        setTimeout(() => errorEl.classList.remove("show"), 4000);
      }
    },
  };

  app.init();
  return app;
}

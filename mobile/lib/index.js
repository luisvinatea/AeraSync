import "sanitize.css";
import "./styles.css";
import { initApp } from "./app.js";
import { setupServiceWorker } from "./utils/service-worker.js";

document.addEventListener("DOMContentLoaded", () => {
  initApp();
  setupServiceWorker();
});

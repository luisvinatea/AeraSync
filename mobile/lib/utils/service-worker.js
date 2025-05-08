/**
 * Registers the service worker for the app
 */
export function setupServiceWorker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker
        .register("/service-worker.js")
        .then((registration) => {
          console.log(
            "ServiceWorker registration successful with scope: ",
            registration.scope
          );
        })
        .catch((error) => {
          console.error("ServiceWorker registration failed: ", error);
        });
    });
  }
}

/**
 * Update the application cache by unregistering service workers
 * @returns {Promise<boolean>} True if update successful
 */
export async function updateAppCache() {
  if ("serviceWorker" in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      for (const registration of registrations) {
        await registration.unregister();
      }
      return true;
    } catch (error) {
      console.error("Cache update failed:", error);
      return false;
    }
  }
  return false;
}

const CACHE_NAME = "aerasync-mobile-v1";
const ASSETS = [
  "/",
  "/index.html",
  "/manifest.json",
  "/js/main.js",
  "/css/main.css",
  "/icons/favicon.webp",
  "/icons/logo.webp",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
];

// Install event - cache assets
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME) {
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - network first with cache fallback
self.addEventListener("fetch", (event) => {
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Clone response for caching
        const clonedResponse = response.clone();

        caches.open(CACHE_NAME).then((cache) => {
          // Only cache GET requests for specific asset types
          if (
            event.request.method === "GET" &&
            (event.request.url.includes("/js/") ||
              event.request.url.includes("/css/") ||
              event.request.url.includes("/icons/"))
          ) {
            cache.put(event.request, clonedResponse);
          }
        });

        return response;
      })
      .catch(() => {
        return caches.match(event.request).then((cachedResponse) => {
          // Return cached response or offline fallback
          if (cachedResponse) {
            return cachedResponse;
          }

          // For navigation, return the offline page
          if (event.request.mode === "navigate") {
            return caches.match("/index.html");
          }

          return new Response("Network error", {
            status: 408,
            headers: { "Content-Type": "text/plain" },
          });
        });
      })
  );
});

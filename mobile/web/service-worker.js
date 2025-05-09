const CACHE_NAME = "aerasync-mobile-v1";
const ASSETS = [
  "/",
  "/index.html",
  "/manifest.json",
  "/js/main.js",
  "/css/main.css",
  "/icons/favicon.webp",
  "/icons/watermark.webp",
  "/icons/aerasync180.png",
  "/icons/aerasync.webp",
  "/icons/aerasync_icon.svg",
  "/icons/background.webp"
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
        // If we got a valid response, clone it and update the cache
        if (!response || response.status !== 200 || response.type !== "basic") {
          return response;
        }

        const responseToCache = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });

        return response;
      })
      .catch(() => {
        // If network fetch fails, try to get from cache
        return caches.match(event.request);
      })
  );
});

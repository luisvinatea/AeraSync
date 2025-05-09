// Service worker for AeraSync PWA
const CACHE_NAME = "aerasync-cache-v1";
const OFFLINE_URL = "index.html";
const ASSETS_TO_CACHE = [
  "/",
  "index.html",
  "main.dart.js",
  "flutter.js",
  "flutter_bootstrap.js",
  "manifest.json",
  "assets/fonts/MaterialIcons-Regular.otf",
  "assets/fonts/NotoSerif-Regular.ttf",
  "assets/fonts/NotoSerif-Black.ttf",
  "assets/fonts/NotoSerif-Bold.ttf",
  "assets/fonts/NotoSerif-Italic.ttf",
  "assets/fonts/NotoSerif-BoldItalic.ttf",
  "assets/fonts/NotoSans-Regular.ttf",
  "assets/fonts/NotoSans-Black.ttf",
  "assets/fonts/NotoSans-Bold.ttf",
  "assets/fonts/NotoSans-BoldItalic.ttf",
  "assets/fonts/NotoSans-Italic.ttf",
  "icons/watermark.webp",
  "icons/background.webp",
  "assets/icons/aerasync_icon.svg",
  "assets/static/wave.svg",
  "canvaskit/canvaskit.js",
  "canvaskit/canvaskit.wasm",
];

// Install event - cache core assets
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log("[ServiceWorker] Pre-caching offline assets");
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(
        keyList.map((key) => {
          if (key !== CACHE_NAME) {
            console.log("[ServiceWorker] Removing old cache", key);
            return caches.delete(key);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache if possible
self.addEventListener("fetch", (event) => {
  // Skip cross-origin requests
  if (event.request.url.startsWith(self.location.origin)) {
    event.respondWith(
      caches.match(event.request).then((response) => {
        // Return cached response if found
        if (response) {
          return response;
        }

        // Fetch from network
        return fetch(event.request)
          .then((response) => {
            // Check if we received a valid response
            if (
              !response ||
              response.status !== 200 ||
              response.type !== "basic"
            ) {
              return response;
            }

            // Clone the response since we need to use it twice
            const responseToCache = response.clone();

            // Cache the response for future use
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseToCache);
            });

            return response;
          })
          .catch(() => {
            // If network fetch fails, return offline page for navigation requests
            if (event.request.mode === "navigate") {
              return caches.match(OFFLINE_URL);
            }
          });
      })
    );
  }
});

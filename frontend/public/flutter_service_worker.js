'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"favicon.webp": "c47a7f48fa95de062c07bcb4e6e76ff1",
"flutter_bootstrap.js": "12074fd0edb5b245f0becc22cc97805b",
"index.html": "bd31f8ea9b363b1363b999960f85b925",
"/": "bd31f8ea9b363b1363b999960f85b925",
"icons/aerasync180.webp": "fb66a85740a99e579915b01f94def02b",
"icons/aerasync64.png": "4a0fe9b747bfbbdf906470938732ca25",
"icons/aerasync.png": "76313e87c4dc958b2f5c023f69740e39",
"icons/aerasync180.png": "1709edc36cc18d58ce33074f976a25d8",
"icons/background.webp": "7f136cef044e916827e19d2bc074153e",
"icons/aerasync.webp": "f6a0d6a39601a30257dade84f4ecb08d",
"icons/watermark.webp": "194ddacc7783f40601658f6aa89584da",
"icons/aerasync64.webp": "08014e88337bf135714c4cf99c4baeb1",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"assets/web/icons/aerasync180.webp": "fb66a85740a99e579915b01f94def02b",
"assets/web/icons/background.webp": "7f136cef044e916827e19d2bc074153e",
"assets/web/icons/aerasync.webp": "f6a0d6a39601a30257dade84f4ecb08d",
"assets/web/icons/aerasync64.webp": "08014e88337bf135714c4cf99c4baeb1",
"assets/web/assets/wave.svg": "5516c44a9fbdc7d8d6bedbc1385a65c3",
"assets/web/fonts/NotoSerif-Black.ttf": "4c3a3d4839b80e97610b7f175956c2be",
"assets/web/fonts/NotoSerif-BoldItalic.ttf": "91d0e6f48c74a826f00cf9be25f55be1",
"assets/web/fonts/NotoSerif-BlackItalic.ttf": "dc79f1ec7faafb84ae8fde2f03f41d28",
"assets/web/fonts/NotoSerif-Bold.ttf": "619d81e0d70ea90db309b131ebc52ede",
"assets/wave.svg": "5516c44a9fbdc7d8d6bedbc1385a65c3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.bin": "da480c1895ac8209b4db7bf29987c665",
"assets/AssetManifest.bin.json": "e42cbaaa41fc368269647c9416a18dda",
"assets/NOTICES": "678d39cec484cee2a0864d4ce45a2f29",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "bc501f7741968bb48fa58fe75f3c5b03",
"assets/AssetManifest.json": "b841aea8e2b0a6caef1d9a0b8156baf7",
"main.dart.js": "fcabf88f96ff41448eb01d636803ff1a",
"fonts/NotoSerif-Black.ttf": "4c3a3d4839b80e97610b7f175956c2be",
"fonts/NotoSerif-BoldItalic.ttf": "91d0e6f48c74a826f00cf9be25f55be1",
"fonts/NotoSerif-BlackItalic.ttf": "dc79f1ec7faafb84ae8fde2f03f41d28",
"fonts/NotoSerif-Bold.ttf": "619d81e0d70ea90db309b131ebc52ede",
"manifest.json": "3a360d04b35689d16428e621dbea3375",
"version.json": "dcbfb966ebfd8b4b032c9107c204633a",
"privacy.html": "c0dc0fee494b0d25aeab233dca23530b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

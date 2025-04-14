'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"index.html": "f676e62713ecc4aaea99a3b47a88dec8",
"/": "f676e62713ecc4aaea99a3b47a88dec8",
"assets/wave.svg": "5516c44a9fbdc7d8d6bedbc1385a65c3",
"assets/NOTICES": "ab412c567706122c68bf3ae956e47970",
"assets/assets/data/shrimp_respiration_salinity_temperature_weight.json": "098806c26f9b18d79c0ebda5ad372fa3",
"assets/assets/data/o2_temp_sal_100_sat.json": "95941d4fb5a4f0f50e420bb32d20dcb5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "5394393a394ac2924e7adfff7b18cba7",
"assets/fonts/MaterialIcons-Regular.otf": "8084e174286d34e710d843851c2f0514",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "96d9c8b69cfaf88f3f8bcb04f1cc850c",
"assets/web/assets/wave.svg": "5516c44a9fbdc7d8d6bedbc1385a65c3",
"assets/web/icons/aerasync.webp": "f6a0d6a39601a30257dade84f4ecb08d",
"assets/web/icons/aerasync1024.webp": "480f0e3225fa16cb15246133c6f29429",
"assets/web/icons/aerasync64.webp": "08014e88337bf135714c4cf99c4baeb1",
"assets/web/icons/aerasync64.png": "4a0fe9b747bfbbdf906470938732ca25",
"assets/web/icons/aerasync180.png": "1709edc36cc18d58ce33074f976a25d8",
"assets/web/icons/aerasync180.webp": "fb66a85740a99e579915b01f94def02b",
"assets/web/icons/aerasync512.webp": "8c83508e96f950f20f6782c99297b6f2",
"assets/web/icons/aerasync1024.png": "71dc7b23927a045bb75186ada00afd08",
"assets/web/icons/aerasync512.png": "fb88eeacb5729928128d9839ff2acf81",
"assets/web/manifest.json": "dc910af63f3e8533db7b2ddb56521855",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.json": "9fb06ac263c4dc808b48001a9d5e75c9",
"version.json": "d9ff53f69ef1ba7fdb6e7f79ae3113d4",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"main.dart.js": "a5226d1088509c45ae62095c121d0b78",
"favicon.webp": "08014e88337bf135714c4cf99c4baeb1",
"icons/aerasync300-100.png": "ad006b28ba39ea59ae1241a0ba22801d",
"icons/aerasync16.webp": "28514dee9095d32dfddd80bdb453654a",
"icons/aerasync400.webp": "f13470b9caa129eb1d96610de9f8406b",
"icons/aerasync.webp": "f6a0d6a39601a30257dade84f4ecb08d",
"icons/aerasync300-100.webp": "378edb6a7fc12801de431783097872a7",
"icons/aerasync1024.webp": "480f0e3225fa16cb15246133c6f29429",
"icons/aerasync64.webp": "08014e88337bf135714c4cf99c4baeb1",
"icons/aerasync16.png": "4a78d197267358e18d26d34cd6496881",
"icons/aerasync64.png": "4a0fe9b747bfbbdf906470938732ca25",
"icons/aerasync1500-500.png": "8c1b8a12e45b1e0c09448d8abc56720d",
"icons/aerasync1500-500.webp": "8a1254fd6a435b2a2e333d3be4881446",
"icons/aerasync180.png": "1709edc36cc18d58ce33074f976a25d8",
"icons/aerasync180.webp": "fb66a85740a99e579915b01f94def02b",
"icons/aerasync512.webp": "8c83508e96f950f20f6782c99297b6f2",
"icons/aerasync1024.png": "71dc7b23927a045bb75186ada00afd08",
"icons/aerasync512.png": "fb88eeacb5729928128d9839ff2acf81",
"icons/aerasync.png": "76313e87c4dc958b2f5c023f69740e39",
"icons/aerasync400.png": "936fae71189951962114c25354f03ea3",
"manifest.json": "dc910af63f3e8533db7b2ddb56521855",
"privacy.html": "0e430c2d88e3ca612e78d65efc1647a4",
"flutter_bootstrap.js": "b678513ff2d86cb5a80256e73624df18"};
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

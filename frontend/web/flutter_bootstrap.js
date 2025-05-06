// Import flutter.js first
const flutter_js = document.createElement("script");
flutter_js.src = "flutter.js";
flutter_js.defer = true;
document.head.appendChild(flutter_js);

// Define serviceWorkerVersion dynamically to prevent caching issues
const serviceWorkerVersion = Date.now().toString();
const flutter_build_config = {
  engineRevision: "cf56914b326edb0ccb123ffdc60f00060bd513fa",
  builds: [
    {
      compileTarget: "dart2js",
      renderer: "canvaskit",
      mainJsPath: "main.dart.js",
    },
  ],
};

// Flutter web bootstrap script
window.addEventListener("load", function () {
  if (!window._flutter) {
    console.error(
      "Flutter.js failed to load. Check if flutter.js is included properly."
    );
    return;
  }

  window._flutter.loader
    .load({
      serviceWorker: {
        serviceWorkerVersion: serviceWorkerVersion,
      },
    })
    .then(function (engineInitializer) {
      // Initialize the Flutter engine
      return engineInitializer.initializeEngine({
        // Use canvaskit renderer
        renderer: "canvaskit",
      });
    })
    .then(function (appRunner) {
      // Enable iOS Safari scrolling fix
      const iOSFix = function () {
        if (/iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream) {
          // Add touchmove listener to prevent default
          document.addEventListener(
            "touchmove",
            function (e) {
              // Don't prevent default for actual scrollable areas
              if (
                e.target.closest(".scrollable") ||
                e.target.closest(".flutter-view") ||
                e.target.closest("flt-glass-pane")
              ) {
                return;
              }
              // Allow default behavior for scrollable areas
            },
            { passive: true }
          );

          // Update Flutter's handling of touch events
          window.flutterIosScrollFix = true;

          // Override position:fixed that prevents scrolling
          const style = document.createElement("style");
          style.textContent = `
          flt-glass-pane {
            overflow: auto !important;
            -webkit-overflow-scrolling: touch !important;
          }
          .flutter-view, .scrollable {
            overflow: auto !important;
            -webkit-overflow-scrolling: touch !important;
          }
        `;
          document.head.appendChild(style);
        }
      };

      iOSFix();

      // Run the app
      appRunner.runApp();

      // Manually dispatch flutter-first-frame event after a short delay
      setTimeout(function () {
        window.dispatchEvent(new Event("flutter-first-frame"));
      }, 1000);
    })
    .catch(function (error) {
      console.error("Flutter initialization error:", error);
      document.getElementById("loading-screen").innerHTML =
        '<div class="loading"><h2>Error loading application</h2>' +
        "<p>Please refresh the page or try again later.</p></div>";
    });
});

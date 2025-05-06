// Import flutter.js first
const flutter_js = document.createElement("script");
flutter_js.src = "flutter.js";
flutter_js.defer = true;
document.head.appendChild(flutter_js);

// Define serviceWorkerVersion dynamically to prevent caching issues
const serviceWorkerVersion = Date.now().toString();

// Ensure Flutter object exists
window._flutter = window._flutter || {};

// Set Flutter build config
window._flutter.buildConfig = {
  engineRevision: "cf56914b326edb0ccb123ffdc60f00060bd513fa",
  builds: [
    {
      compileTarget: "dart2js",
      renderer: "canvaskit",
      mainJsPath: "main.dart.js",
    },
  ],
};

// Initialize Flutter manually
window.addEventListener("load", function () {
  // Load main.dart.js directly
  const mainScript = document.createElement("script");
  mainScript.src = "main.dart.js";
  mainScript.type = "application/javascript";

  // Handle script load error
  mainScript.onerror = function () {
    console.error("Failed to load main.dart.js");
    document.getElementById("loading-screen").innerHTML =
      '<div class="loading"><h2>Error loading application</h2>' +
      "<p>Please refresh the page or try again later.</p></div>";
  };

  // Enable iOS Safari scrolling fix
  const iOSFix = function () {
    if (/iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream) {
      document.addEventListener(
        "touchmove",
        function (e) {
          if (
            e.target.closest(".scrollable") ||
            e.target.closest(".flutter-view") ||
            e.target.closest("flt-glass-pane")
          ) {
            return;
          }
        },
        { passive: true }
      );

      window.flutterIosScrollFix = true;

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
  document.body.appendChild(mainScript);

  // Trigger flutter-first-frame manually after a delay
  setTimeout(function () {
    window.dispatchEvent(new Event("flutter-first-frame"));
  }, 3000);
});

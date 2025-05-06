{
  {
    flutter_js;
  }
}
{
  {
    flutter_build_config;
  }
}

// Flutter web bootstrap script
window.addEventListener("load", function () {
  _flutter.loader
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
    });
});

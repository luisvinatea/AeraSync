{{flutter_js}}
{{flutter_build_config}}

// Initialize Flutter engine
(function() {
  const hostElement = document.querySelector('#flutter-target');
  
  if (typeof _flutter !== 'undefined') {
    _flutter.loader.load({
      hostElement: hostElement
    }).then(function(appEngineInitializer) {
      return appEngineInitializer.initializeEngine();
    }).then(function(appRunner) {
      return appRunner.runApp();
    });
  }
})();
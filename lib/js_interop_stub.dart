import 'dart:js_interop';

@JS()
external void registerFlutterHandler(
    String name, JSAny Function(JSAny) callback);

void setupHandlers(JSAny Function(JSAny) callback) {
  registerFlutterHandler('setDisclosureAgreement', (JSAny agreed) {
    return callback(jsify({'disclosureAgreed': _convertToBool(agreed)}));
  });

  registerFlutterHandler('onCookiesAccepted', (JSAny _) {
    return callback(jsify({'cookiesAccepted': true}));
  });

  registerFlutterHandler('onUserLoggedIn', (JSAny userInfo) {
    return callback(jsify({'userLoggedIn': jsObjectToMap(userInfo)}));
  });
}

Map<String, dynamic> jsObjectToMap(dynamic jsObject) {
  if (jsObject == null) return {};
  return Map<String, dynamic>.from(jsObject as Map);
}

// Converts a Dart Map to a JavaScript-compatible object
JSAny jsify(Map<String, dynamic> dartObject) {
  // Implementation to convert Dart Map to JavaScript object
  // Since we're using dart:js_interop, we can convert the map to JSAny
  return dartObject.jsify() as JSAny;
}

bool _convertToBool(JSAny value) {
  // Safely convert JSAny to a Dart bool
  if (value == _dartToJSAny(true)) return true;
  if (value == _dartToJSAny(false)) return false;
  throw ArgumentError('Invalid JSAny value for boolean conversion');
}

// Helper function to convert Dart values to JSAny
JSAny _dartToJSAny(dynamic value) {
  return value.jsify() as JSAny;
}
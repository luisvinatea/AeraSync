// js_interop_stub.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb; // Correct import for kIsWeb

// Define a type alias for JSAny to avoid direct dependency on dart:js_interop
typedef JSAny = dynamic; // Fallback type for non-web environments

/// Registers a handler for JavaScript interop in web environments.
/// In non-web environments (e.g., tests), logs the call and performs a no-op.
void registerFlutterHandler(String name, JSAny Function(JSAny) callback) {
  if (!kIsWeb) {
    // No-op for non-web environments (e.g., during tests)
    developer.log('registerFlutterHandler called in non-web environment: $name');
    return;
  }
  // In web environments, this would call the actual JS interop logic.
  // Since this is a stub, log the call for debugging.
  developer.log('registerFlutterHandler called in web environment: $name');
}

/// Sets up handlers for JavaScript interop events in web environments.
/// In non-web environments, logs the call and skips the setup.
void setupHandlers(JSAny Function(JSAny) callback) {
  if (!kIsWeb) {
    // In a test environment, simulate the behavior or skip
    developer.log('setupHandlers called in non-web environment');
    return;
  }

  // Web-specific logic (this won't run during tests)
  developer.log('Setting up handlers in web environment');
  registerFlutterHandler('setDisclosureAgreement', (JSAny agreed) {
    developer.log('setDisclosureAgreement called with agreed: $agreed');
    return callback(jsify({'disclosureAgreed': _convertToBool(agreed)}));
  });

  registerFlutterHandler('onCookiesAccepted', (JSAny _) {
    developer.log('onCookiesAccepted called');
    return callback(jsify({'cookiesAccepted': true}));
  });

  registerFlutterHandler('onUserLoggedIn', (JSAny userInfo) {
    developer.log('onUserLoggedIn called with userInfo: $userInfo');
    return callback(jsify({'userLoggedIn': jsObjectToMap(userInfo)}));
  });
}

/// Converts a JavaScript object to a Dart Map.
/// Returns an empty map if the input is null or not a Map.
Map<String, dynamic> jsObjectToMap(dynamic jsObject) {
  if (jsObject == null) return {};
  if (jsObject is! Map) {
    developer.log('jsObjectToMap: Expected a Map, got $jsObject');
    return {};
  }
  return Map<String, dynamic>.from(jsObject);
}

/// Converts a Dart Map to a JavaScript-compatible object.
/// In non-web environments, returns the map as-is.
JSAny jsify(Map<String, dynamic> dartObject) {
  // In non-web environments, return the map as-is (or simulate the behavior)
  return dartObject;
}

/// Safely converts a JSAny (dynamic) value to a Dart bool.
/// Throws an ArgumentError if the value cannot be converted.
bool _convertToBool(JSAny value) {
  if (value == true) return true;
  if (value == false) return false;
  throw ArgumentError('Invalid value for boolean conversion: $value');
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Import the generated localization delegate
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Import the main app widget and the state management class
import 'package:AeraSync/main.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/core/services/app_state.dart'; // Adjust import path if necessary

void main() {
  // Use testWidgets for widget tests
  testWidgets('MyApp builds and displays localized app title', (WidgetTester tester) async {
    // Arrange: Set up dependencies and initial state

    // Ensure Flutter bindings are initialized for testing
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create an instance of AppState
    final appState = AppState();

    // Initialize AppState (this loads calculator data asynchronously)
    // It's important to await this before pumping the widget that depends on it.
    await appState.initialize();

    // Act: Build the widget tree for testing
    await tester.pumpWidget(
      // Provide the initialized AppState to the widget tree
      Provider<AppState>.value(
        value: appState,
        // Wrap the MyApp widget within a MaterialApp configured for testing
        // This provides necessary context like Directionality and localization support.
        child: MaterialApp(
          // Set up localization delegates for the test environment
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Force a specific locale for predictable testing
          locale: const Locale('en'),
          // The widget under test
          home: const MyApp(), // Note: MyApp itself returns a MaterialApp
        ),
      ),
    );

    // Allow the widget tree to settle after initial build and potential async operations
    await tester.pumpAndSettle();

    // Assert: Verify the expected outcome

    // Check if the widget displaying the app title 'AeraSync' (from app_en.arb) is found.
    // This verifies that MyApp built and localization is working for the title.
    expect(find.text('AeraSync'), findsOneWidget);

  });
}

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
      ChangeNotifierProvider<AppState>(
        create: (_) => appState,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const MyApp(),
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

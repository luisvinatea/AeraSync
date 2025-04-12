import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:AeraSync/main.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/core/services/app_state.dart';

void main() {
  testWidgets('MyApp builds and displays app title', (WidgetTester tester) async {
    // Create an instance of AppState
    final appState = AppState();
    
    // Initialize AppState (loads calculator data)
    await appState.initialize();

    // Wrap MyApp with Provider<AppState>
    await tester.pumpWidget(
      Provider<AppState>.value(
        value: appState,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const MyApp(),
        ),
      ),
    );

    // Wait for the widget tree to settle
    await tester.pumpAndSettle();

    // Expect to find the app title
    expect(find.text('AeraSync'), findsOneWidget); // Matches appTitle from app_en.arb
  });
}
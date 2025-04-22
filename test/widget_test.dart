import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aerasync/main.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/core/services/api_service.dart';
import 'package:aerasync/l10n/l10n.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  testWidgets('HomePage smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'locale': 'en',
      'hasAgreedToDisclosure': true, // Avoid disclosure dialog
    });

    // Mock ApiService
    final mockApiService = MockApiService();
    when(() => mockApiService.checkHealth()).thenAnswer((_) async => true);

    // Build our app with AppState provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(
          locale: const Locale('en'),
          apiService: mockApiService,
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          home: const MyApp(),
        ),
      ),
    );

    // Wait for async operations (e.g., API health check)
    await tester.pumpAndSettle();

    // Verify HomePage elements
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(find.text(l10n.welcomeToAeraSync), findsOneWidget);
    expect(find.text(l10n.startSurvey), findsOneWidget);
    expect(find.byType(DropdownButton<Locale>), findsOneWidget);
    expect(find.text('EN'), findsOneWidget); // Language dropdown default

    // Verify Start Survey button is enabled (API healthy)
    final startSurveyButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(startSurveyButton.enabled, isTrue);
  });
}

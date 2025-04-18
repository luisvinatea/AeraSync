import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aerasync/core/services/api_service.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/l10n/l10n.dart';
import 'package:aerasync/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  setUpAll(() {
    // Mock SharedPreferences to avoid MissingPluginException
    SharedPreferences.setMockInitialValues({
      'hasAgreedToDisclosure': true,
      'locale': 'en',
    });
  });

  group('HomePage Localization Tests', () {
    late MockApiService mockApiService;
    late AppState appState;

    setUp(() {
      mockApiService = MockApiService();
      appState = AppState(locale: const Locale('en'), apiService: mockApiService);
      when(() => mockApiService.checkHealth()).thenAnswer((_) async => true);
      appState.setDisclosureAgreed(true); // Avoid disclosure dialog
    });

    Future<void> pumpHomePage(WidgetTester tester, String locale) async {
      appState.locale = Locale(locale);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>(
          create: (_) => appState,
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.all,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (var locale in ['en', 'es', 'pt']) {
      testWidgets('HomePage displays localized content in $locale', (WidgetTester tester) async {
        await pumpHomePage(tester, locale);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(l10n.appTitle), findsOneWidget);
        expect(find.text(l10n.welcomeToAeraSync), findsOneWidget);
      });
    }
  });

  group('HomePage API Tests', () {
    late MockApiService mockApiService;
    late AppState appState;

    setUp(() {
      mockApiService = MockApiService();
      appState = AppState(locale: const Locale('en'), apiService: mockApiService);
      appState.setDisclosureAgreed(true); // Avoid disclosure dialog
    });

    Future<void> pumpHomePageWithApi(WidgetTester tester, String locale, {required bool isHealthy}) async {
      when(() => mockApiService.checkHealth()).thenAnswer((_) async => isHealthy);
      appState.locale = Locale(locale);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>(
          create: (_) => appState,
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.all,
            home: const HomePage(),
          ),
        ),
      );
      // Additional pump to ensure async API health check completes
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    for (var locale in ['en', 'es', 'pt']) {
      testWidgets('HomePage shows API healthy in $locale', (WidgetTester tester) async {
        await pumpHomePageWithApi(tester, locale, isHealthy: true);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(l10n.startSurvey), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);
      });

      testWidgets('HomePage shows API error in $locale when unhealthy', (WidgetTester tester) async {
        await pumpHomePageWithApi(tester, locale, isHealthy: false);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(l10n.apiUnreachable), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isFalse);
      });
    }
  });
}
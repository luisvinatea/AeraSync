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
import 'package:aerasync/main.dart';
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

      testWidgets('HomePage allows language change in $locale', (WidgetTester tester) async {
        await pumpHomePage(tester, 'en');
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        // Verify initial English text before changing language
        expect(find.text(l10n.welcomeToAeraSync), findsOneWidget); // Should be "Welcome to AeraSync" in English
        await tester.tap(find.byType(DropdownButton<Locale>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ES').last);
        await tester.pumpAndSettle();
        final newL10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(newL10n.welcomeToAeraSync), findsOneWidget); // Should be in Spanish ("Bienvenido a AeraSync")
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
      // Note: Ideally, wait for a Future exposed by AppState (e.g., appState.apiHealthCheckFuture).
      // For now, rely on pumpAndSettle.
      await tester.pumpAndSettle();
    }

    for (var locale in ['en', 'es', 'pt']) {
      testWidgets('HomePage shows API healthy in $locale', (WidgetTester tester) async {
        await pumpHomePageWithApi(tester, locale, isHealthy: true);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(l10n.startSurvey), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);

        // Test interaction: Tap the "Start Survey" button (assuming it navigates or updates state)
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        // Add expectations based on what happens after tapping (e.g., navigation to a survey page)
      });

      testWidgets('HomePage shows API error in $locale when unhealthy', (WidgetTester tester) async {
        await pumpHomePageWithApi(tester, locale, isHealthy: false);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(find.text(l10n.apiUnreachable), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isFalse);
      });
    }
  });

  group('HomePage Disclosure Tests', () {
    late MockApiService mockApiService;
    late AppState appState;

    setUp(() {
      mockApiService = MockApiService();
      appState = AppState(locale: const Locale('en'), apiService: mockApiService);
      when(() => mockApiService.checkHealth()).thenAnswer((_) async => true);
    });

    testWidgets('HomePage shows disclosure dialog when not agreed', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'hasAgreedToDisclosure': false});
      appState.setDisclosureAgreed(false);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>(
          create: (_) => appState,
          child: MaterialApp(
            locale: const Locale('en'),
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

      final l10n = AppLocalizations.of(tester.element(find.byType(AlertDialog)))!;
      expect(find.text(l10n.dataDisclosure), findsOneWidget);
      await tester.tap(find.text(l10n.agree));
      await tester.pumpAndSettle();
      expect(find.text(l10n.welcomeToAeraSync), findsOneWidget);
    });
  });

  group('MyApp Smoke Tests', () {
    testWidgets('MyApp renders HomePage correctly', (WidgetTester tester) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'locale': 'en',
        'hasAgreedToDisclosure': true, // Avoid disclosure dialog
      });

      // Mock ApiService
      final mockApiService = MockApiService();
      when(() => mockApiService.checkHealth()).thenAnswer((_) async => true);

      // Build the app through MyApp
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
  });
}
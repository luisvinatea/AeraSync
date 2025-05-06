import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mock AppState
@GenerateMocks([AppState])
import 'home_page_test.mocks.dart';

void main() {
  group('HomePage Widget Tests', () {
    late MockAppState mockAppState;

    setUp(() {
      mockAppState = MockAppState();
      SharedPreferences.setMockInitialValues({});

      // Default stubs for AppState methods and properties
      when(mockAppState.locale).thenReturn(const Locale('en'));
      when(mockAppState.isApiHealthy).thenReturn(true);
      when(mockAppState.hasAgreedToDisclosure).thenReturn(true);
      when(mockAppState.checkApiHealth()).thenAnswer((_) async => true);
    });

    Widget createHomeScreen({double width = 800, double height = 600}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
          ),
          child: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const HomePage(),
          ),
        ),
      );
    }

    testWidgets('renders title and welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find the app title in AppBar
      expect(find.text('AeraSync'), findsOneWidget);

      // Find the welcome message
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('shows start survey button when API is healthy', (WidgetTester tester) async {
      when(mockAppState.isApiHealthy).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find the Start Survey button
      expect(find.textContaining('Start Survey'), findsOneWidget);

      // Enable button when API is healthy
      final startSurveyButton = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(startSurveyButton).enabled, isTrue);
    });

    testWidgets('disables start survey button when API is not healthy', (WidgetTester tester) async {
      // Setup mock for unhealthy API
      when(mockAppState.isApiHealthy).thenReturn(false);
      when(mockAppState.checkApiHealth()).thenAnswer((_) async => false);
      when(mockAppState.hasAgreedToDisclosure).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Button should be disabled when API is not healthy
      final startSurveyButton = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(startSurveyButton).enabled, isFalse);
    });

    testWidgets('shows API unreachable warning when API is not healthy', (WidgetTester tester) async {
      when(mockAppState.isApiHealthy).thenReturn(false);
      when(mockAppState.checkApiHealth()).thenAnswer((_) async => false);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Should show warning icon and retry button
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.textContaining('Retry'), findsOneWidget);
    });

    testWidgets('shows disclosure dialog if not previously agreed', (WidgetTester tester) async {
      when(mockAppState.hasAgreedToDisclosure).thenReturn(false);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Should show data disclosure dialog
      expect(find.textContaining('Disclosure'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('does not show disclosure dialog if previously agreed', (WidgetTester tester) async {
      when(mockAppState.hasAgreedToDisclosure).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Should not show data disclosure dialog
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('clicking agree on disclosure dialog updates app state', (WidgetTester tester) async {
      when(mockAppState.hasAgreedToDisclosure).thenReturn(false);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find and click a TextButton in the AlertDialog
      final agreeButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton)
      );
      expect(agreeButton, findsOneWidget);

      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      // Verify the appropriate method was called
      verify(mockAppState.setDisclosureAgreed(true)).called(1);
    });

    testWidgets('clicking language dropdown shows language options', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find and tap the language dropdown
      final dropdown = find.byType(DropdownButton<Locale>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show language options
      expect(find.text('EN'), findsWidgets);

      // There should be multiple language options
      final dropdownItems = find.byType(DropdownMenuItem<Locale>);
      expect(dropdownItems, findsWidgets);
      expect(tester.widgetList(dropdownItems).length, greaterThan(1));
    });

    testWidgets('changing language updates app state', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Tap the language dropdown
      final dropdown = find.byType(DropdownButton<Locale>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Find all DropdownMenuItem widgets
      final menuItems = find.byType(DropdownMenuItem<Locale>);

      // Tap the second menu item (assuming it exists)
      if (tester.widgetList(menuItems).length > 1) {
        await tester.tap(menuItems.at(1));
        await tester.pumpAndSettle();

        // Verify locale was updated
        verify(mockAppState.locale = any).called(greaterThanOrEqualTo(1));
      }
    });

    testWidgets('tapping start survey navigates to survey page', (WidgetTester tester) async {
      when(mockAppState.isApiHealthy).thenReturn(true);
      when(mockAppState.hasAgreedToDisclosure).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => MediaQuery(
                data: const MediaQueryData(size: Size(800, 600)),
                child: ChangeNotifierProvider<AppState>.value(
                  value: mockAppState,
                  child: const HomePage(),
                ),
              ),
            '/survey': (context) => const Scaffold(body: Text('Survey Page')),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the start survey button
      final startSurveyButton = find.byType(ElevatedButton).first;
      await tester.tap(startSurveyButton);
      await tester.pumpAndSettle();

      // Should navigate to survey page
      expect(find.text('Survey Page'), findsOneWidget);
    });
  });
}

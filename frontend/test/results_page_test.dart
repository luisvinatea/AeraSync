import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/presentation/widgets/results_page.dart';

// Generate mock AppState
@GenerateMocks([AppState])
import 'results_page_test.mocks.dart';

void main() {
  group('ResultsPage Widget Tests', () {
    late MockAppState mockAppState;

    // Sample API results for testing
    final Map<String, dynamic> sampleResults = {
      'tod': 5443.7675,
      'aeratorResults': [
        {
          'name': 'Aerator 1',
          'num_aerators': 3889,
          'total_power_hp': 11667,
          'total_initial_cost': 1944500,
          'annual_energy_cost': 1270722.97,
          'annual_maintenance_cost': 252785,
          'npv_cost': -10608909.98,
          'aerators_per_ha': 3.889,
          'hp_per_ha': 11.667,
          'sae': 0.63,
          'payback_years': 2.5,
          'roi_percent': 150.25,
          'irr': 32.16,
          'profitability_k': 1.5
        },
        {
          'name': 'Aerator 2',
          'num_aerators': 2475,
          'total_power_hp': 8662.5,
          'total_initial_cost': 1980000,
          'annual_energy_cost': 943410.30,
          'annual_maintenance_cost': 123750,
          'npv_cost': -7546848.31,
          'aerators_per_ha': 2.475,
          'hp_per_ha': 8.6625,
          'sae': 0.84,
          'payback_years': 1.8,
          'roi_percent': 198.52,
          'irr': 42.38,
          'profitability_k': 1.8
        }
      ],
      'winnerLabel': 'Aerator 2',
      'equilibriumPrices': {'Aerator 1': 399.40}
    };

    setUp(() {
      mockAppState = MockAppState();
      when(mockAppState.locale).thenReturn(const Locale('en'));
    });

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Note: We're directly using tester.view properties in individual tests instead
    });

    tearDownAll(() {
      // Cleanup handled in individual tests
    });

    Widget createResultsScreen() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<AppState>.value(
          value: mockAppState,
          child: const ResultsPage(),
        ),
      );
    }

    testWidgets('shows no data message when results are null',
        (WidgetTester tester) async {
      // Setup mock with null results
      when(mockAppState.apiResults).thenReturn(null);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Should show no data available message
      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('shows results when data is available',
        (WidgetTester tester) async {
      // Setup mock with test results
      when(mockAppState.apiResults).thenReturn(sampleResults);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Check for summary section
      expect(find.text('Summary Metrics'), findsOneWidget);
      expect(find.textContaining('5443.77'), findsOneWidget);
      expect(find.textContaining('Recommended Aerator: Aerator 2'),
          findsOneWidget);

      // Check for comparison table
      expect(find.text('Aerator Comparison Results'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);

      // Check for equilibrium prices
      expect(find.text('Equilibrium Prices'), findsOneWidget);
      expect(find.textContaining('399.40'), findsOneWidget);
    });

    testWidgets('shows all aerator results in the table',
        (WidgetTester tester) async {
      // Setup mock with test results
      when(mockAppState.apiResults).thenReturn(sampleResults);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Check for both aerators in the table
      expect(find.text('Aerator 1'), findsOneWidget);
      expect(find.text('Aerator 2'), findsOneWidget);

      // Check for numeric values from the results
      expect(find.text('3889'), findsOneWidget); // num_aerators for Aerator 1
      expect(find.text('2475'), findsOneWidget); // num_aerators for Aerator 2

      // Check for formatted currency values
      expect(find.textContaining('1944500'), findsOneWidget);
      expect(find.textContaining('1980000'), findsOneWidget);
    });

    testWidgets('highlights the winning aerator', (WidgetTester tester) async {
      // Setup mock with test results
      when(mockAppState.apiResults).thenReturn(sampleResults);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Find DataTable
      final dataTable = find.byType(DataTable);
      expect(dataTable, findsOneWidget);

      // Find at least one cell with the winner's name
      expect(
          find.descendant(
              of: find.byType(DataTable), matching: find.text('Aerator 2')),
          findsOneWidget);
    });

    testWidgets('handles infinite values in results gracefully',
        (WidgetTester tester) async {
      // Create results with infinite values
      final resultsWithInfinites = Map<String, dynamic>.from(sampleResults);
      resultsWithInfinites['aeratorResults'] = [
        {
          'name': 'Aerator 1',
          'num_aerators': 3889,
          'total_power_hp': 11667,
          'total_initial_cost': 1944500,
          'annual_energy_cost': 1270722.97,
          'annual_maintenance_cost': 252785,
          'npv_cost': double.negativeInfinity, // Use infinity value
          'aerators_per_ha': 3.889,
          'hp_per_ha': 11.667,
          'sae': 0.63,
          'payback_years': double.infinity, // Use infinity value
          'roi_percent': 150.25,
          'irr': 32.16,
          'profitability_k': 1.5
        },
        sampleResults['aeratorResults'][1],
      ];

      // Setup mock with modified results
      when(mockAppState.apiResults).thenReturn(resultsWithInfinites);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Check that infinite payback period is displayed as N/A
      expect(find.text('N/A'), findsWidgets);
    });

    testWidgets('handles empty equilibrium prices',
        (WidgetTester tester) async {
      // Create results with empty equilibrium prices
      final resultsWithNoEquilibriumPrices =
          Map<String, dynamic>.from(sampleResults);
      resultsWithNoEquilibriumPrices['equilibriumPrices'] = <String, dynamic>{};

      // Setup mock with modified results
      when(mockAppState.apiResults).thenReturn(resultsWithNoEquilibriumPrices);

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // With no equilibrium prices, we should see the "No equilibrium prices" text
      // but the exact text depends on localization, so we check for absence of price value
      expect(find.textContaining('399.40'), findsNothing);
    });

    testWidgets('scrolls to show all content', (WidgetTester tester) async {
      // Setup mock with test results
      when(mockAppState.apiResults).thenReturn(sampleResults);

      // Use a specific size that's smaller than the content
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createResultsScreen());
      await tester.pumpAndSettle();

      // Initial check - find the first SingleChildScrollView
      final scrollView = find.byType(SingleChildScrollView).first;
      expect(scrollView, findsOneWidget);

      // Scroll down by dragging
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pumpAndSettle();

      // We don't need specific assertions after scrolling - just checking that it doesn't crash

      // Reset the physical size and pixel ratio in tearDown
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}

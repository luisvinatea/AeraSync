import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/aerator_comparison_form.dart';
import '../widgets/calculator_form.dart';
import '../widgets/oxygen_demand_and_estimation_form.dart';
import '../widgets/oxygen_demand_results_display.dart';
import '../widgets/results_display.dart';
import '../../core/services/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with the correct number of tabs
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get l10n instance once for the build method
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle), // Use localized title
        bottom: TabBar(
          controller: _tabController,
          // Make tabs scrollable if they might overflow on smaller screens
          isScrollable: true,
          tabs: [
            // Use localized tab labels
            Tab(text: l10n.aeratorPerformanceCalculator),
            Tab(text: l10n.aeratorComparisonCalculator),
            Tab(text: l10n.oxygenDemandAndEstimationCalculator),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Disable swiping between tabs if desired
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Aerator Performance Tab
          // Use a consistent key for AppState results for this tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const CalculatorForm(),
                  // Pass the correct key used in CalculatorForm
                  ResultsDisplay(tab: 'Aerator Performance'),
                ],
              ),
            ),
          ),

          // Aerator Comparison Tab
          // Use a consistent key for AppState results for this tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const AeratorComparisonForm(),
                  // Pass the correct key used in AeratorComparisonForm
                  ResultsDisplay(tab: 'Aerator Comparison'),
                ],
              ),
            ),
          ),

          // Oxygen Demand and Estimation Tab
          // Use a consistent key for AppState results for this tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const OxygenDemandAndEstimationForm(),
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      // Use the correct key used in OxygenDemandAndEstimationForm
                      final results = appState.getResults('Oxygen Demand and Estimation');
                      // Handle null or empty results gracefully
                      if (results == null || results.isEmpty) {
                        // Show the generic results display if no results yet
                        return ResultsDisplay(tab: 'Oxygen Demand and Estimation');
                      }
                      // **FIX:** Check for the key using the string literal used in the form
                      // Check if the results map contains the key indicating experimental results
                      if (results.containsKey('numberOfAeratorsPerHectareLabel')) {
                         // If it has experimental results, show the generic ResultsDisplay
                         // (assuming it can handle both farm-based and experimental keys now)
                         // OR create a specific display widget if needed.
                        return ResultsDisplay(tab: 'Oxygen Demand and Estimation');
                      } else {
                        // Otherwise, assume it's farm-based results and show the specific display
                        return const OxygenDemandResultsDisplay();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget to lazily build tab content (keeps state)
class _LazyTab extends StatefulWidget {
  final Widget child;

  const _LazyTab({required this.child});

  @override
  _LazyTabState createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> with AutomaticKeepAliveClientMixin {
  // No need for _hasBuilt flag when using AutomaticKeepAliveClientMixin
  // bool _hasBuilt = false;

  @override
  bool get wantKeepAlive => true; // Keep the state of the tab

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important: call super.build(context)
    // The child is built only once and kept alive
    return widget.child;
  }
}

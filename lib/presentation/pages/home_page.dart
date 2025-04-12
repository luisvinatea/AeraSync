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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.aeratorPerformanceCalculator),
            Tab(text: l10n.aeratorComparisonCalculator),
            Tab(text: l10n.oxygenDemandAndEstimationCalculator),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Aerator Performance Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const CalculatorForm(),
                  ResultsDisplay(tab: 'Aerator Performance'),
                ],
              ),
            ),
          ),
          // Aerator Comparison Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const AeratorComparisonForm(),
                  ResultsDisplay(tab: 'Aerator Comparison'), // Replaced ComparisonResultsDisplay
                ],
              ),
            ),
          ),
          // Oxygen Demand and Estimation Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const OxygenDemandAndEstimationForm(),
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      final results = appState.getResults('Oxygen Demand and Estimation');
                      if (results == null || results.isEmpty) {
                        return ResultsDisplay(tab: 'Oxygen Demand and Estimation');
                      }
                      if (results.containsKey(l10n.numberOfAeratorsPerHectareLabel)) {
                        return ResultsDisplay(tab: 'Oxygen Demand and Estimation');
                      } else {
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

class _LazyTab extends StatefulWidget {
  final Widget child;

  const _LazyTab({required this.child});

  @override
  _LazyTabState createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> with AutomaticKeepAliveClientMixin {
  bool _hasBuilt = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_hasBuilt) {
      _hasBuilt = true;
      return widget.child;
    }
    return widget.child;
  }
}
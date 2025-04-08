import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/aerator_comparison_form.dart';
import '../widgets/aerator_estimation_form.dart';
import '../widgets/calculator_form.dart';
import '../widgets/comparison_results_display.dart';
import '../widgets/oxygen_demand_form.dart';
import '../widgets/oxygen_demand_results_display.dart';
import '../widgets/results_display.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('AeraSync'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.aeratorPerformanceCalculator),
            Tab(text: l10n.aeratorEstimationCalculator),
            Tab(text: l10n.aeratorComparisonCalculator),
            Tab(text: l10n.oxygenDemandCalculator),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to reduce unnecessary builds
        children: const [
          // Aerator Performance Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CalculatorForm(),
                  ResultsDisplay(tab: 'Aerator Performance'),
                ],
              ),
            ),
          ),
          // Aerator Estimation Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AeratorEstimationForm(),
                  ResultsDisplay(tab: 'Aerator Estimation'),
                ],
              ),
            ),
          ),
          // Aerator Comparison Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AeratorComparisonForm(),
                  ComparisonResultsDisplay(),
                ],
              ),
            ),
          ),
          // Oxygen Demand Tab
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  OxygenDemandForm(),
                  OxygenDemandResultsDisplay(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that defers building its child until it is visible.
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
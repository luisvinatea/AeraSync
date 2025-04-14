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
  bool _hasAgreedToDataDisclosure = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Show popup on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDataDisclosurePopup();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDataDisclosurePopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing without agreeing
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.dataDisclosureTitle),
          content: Text(l10n.dataDisclosureMessage),
          actions: [
            TextButton(
              onPressed: () {
                // Exit app if user doesn't agree
                Navigator.of(context).pop();
                // Note: SystemNavigator.pop() doesn't work on web
                // For web, show a message or redirect
                setState(() {
                  _hasAgreedToDataDisclosure = false;
                });
              },
              child: Text(l10n.disagreeButton),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasAgreedToDataDisclosure = true;
                });
                Navigator.of(context).pop();
              },
              child: Text(l10n.agreeButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasAgreedToDataDisclosure) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.aeratorComparisonCalculator),
            Tab(text: l10n.sotrCalculator),
            Tab(text: l10n.todCalculator),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _LazyTab(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const AeratorComparisonForm(),
                  ResultsDisplay(tab: 'Aerator Comparison'),
                ],
              ),
            ),
          ),
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
                      if (results.containsKey('numberOfAeratorsPerHectareLabel')) {
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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
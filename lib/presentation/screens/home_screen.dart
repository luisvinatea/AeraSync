import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../widgets/aerator_comparison_form.dart';
import '../widgets/calculator_form.dart';
import '../widgets/aerator_estimation_form.dart';
import '../widgets/comparison_results_display.dart';
import '../widgets/oxygen_demand_form.dart';
import '../widgets/oxygen_demand_results_display.dart';
import '../widgets/results_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Provider.of<AppState>(context, listen: false).resetState();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                isScrollable: true, // Added to handle more tabs
                tabs: const [
                  Tab(text: 'Aerator Comparison'),
                  Tab(text: 'Aerator Performance'),
                  Tab(text: 'Aerator Estimation'),
                  Tab(text: 'Oxygen Demand'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // First tab: Aerator Comparison (Main Tab)
                    Column(
                      children: [
                        const AeratorComparisonForm(),
                        const Expanded(
                          child: ComparisonResultsDisplay(),
                        ),
                      ],
                    ),
                    // Second tab: Aerator Performance
                    Column(
                      children: [
                        const CalculatorForm(),
                        Expanded(
                          child: ResultsDisplay(tab: 'Aerator Performance'),
                        ),
                      ],
                    ),
                    // Third tab: Aerator Estimation
                    Column(
                      children: [
                        const AeratorEstimationForm(),
                        Expanded(
                          child: ResultsDisplay(tab: 'Aerator Estimation'),
                        ),
                      ],
                    ),
                    // Fourth tab: Oxygen Demand
                    Column(
                      children: [
                        const OxygenDemandForm(),
                        Expanded(
                          child: OxygenDemandResultsDisplay(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
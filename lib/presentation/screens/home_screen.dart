import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart'; // Fixed path
import '../widgets/calculator_form.dart'; // Fixed path
import '../widgets/aerator_estimation_form.dart'; // Fixed path
import '../widgets/results_display.dart'; // Fixed path

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
    _tabController = TabController(length: 2, vsync: this);
    // Add a listener to reset the AppState when the tab changes
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
                tabs: const [
                  Tab(text: 'Aerator Performance'),
                  Tab(text: 'Aerator Estimation'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // First tab: Aerator Performance
                    Column(
                      children: [
                        const CalculatorForm(),
                        Expanded(
                          child: ResultsDisplay(tab: 'Aerator Performance'),
                        ),
                      ],
                    ),
                    // Second tab: Aerator Estimation
                    Column(
                      children: [
                        const AeratorEstimationForm(),
                        Expanded(
                          child: ResultsDisplay(tab: 'Aerator Estimation'),
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
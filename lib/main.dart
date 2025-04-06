import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/app_state.dart';
import 'presentation/widgets/calculator_form.dart';
import 'presentation/widgets/aerator_estimation_form.dart';
import 'presentation/widgets/results_display.dart';

void main() {
  runApp(const AeraSyncApp());
}

class AeraSyncApp extends StatelessWidget {
  const AeraSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'AeraSync',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.transparent,
          cardTheme: const CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Montserrat'),
            titleLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TabBar with padding for better visibility
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Aerator Performance'),
                    Tab(text: 'Aerator Estimation'),
                  ],
                ),
              ),
              // Expanded TabBarView with SingleChildScrollView for scrolling
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Aerator Performance
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const CalculatorForm(),
                          ResultsDisplay(tab: 'Aerator Performance'),
                        ],
                      ),
                    ),
                    // Tab 2: Aerator Estimation
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const AeratorEstimationForm(),
                          ResultsDisplay(tab: 'Aerator Estimation'),
                        ],
                      ),
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/app_state.dart';
import 'core/services/calculator_service.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<CalculatorService>(
          create: (_) => CalculatorService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(
            calculator: Provider.of<CalculatorService>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeraSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
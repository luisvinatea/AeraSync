import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/services/app_state.dart';
import 'core/services/aerator_calculator.dart';
import 'core/services/shrimp_respiration_calculator.dart';
import 'presentation/pages/home_page.dart';

void main() {
  // Preload critical assets
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AeratorCalculator>(
          create: (_) => AeratorCalculator(),
        ),
        Provider<ShrimpRespirationCalculator>(
          create: (_) => ShrimpRespirationCalculator(),
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(
            calculator: Provider.of<AeratorCalculator>(context, listen: false),
            respirationCalculator: Provider.of<ShrimpRespirationCalculator>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AeraSync',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Montserrat',
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E40AF),
            secondary: Color(0xFF60A5FA),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E40AF),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: Builder(
          builder: (context) => const HomePage(),
        ),
      ),
    );
  }
}
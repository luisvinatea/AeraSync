import 'package:flutter/material.dart';
// Import the generated localization file
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:AeraSync/presentation/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/core/services/app_state.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize AppState before running the app
  final appState = AppState();
  await appState.initialize(); // Ensure data is loaded

  runApp(
    // Provide the AppState instance to the widget tree
    Provider<AppState>.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // === Localization Setup ===
      // Delegates are needed to load the translations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Define the locales your app supports
      supportedLocales: AppLocalizations.supportedLocales,
      // === App Configuration ===
      // Set the title from localized strings if desired,
      // but MaterialApp title is often not directly visible.
      // Use onGenerateTitle for dynamic titles based on locale.
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle, // Dynamically get title
      // title: 'AeraSync', // This title is mainly for the OS task switcher

      // Define the theme (optional)
      theme: ThemeData(
        primarySwatch: Colors.blue, // Or use ColorScheme.fromSeed
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
           backgroundColor: Color(0xFF1E40AF), // Example color
           foregroundColor: Colors.white, // Title/icon color
        ),
         tabBarTheme: const TabBarTheme(
           labelColor: Colors.white, // Color for selected tab text
           unselectedLabelColor: Colors.white70, // Color for unselected tab text
           indicatorColor: Colors.white, // Color of the indicator line
         ),
      ),

      // Set the initial route/page
      home: const HomePage(),

      // Disable the debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}

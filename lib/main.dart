import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:AeraSync/presentation/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/core/services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize AppState
  final appState = AppState();
  await appState.initialize();

  runApp(
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'AeraSync',
      home: const HomePage(),
    );
  }
}
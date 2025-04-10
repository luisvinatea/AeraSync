import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:AeraSync/generated/l10n.dart';
import 'core/services/app_state.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        // Initialize AppState immediately
        appState.initialize();
        return appState;
      },
      child: MaterialApp(
        title: 'AeraSync',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (appState.error != null) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${appState.error}'),
                ),
              );
            }
            return const HomePage();
          },
        ),
      ),
    );
  }
}
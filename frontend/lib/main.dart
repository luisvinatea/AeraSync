import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/app_state.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/widgets/survey_page.dart';
import 'presentation/widgets/results_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeCode = prefs.getString('locale') ?? 'en';
  final supportedLocales =
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
  final validLocaleCode =
      supportedLocales.contains(localeCode) ? localeCode : 'en';
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(locale: Locale(validLocaleCode)),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'AeraSync',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E40AF),
              primary: const Color(0xFF1E40AF),
              secondary: const Color(0xFF60A5FA),
              surface: Colors.white.withAlpha(230),
              onSurface: const Color(0xFF1E40AF),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            cardTheme: const CardTheme(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
              bodyMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1E40AF),
              ),
              labelMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E40AF),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withAlpha(242),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF60A5FA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF60A5FA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF1E40AF), width: 2),
              ),
              labelStyle: TextStyle(
                backgroundColor: Colors.white.withAlpha(204),
                color: const Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/survey': (context) => const SurveyPage(),
            '/results': (context) => const ResultsPage(),
          },
          builder: (context, child) {
            // Show errors as SnackBar
            if (appState.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(appState.error!),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.dismiss,
                      onPressed: appState.clearError,
                    ),
                  ),
                );
              });
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

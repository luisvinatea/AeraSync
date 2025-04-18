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
  // Validate localeCode to ensure it's supported
  final validLocaleCode = ['en', 'es', 'pt'].contains(localeCode) ? localeCode : 'en';
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('pt'),
          ],
          locale: appState.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E40AF),
              primary: const Color(0xFF1E40AF),
              secondary: const Color(0xFF60A5FA),
              surface: Colors.white.withValues(alpha: 0.9),
              onSurface: const Color(0xFF1E40AF),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Color(0xFF1E40AF),
              ),
              labelMedium: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Color(0xFF1E40AF),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(color: Color(0xFF60A5FA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(color: Color(0xFF60A5FA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(color: Color(0xFF60A5FA)),
              ),
            ),
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const HomePage());
              case '/survey':
                return MaterialPageRoute(builder: (_) => const SurveyPage());
              case '/results':
                return MaterialPageRoute(builder: (_) => const ResultsPage());
              default:
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Text(AppLocalizations.of(context)!.pageNotFound),
                    ),
                  ),
                );
            }
          },
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (appState.error != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.error,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(appState.error!),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => appState.clearError(),
                                  child: Text(AppLocalizations.of(context)!.dismiss),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/app_state.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/widgets/survey_page.dart';
import 'presentation/widgets/results_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for mobile devices
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E40AF),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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
    // Detect if we're on mobile
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          navigatorKey: AppState.navigatorKey,
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
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                // Using system fonts instead of custom fonts to avoid loading issues
                fontSize: isMobile ? 14.0 : 16.0,
              ),
              headlineMedium: TextStyle(
                fontSize: isMobile ? 18.0 : 22.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
              labelMedium: TextStyle(
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E40AF),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: const Color(0xFF1E40AF),
              titleTextStyle: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              toolbarHeight: isMobile ? 56.0 : 64.0,
            ),
            cardTheme: CardTheme(
              elevation: 4,
              margin: EdgeInsets.symmetric(
                  vertical: 8, horizontal: isMobile ? 8 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 8 : 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withAlpha(242),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.transparent, width: 2),
              ),
              labelStyle: TextStyle(
                backgroundColor: Colors.white.withAlpha(204),
                color: const Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 14 : 16,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, vertical: isMobile ? 14 : 18),
            ),
          ),
          // Add scroll behavior configuration for mobile
          scrollBehavior: const AppScrollBehavior(),
          locale: appState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/survey': (context) => const SurveyPage(),
            '/results': (context) => const ResultsPage(),
          },
          builder: (context, child) {
            // Apply text scaling limit for better readability on mobile
            final mediaQuery = MediaQuery.of(context);
            final constrainedTextScaler = mediaQuery.textScaler
                .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.3);

            child = MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: constrainedTextScaler,
              ),
              child: child!,
            );

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
            return child;
          },
        );
      },
    );
  }
}

// Custom scroll behavior that enables drag scrolling on all platforms
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Only show scrollbar on desktop
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile ? child : super.buildScrollbar(context, child, details);
  }
}

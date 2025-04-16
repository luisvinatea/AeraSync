import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/presentation/pages/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  // Define test data for locales and their expected translations
  final localeTests = {
    'en': {
      'appTitle': 'AeraSync',
      'welcome': 'Welcome to AeraSync',
      'startSurvey': 'Start Survey',
      'apiUnreachable': 'Unable to connect to the server. Please try again later.',
      'retry': 'Retry',
    },
    'es': {
      'appTitle': 'AeraSync',
      'welcome': 'Bienvenido a AeraSync',
      'startSurvey': 'Iniciar Encuesta',
      'apiUnreachable': 'No se puede conectar al servidor. Por favor, intenta de nuevo más tarde.',
      'retry': 'Reintentar',
    },
    'pt': {
      'appTitle': 'AeraSync',
      'welcome': 'Bem-vindo ao AeraSync',
      'startSurvey': 'Iniciar Pesquisa',
      'apiUnreachable': 'Não foi possível conectar ao servidor. Tente novamente mais tarde.',
      'retry': 'Tentar Novamente',
    },
  };

  group('HomePage Localization Tests', () {
    for (final locale in localeTests.entries) {
      testWidgets('HomePage displays localized content in ${locale.key}', (WidgetTester tester) async {
        // Arrange: Set up dependencies
        TestWidgetsFlutterBinding.ensureInitialized();
        final appState = AppState(locale: Locale(locale.key));
        appState.setApiHealth(true);

        // Act: Build HomePage with providers and localization
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>(
            create: (_) => appState,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('pt'),
              ],
              locale: Locale(locale.key),
              home: const HomePage(),
            ),
          ),
        );

        // Allow async operations to complete
        await tester.pumpAndSettle();

        // Assert: Verify localized content
        expect(find.text(locale.value['appTitle']!), findsOneWidget); // AppBar title
        expect(find.text(locale.value['welcome']!), findsOneWidget); // Welcome text
        expect(find.text(locale.value['startSurvey']!), findsOneWidget); // Button text
        expect(find.byType(DropdownButton<Locale>), findsOneWidget); // Locale dropdown
      });
    }
  });

  group('HomePage API Error Tests', () {
    for (final locale in localeTests.entries) {
      testWidgets('HomePage shows API error in ${locale.key} when unhealthy', (WidgetTester tester) async {
        // Arrange: Set up dependencies
        TestWidgetsFlutterBinding.ensureInitialized();
        final appState = AppState(locale: Locale(locale.key));
        appState.setApiHealth(false);

        // Act: Build HomePage
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>(
            create: (_) => appState,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('pt'),
              ],
              locale: Locale(locale.key),
              home: const HomePage(),
            ),
          ),
        );

        // Allow async operations to complete
        await tester.pumpAndSettle();

        // Assert: Verify error UI
        expect(find.text(locale.value['apiUnreachable']!), findsOneWidget); // Error message
        expect(find.text(locale.value['retry']!), findsOneWidget); // Retry button
        expect(find.byIcon(Icons.warning), findsOneWidget); // Warning icon
        expect(
          find.byWidgetPredicate(
            (widget) => widget is ElevatedButton && widget.enabled == false,
          ),
          findsOneWidget,
        ); // Disabled Start Survey button
      });
    }
  });
}
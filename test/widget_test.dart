import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:aerasync/core/services/app_state.dart';
import 'package:aerasync/presentation/pages/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('HomePage builds and displays localized content', (WidgetTester tester) async {
    // Arrange: Set up dependencies
    TestWidgetsFlutterBinding.ensureInitialized();
    final appState = AppState();

    // Act: Build HomePage with required providers and localization
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => appState,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: HomePage(),
        ),
      ),
    );

    // Allow async operations (e.g., data disclosure popup) to complete
    await tester.pumpAndSettle();

    // Assert: Verify localized content
    expect(find.text('AeraSync'), findsOneWidget); // AppBar title
    expect(find.text('Data Disclosure'), findsOneWidget); // Popup title
    expect(find.text('Agree'), findsOneWidget); // Agree button
  });
}
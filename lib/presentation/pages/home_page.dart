import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isApiHealthy = true;
  bool _isCheckingHealth = false;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
    _showDataDisclosureIfNeeded();
  }

  Future<void> _checkApiHealth() async {
    if (_isCheckingHealth) return;
    setState(() {
      _isCheckingHealth = true;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    final isHealthy = await appState.checkApiHealth();
    if (!mounted) return;
    setState(() {
      _isApiHealthy = isHealthy;
      _isCheckingHealth = false;
    });
    if (!isHealthy) {
      appState.setError(AppLocalizations.of(context)!.apiUnreachable);
    }
  }

  Future<void> _showDataDisclosureIfNeeded() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.hasAgreedToDisclosure && mounted) {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.dataDisclosure),
            content: Text(l10n.dataDisclosureMessage),
            actions: [
              TextButton(
                onPressed: () {
                  appState.setDisclosureAgreed(true);
                  Navigator.of(context).pop();
                },
                child: Text(l10n.agree),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Colors.white.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcomeToAeraSync,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.welcomeDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!_isApiHealthy) ...[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.red.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l10n.apiUnreachable)),
                              TextButton(
                                onPressed: _checkApiHealth,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton(
                        onPressed: _isApiHealthy
                            ? () => Navigator.pushNamed(context, '/survey')
                            : null,
                        child: Text(l10n.startSurvey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.selectLanguage),
                          const SizedBox(width: 8),
                          DropdownButton<Locale>(
                            value: appState.locale,
                            items: AppLocalizations.supportedLocales
                                .map((locale) => DropdownMenuItem(
                                      value: locale,
                                      child: Text(locale.languageCode.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (locale) {
                              if (locale != null) {
                                appState.locale = locale;
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
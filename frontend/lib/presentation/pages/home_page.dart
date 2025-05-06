import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_state.dart';
import '../widgets/utils/wave_background.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Toggle disclosure dialog
  static const bool _showDisclosureDialog = true;

  bool _isApiHealthy = true;
  bool _isCheckingHealth = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
    if (_showDisclosureDialog) {
      _showDataDisclosureIfNeeded();
    }

    // Initialize wave animation controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Text(l10n.dataDisclosure),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dataDisclosureMessage),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    const url = 'https://aerasync-web.vercel.app/privacy.html';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    l10n.learnMore,
                    style: const TextStyle(
                      color: Color(0xFF1E40AF),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace SVG with Image widget for WebP file
            Image.asset(
              'web/icons/watermark.webp',
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(l10n.appTitle, style: const TextStyle(color: Color.fromARGB(255, 40, 130, 225))),
          ],
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background wave animation
              WaveBackground(animation: _waveController.value),

              // Content
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.black54.withAlpha(0),
                      color: const Color.fromARGB(255, 255, 255, 255).withAlpha(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: l10n.welcomeToAeraSync,
                              child: Text(
                                l10n.welcomeToAeraSync,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_isApiHealthy) ...[
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
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
                              style: AppTheme.primaryButtonStyle,
                              onPressed: _isApiHealthy &&
                                      (!_showDisclosureDialog ||
                                          appState.hasAgreedToDisclosure)
                                  ? () =>
                                      Navigator.pushNamed(context, '/survey')
                                  : null,
                              child: Text(
                                l10n.startSurvey,
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              label: l10n.selectLanguage,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(l10n.selectLanguage),
                                  const SizedBox(width: 8),
                                  DropdownButton<Locale>(
                                    value: appState.locale,
                                    items: AppLocalizations.supportedLocales
                                        .map((locale) => DropdownMenuItem(
                                              value: locale,
                                              child: Text(locale.languageCode
                                                  .toUpperCase()),
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
      ),
    );
  }
}

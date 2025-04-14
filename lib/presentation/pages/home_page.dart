import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasAgreedToDataDisclosure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDataDisclosurePopup();
    });
  }

  void _showDataDisclosurePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.dataDisclosureTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dataDisclosureMessage),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final url = Uri.parse(
                      'https://luisvinatea.github.io/AeraSync/privacy.html');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  l10n.privacyPolicy ?? 'Privacy Policy', // Replace with the correct localization key, or use a hardcoded string like 'Privacy Policy'
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
                setState(() {
                  _hasAgreedToDataDisclosure = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.disagreeMessage ?? 'Disagreed')),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.disagreeButton),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasAgreedToDataDisclosure = true;
                });
                Navigator.of(context).pop();
              },
              child: Text(l10n.agreeButton),
            ),
          ],
        );
      },
    );
  }

  void _changeLocale(String locale) {
    switch (locale) {
      case 'es':
        break;
      case 'pt':
        break;
      default:
    }
    // This function currently does not change the app's locale.
    // Implement the logic in your app's state management to apply the newLocale.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasAgreedToDataDisclosure) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: const Color(0xFF1E40AF),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLocale,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text(l10n.languageEnglish ?? 'English'),
              ),
              PopupMenuItem(
                value: 'es',
                child: Text(l10n.languageSpanish ?? 'Español'),
              ),
              PopupMenuItem(
                value: 'pt',
                child: Text(l10n.languagePortuguese ?? 'Português'),
              ),
            ],
            icon: const Icon(Icons.language),
            tooltip: l10n.changeLanguageTooltip,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeTitle ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF1E40AF),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.welcomeMessage ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Tooltip(
                            message: l10n.startSurveyTooltip,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const SurveyPage()),
                                );
                              },
                              icon: const Icon(Icons.calculate),
                              label: Text(l10n.startAeratorComparison ?? ''),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Features Section
                Card(
                  elevation: 4,
                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.featuresTitle ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF1E40AF),
                              ),
                        ),
                        const SizedBox(height: 8),
                        _FeatureItem(
                          icon: Icons.compare_arrows,
                          title: l10n.featureCompareAerators,
                          description: l10n.featureCompareAeratorsDesc,
                        ),
                        _FeatureItem(
                          icon: Icons.attach_money,
                          title: l10n.featureFinancialAnalysis,
                          description: l10n.featureFinancialAnalysisDesc,
                        ),
                        _FeatureItem(
                          icon: Icons.water,
                          title: l10n.featureOxygenDemand,
                          description: l10n.featureOxygenDemandDesc,
                        ),
                        // Add a SizedBox to separate the last feature from the card's bottom if needed
                        // const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on AppLocalizations {
  String? get privacyPolicy => null;
  
  String? get disagreeMessage => null;
  
  String? get languageEnglish => null;
  
  String? get languageSpanish => null;
  
  String? get languagePortuguese => null;
  
  get changeLanguageTooltip => null;
  
  String? get welcomeTitle => null;
  
  String? get welcomeMessage => null;
  
  get startSurveyTooltip => null;
  
  String? get startAeratorComparison => null;
  
  String? get featuresTitle => null;
  
  get featureCompareAerators => null;
  
  get featureCompareAeratorsDesc => null;
  
  get featureFinancialAnalysis => null;
  
  get featureFinancialAnalysisDesc => null;
  
  get featureOxygenDemand => null;
  
  get featureOxygenDemandDesc => null;
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1E40AF), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

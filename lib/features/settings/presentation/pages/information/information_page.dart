// Pagina Informazioni delle impostazioni: Stato dell'app (nome, versione
// con le novità, build) e Crediti e licenze. Privacy e assistenza hanno
// le loro pagine (Privacy e legale, Assistenza).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';

import 'information_app_page.dart';
import 'information_credits_page.dart';
import 'information_licenses_page.dart';
import 'information_sub_item.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  bool _appExpanded = false;
  bool _creditsExpanded = false;

  static const Color _backgroundColor = AmaterasuColors.surfaceDeep;
  static const Color _titleColor = AmaterasuColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          l10n.settingsInformation,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          AmaterasuSettingsCard(
            key: const Key('information-app'),
            icon: Icons.verified_outlined,
            title: l10n.informationApp,
            subtitle: l10n.informationAppSubtitle,
            isExpanded: _appExpanded,
            onTap: () {
              setState(() {
                _appExpanded = !_appExpanded;
              });
            },
            children: const [InformationAppPage()],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('information-credits'),
            icon: Icons.favorite_border,
            title: l10n.informationCredits,
            subtitle: l10n.informationCreditsSubtitle,
            isExpanded: _creditsExpanded,
            onTap: () {
              setState(() {
                _creditsExpanded = !_creditsExpanded;
              });
            },
            children: [
              const InformationCreditsPage(),
              const SizedBox(height: 10),
              InformationSubItem(
                key: const Key('information-licenses'),
                icon: Icons.description_outlined,
                title: l10n.informationOpenSourceLicenses,
                subtitle: l10n.informationOpenSourceLicensesSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const InformationLicensesPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

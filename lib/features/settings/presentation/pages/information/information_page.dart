import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';

import 'information_app_page.dart';
import 'information_legal_page.dart';
import 'information_support_page.dart';
import 'information_credits_page.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  bool _appExpanded = false;
  bool _legalExpanded = false;
  bool _supportExpanded = false;
  bool _creditsExpanded = false;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);

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
            icon: Icons.info_outline,
            title: l10n.informationApp,
            subtitle: l10n.informationAppSubtitle,
            isExpanded: _appExpanded,
            onTap: () {
              setState(() {
                _appExpanded = !_appExpanded;
              });
            },
            children: const [
              InformationAppPage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.gavel_outlined,
            title: l10n.informationLegal,
            subtitle: l10n.informationLegalSubtitle,
            isExpanded: _legalExpanded,
            onTap: () {
              setState(() {
                _legalExpanded = !_legalExpanded;
              });
            },
            children: const [
              InformationLegalPage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.support_agent_outlined,
            title: l10n.informationSupport,
            subtitle: l10n.informationSupportSubtitle,
            isExpanded: _supportExpanded,
            onTap: () {
              setState(() {
                _supportExpanded = !_supportExpanded;
              });
            },
            children: const [
              InformationSupportPage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.favorite_border,
            title: l10n.informationCredits,
            subtitle: l10n.informationCreditsSubtitle,
            isExpanded: _creditsExpanded,
            onTap: () {
              setState(() {
                _creditsExpanded = !_creditsExpanded;
              });
            },
            children: const [
              InformationCreditsPage(),
            ],
          ),
        ],
      ),
    );
  }
}
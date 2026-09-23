import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_consent_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_export_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_permissions_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _permissionsExpanded = false;
  bool _consentExpanded = false;
  bool _exportExpanded = false;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://atlaslanternproject.github.io/AmaterasuTrip/privacy.html',
  );

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(_privacyPolicyUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          l10n.privacyTitle,
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
          Text(
            l10n.privacyIntro,
            style: const TextStyle(
              color: _subtitleColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          AmaterasuSettingsCard(
            icon: Icons.policy_outlined,
            title: l10n.privacyDataTitle,
            subtitle: l10n.privacyDataSubtitle,
            onTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.admin_panel_settings_outlined,
            title: l10n.privacyPermissionsTitle,
            subtitle: l10n.privacyPermissionsSubtitle,
            isExpanded: _permissionsExpanded,
            onTap: () {
              setState(() {
                _permissionsExpanded = !_permissionsExpanded;
              });
            },
            children: const [PrivacyPermissionsPage()],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.fact_check_outlined,
            title: l10n.privacyConsentTitle,
            subtitle: l10n.privacyConsentSubtitle,
            isExpanded: _consentExpanded,
            onTap: () {
              setState(() {
                _consentExpanded = !_consentExpanded;
              });
            },
            children: const [PrivacyConsentPage()],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.download_outlined,
            title: l10n.privacyExportTitle,
            subtitle: l10n.privacyExportSubtitle,
            isExpanded: _exportExpanded,
            onTap: () {
              setState(() {
                _exportExpanded = !_exportExpanded;
              });
            },
            children: const [PrivacyExportPage()],
          ),
        ],
      ),
    );
  }
}

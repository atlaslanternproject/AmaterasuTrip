import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_consent_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_data_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_export_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_permissions_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const Color _backgroundColor = Color(0xFF120F0D);
  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _accentColor = Color(0xFFD49A52);

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        title: Text(l10n.privacyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          _PrivacyTile(
            icon: Icons.policy_outlined,
            title: l10n.privacyDataTitle,
            subtitle: l10n.privacyDataSubtitle,
            onTap: () {
              _openPage(context, const PrivacyDataPage());
            },
          ),
          const SizedBox(height: 12),
          _PrivacyTile(
            icon: Icons.admin_panel_settings_outlined,
            title: l10n.privacyPermissionsTitle,
            subtitle: l10n.privacyPermissionsSubtitle,
            onTap: () {
              _openPage(context, const PrivacyPermissionsPage());
            },
          ),
          const SizedBox(height: 12),
          _PrivacyTile(
            icon: Icons.fact_check_outlined,
            title: l10n.privacyConsentTitle,
            subtitle: l10n.privacyConsentSubtitle,
            onTap: () {
              _openPage(context, const PrivacyConsentPage());
            },
          ),
          const SizedBox(height: 12),
          _PrivacyTile(
            icon: Icons.download_outlined,
            title: l10n.privacyExportTitle,
            subtitle: l10n.privacyExportSubtitle,
            onTap: () {
              _openPage(context, const PrivacyExportPage());
            },
          ),
        ],
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PrivacyPage._cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PrivacyPage._borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PrivacyPage._accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: PrivacyPage._accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PrivacyPage._titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PrivacyPage._subtitleColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: PrivacyPage._subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

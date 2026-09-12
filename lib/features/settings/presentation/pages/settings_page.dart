import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
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
          l10n.settingsTitle,
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
            icon: Icons.lock_outline,
            title: l10n.settingsAccount,
            subtitle: l10n.settingsAccountSubtitle,
            onTap: () {
              context.push('/settings/account');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.shield_outlined,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacySubtitle,
            onTap: () {
              context.push('/settings/privacy');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.person_outline,
            title: l10n.settingsProfile,
            subtitle: l10n.settingsProfileSubtitle,
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageSubtitle,
            onTap: () {
              context.push('/settings/language');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.notifications_none,
            title: l10n.settingsNotifications,
            subtitle: l10n.settingsNotificationsSubtitle,
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.cloud_outlined,
            title: l10n.settingsDataSync,
            subtitle: l10n.settingsDataSyncSubtitle,
            onTap: () {
              context.push('/settings/data');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.info_outline,
            title: l10n.settingsInformation,
            subtitle: l10n.settingsInformationSubtitle,
            onTap: () {
              context.push('/settings/information');
            },
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLanguage),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsProfile),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            onTap: () {
              context.push('/settings/language');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsNotifications),
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settingsAccount),
            onTap: () {
              context.push('/settings/account');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l10n.settingsPrivacy),
            onTap: () {
              context.push('/settings/privacy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.settingsDataSync),
            onTap: () {
              context.push('/settings/data-sync');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsInformation),
            onTap: () {
              context.push('/settings/information');
            },
          ),
        ],
      ),
    );
  }
}
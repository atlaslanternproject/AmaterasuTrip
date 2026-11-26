// Pagina principale delle impostazioni: Account, Profilo, Lingua, Aspetto,
// Dati, Privacy e legale, Assistenza, Informazioni (schema del 26/11/2026),
// tutte con la stessa distanza tra le card.

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';

import 'package:amaterasutrip/features/settings/presentation/pages/account/account_logout.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            key: const Key('settings-account'),
            icon: Icons.lock_outline,
            title: l10n.settingsAccount,
            subtitle: l10n.settingsAccountSubtitle,
            onTap: () {
              context.push('/settings/account');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-profile'),
            icon: Icons.person_outline,
            title: l10n.settingsProfile,
            subtitle: l10n.settingsProfileSubtitle,
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-language'),
            icon: Icons.language,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageSubtitle,
            onTap: () {
              context.push('/settings/language');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-appearance'),
            icon: Icons.text_fields_rounded,
            title: l10n.settingsAppearance,
            subtitle: l10n.settingsAppearanceSubtitle,
            onTap: () {
              context.push('/settings/appearance');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-data'),
            icon: Icons.cloud_outlined,
            title: l10n.settingsDataSync,
            subtitle: l10n.settingsDataSyncSubtitle,
            onTap: () {
              context.push('/settings/data');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-privacy'),
            icon: Icons.shield_outlined,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacySubtitle,
            onTap: () {
              context.push('/settings/privacy');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-support'),
            icon: Icons.support_agent_rounded,
            title: l10n.settingsSupport,
            subtitle: l10n.settingsSupportSubtitle,
            onTap: () {
              context.push('/settings/support');
            },
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('settings-information'),
            icon: Icons.info_outline,
            title: l10n.settingsInformation,
            subtitle: l10n.settingsInformationSubtitle,
            onTap: () {
              context.push('/settings/information');
            },
          ),
          const SizedBox(height: 10),
          const AccountLogoutPage(),
        ],
      ),
    );
  }
}

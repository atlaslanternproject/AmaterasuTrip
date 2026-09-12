import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _chevronColor = Color(0xFFB89B7A);
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
          _SettingsCard(
            icon: Icons.lock_outline,
            title: l10n.settingsAccount,
            subtitle: l10n.settingsAccountSubtitle,
            onTap: () {
              context.push('/settings/account');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageSubtitle,
            onTap: () {
              context.push('/settings/language');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.person_outline,
            title: l10n.settingsProfile,
            subtitle: l10n.settingsProfileSubtitle,
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotifications,
            subtitle: l10n.settingsNotificationsSubtitle,
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.shield_outlined,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacySubtitle,
            onTap: () {
              context.push('/settings/privacy');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.cloud_outlined,
            title: l10n.settingsDataSync,
            subtitle: l10n.settingsDataSyncSubtitle,
            onTap: () {
              context.push('/settings/data-sync');
            },
          ),
          const SizedBox(height: 10),
          _SettingsCard(
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
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: SettingsPage._cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SettingsPage._borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SettingsPage._accentColor.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: SettingsPage._accentColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SettingsPage._titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SettingsPage._subtitleColor,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right,
                  color: SettingsPage._chevronColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
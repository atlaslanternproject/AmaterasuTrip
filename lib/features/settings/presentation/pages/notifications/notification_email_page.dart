import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/settings/providers/notification_settings_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class NotificationEmailPage extends ConsumerWidget {
  const NotificationEmailPage({super.key});

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _cardColor = Color(0xFF1A1411);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        title: Text(l10n.notificationsEmailSection),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _EmailSettingsCard(
            children: [
              _RequiredEmailTile(
                icon: Icons.manage_accounts_outlined,
                title: l10n.notificationsAccountEmails,
                subtitle: l10n.notificationsAccountEmailsSubtitle,
              ),
              const _NotificationDivider(),
              _RequiredEmailTile(
                icon: Icons.info_outline,
                title: l10n.notificationsServiceEmails,
                subtitle: l10n.notificationsServiceEmailsSubtitle,
              ),
              const _NotificationDivider(),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                secondary: const Icon(
                  Icons.campaign_outlined,
                  color: _accentColor,
                ),
                title: Text(
                  l10n.notificationsPromotionalEmails,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.notificationsPromotionalEmailsSubtitle,
                    style: const TextStyle(
                      color: _subtitleColor,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
                value: settings.promotionalEmails,
                onChanged: notifier.setPromotionalEmails,
                activeThumbColor: _accentColor,
                activeTrackColor: _accentColor.withValues(alpha: 0.35),
                inactiveThumbColor: _subtitleColor,
                inactiveTrackColor: const Color(0xFF332A25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailSettingsCard extends StatelessWidget {
  const _EmailSettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NotificationEmailPage._cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NotificationEmailPage._accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _RequiredEmailTile extends StatelessWidget {
  const _RequiredEmailTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: NotificationEmailPage._accentColor),
      title: Text(
        title,
        style: const TextStyle(
          color: NotificationEmailPage._titleColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: NotificationEmailPage._subtitleColor,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _NotificationDivider extends StatelessWidget {
  const _NotificationDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFF302722),
    );
  }
}

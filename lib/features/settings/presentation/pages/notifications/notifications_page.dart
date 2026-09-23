import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/notifications/notification_email_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/notifications/notification_types_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _appExpanded = false;
  bool _emailExpanded = false;

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
          l10n.settingsNotifications,
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
            icon: Icons.notifications_active_outlined,
            title: l10n.notificationsAppSection,
            subtitle: l10n.notificationsPushSubtitle,
            isExpanded: _appExpanded,
            onTap: () {
              setState(() {
                _appExpanded = !_appExpanded;
              });
            },
            children: const [NotificationTypesPage()],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.alternate_email_outlined,
            title: l10n.notificationsEmailSection,
            subtitle: l10n.notificationsEmailSubtitle,
            isExpanded: _emailExpanded,
            onTap: () {
              setState(() {
                _emailExpanded = !_emailExpanded;
              });
            },
            children: const [NotificationEmailPage()],
          ),
        ],
      ),
    );
  }
}

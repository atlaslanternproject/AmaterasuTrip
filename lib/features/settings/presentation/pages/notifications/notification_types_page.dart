import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amaterasutrip/features/settings/providers/notification_permission_provider.dart';
import 'package:amaterasutrip/features/settings/providers/notification_settings_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class NotificationTypesPage extends ConsumerWidget {
  const NotificationTypesPage({super.key});

  static const Color _cardColor = Color(0xFF1A1411);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _disabledColor = Color(0xFF5E554F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Column(
      children: [
        _NotificationSwitchTile(
          title: l10n.notificationsPush,
          subtitle: l10n.notificationsPushSubtitle,
          value: settings.pushNotifications,
          onChanged: (value) async {
            if (!value) {
              await notifier.setPushNotifications(false);
              return;
            }

            final permissionStatus = await ref
                .read(notificationPermissionProvider.notifier)
                .requestPermission();

            if (permissionStatus.isGranted) {
              await notifier.setPushNotifications(true);
            } else {
              await notifier.setPushNotifications(false);
            }
          },
          isMaster: true,
        ),
        const SizedBox(height: 12),
        _NotificationSettingsCard(
          children: [
            _NotificationSwitchTile(
              title: l10n.notificationsTripReminders,
              subtitle: l10n.notificationsTripRemindersSubtitle,
              value: settings.tripReminders,
              enabled: settings.pushNotifications,
              onChanged: notifier.setTripReminders,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsItineraryReminders,
              subtitle: l10n.notificationsItineraryRemindersSubtitle,
              value: settings.itineraryReminders,
              enabled: settings.pushNotifications,
              onChanged: notifier.setItineraryReminders,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsTripUpdates,
              subtitle: l10n.notificationsTripUpdatesSubtitle,
              value: settings.tripUpdates,
              enabled: settings.pushNotifications,
              onChanged: notifier.setTripUpdates,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsGroupInvitations,
              subtitle: l10n.notificationsGroupInvitationsSubtitle,
              value: settings.groupInvitations,
              enabled: settings.pushNotifications,
              onChanged: notifier.setGroupInvitations,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsGroupActivity,
              subtitle: l10n.notificationsGroupActivitySubtitle,
              value: settings.groupActivity,
              enabled: settings.pushNotifications,
              onChanged: notifier.setGroupActivity,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsAppUpdates,
              subtitle: l10n.notificationsAppUpdatesSubtitle,
              value: settings.appUpdates,
              enabled: settings.pushNotifications,
              onChanged: notifier.setAppUpdates,
            ),
            const _NotificationDivider(),
            _NotificationSwitchTile(
              title: l10n.notificationsImportantCommunications,
              subtitle: l10n.notificationsImportantCommunicationsSubtitle,
              value: settings.importantCommunications,
              enabled: settings.pushNotifications,
              onChanged: notifier.setImportantCommunications,
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NotificationTypesPage._cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NotificationTypesPage._accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.isMaster = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final content = SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? NotificationTypesPage._titleColor
              : NotificationTypesPage._disabledColor,
          fontSize: 16,
          fontWeight: isMaster ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: enabled
                ? NotificationTypesPage._subtitleColor
                : NotificationTypesPage._disabledColor,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: NotificationTypesPage._accentColor,
      activeTrackColor: NotificationTypesPage._accentColor.withValues(
        alpha: 0.35,
      ),
      inactiveThumbColor: NotificationTypesPage._subtitleColor,
      inactiveTrackColor: const Color(0xFF332A25),
    );

    if (!isMaster) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: NotificationTypesPage._cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NotificationTypesPage._accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: content,
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

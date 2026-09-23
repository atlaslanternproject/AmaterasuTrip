import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyPermissionsPage extends StatelessWidget {
  const PrivacyPermissionsPage({super.key});

  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _textColor = Color(0xFFB8AAA0);
  static const Color _accentColor = Color(0xFFD49A52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyPermissionsIntro,
          style: const TextStyle(color: _textColor, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        _PermissionSection(
          icon: Icons.notifications_none_outlined,
          title: l10n.privacyPermissionsNotificationsTitle,
          body: l10n.privacyPermissionsNotificationsBody,
        ),
        _PermissionSection(
          icon: Icons.photo_library_outlined,
          title: l10n.privacyPermissionsMediaTitle,
          body: l10n.privacyPermissionsMediaBody,
        ),
        _PermissionSection(
          icon: Icons.location_on_outlined,
          title: l10n.privacyPermissionsLocationTitle,
          body: l10n.privacyPermissionsLocationBody,
        ),
      ],
    );
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PrivacyPermissionsPage._accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PrivacyPermissionsPage._titleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: PrivacyPermissionsPage._textColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

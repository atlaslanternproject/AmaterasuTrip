import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/profile/models/user_profile.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'profile_divider.dart';
import 'profile_info_row.dart';

class ProfileViewCard extends StatelessWidget {
  const ProfileViewCard({super.key, required this.profile});

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);

  final UserProfile profile;

  String _valueOrDash(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return '—';
    }

    return trimmed;
  }

  String get _fullName {
    final parts = <String>[
      if (profile.firstName?.trim().isNotEmpty ?? false)
        profile.firstName!.trim(),
      if (profile.lastName?.trim().isNotEmpty ?? false)
        profile.lastName!.trim(),
    ];

    if (parts.isEmpty) {
      return '—';
    }

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          ProfileInfoRow(
            icon: Icons.alternate_email,
            label: l10n.profileUsername,
            value: _valueOrDash(profile.username),
          ),
          const ProfileDivider(),
          ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: l10n.profileFullName,
            value: _fullName,
          ),
          const ProfileDivider(),
          ProfileInfoRow(
            icon: Icons.email_outlined,
            label: l10n.profileEmail,
            value: _valueOrDash(profile.email),
          ),
          const ProfileDivider(),
          ProfileInfoRow(
            icon: Icons.notes_outlined,
            label: l10n.profileBio,
            value: _valueOrDash(profile.bio),
            alignTop: true,
          ),
        ],
      ),
    );
  }
}

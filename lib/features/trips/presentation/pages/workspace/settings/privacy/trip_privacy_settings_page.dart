import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripPrivacySettingsPage extends StatelessWidget {
  const TripPrivacySettingsPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tripSettingsPrivacy,
              subtitle: l10n.tripPrivacyIntro,
              onBack: () => context.go('/trips/$tripId/settings'),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  AmaterasuSettingsCard(
                    icon: Icons.lock_outline_rounded,
                    title: l10n.tripPrivacyAccess,
                    subtitle: l10n.tripPrivacyAccessPrivate,
                    onTap: () {},
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  AmaterasuSettingsCard(
                    icon: Icons.link_rounded,
                    title: l10n.tripPrivacyInviteLink,
                    subtitle: l10n.tripPrivacyInviteLinkSubtitle,
                    onTap: () {},
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  AmaterasuSettingsCard(
                    icon: Icons.group_outlined,
                    title: l10n.tripPrivacyTravellers,
                    subtitle: l10n.tripPrivacyTravellersSubtitle,
                    onTap: () {
                      context.go('/trips/$tripId/settings/travellers');
                    },
                  ),
                  const SizedBox(height: 10),
                  AmaterasuSettingsCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: l10n.tripPrivacyRoles,
                    subtitle: l10n.tripPrivacyRolesSubtitle,
                    onTap: () {},
                    enabled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: TripPrivacySettingsPage._titleColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TripPrivacySettingsPage._titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TripPrivacySettingsPage._secondaryTextColor,
                    fontSize: 13,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_workspace_bottom_bar.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripSettingsPage extends StatelessWidget {
  const TripSettingsPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _surfaceColor = Color(0xFF1A1310);
  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _TripSettingsItem(
        title: l10n.tripSettingsInformation,
        subtitle: l10n.tripSettingsInformationSubtitle,
        icon: Icons.info_outline_rounded,
        route: '/trips/$tripId/settings/information',
      ),
      _TripSettingsItem(
        title: l10n.tripSettingsTravellers,
        subtitle: l10n.tripSettingsTravellersSubtitle,
        icon: Icons.group_outlined,
        route: '/trips/$tripId/settings/travellers',
      ),
      _TripSettingsItem(
        title: l10n.tripSettingsNotifications,
        subtitle: l10n.tripSettingsNotificationsSubtitle,
        icon: Icons.notifications_none_rounded,
        route: '/trips/$tripId/settings/notifications',
      ),
      _TripSettingsItem(
        title: l10n.tripSettingsPrivacy,
        subtitle: l10n.tripSettingsPrivacySubtitle,
        icon: Icons.lock_outline_rounded,
        route: '/trips/$tripId/settings/privacy',
      ),
      _TripSettingsItem(
        title: l10n.tripSettingsManagement,
        subtitle: l10n.tripSettingsManagementSubtitle,
        icon: Icons.tune_rounded,
        route: '/trips/$tripId/settings/management',
      ),
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: TripWorkspaceBottomBar(
        tripId: tripId,
        currentSection: TripWorkspaceSection.more,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/trips/$tripId/more'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripSettingsTitle,
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tripSettingsSubtitle,
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return _SettingsCard(
                    item: item,
                    onTap: () => context.go(item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.item, required this.onTap});

  final _TripSettingsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TripSettingsPage._surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TripSettingsPage._borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: TripSettingsPage._accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: TripSettingsPage._accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: TripSettingsPage._titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: TripSettingsPage._secondaryTextColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: TripSettingsPage._secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripSettingsItem {
  const _TripSettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

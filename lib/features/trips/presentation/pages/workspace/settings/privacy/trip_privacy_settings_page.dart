import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/domain/access/trip_access.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

final _tripInviteStatusProvider = FutureProvider.autoDispose
    .family<TripInviteStatus, String>((ref, tripId) {
      return ref
          .watch(tripInviteRepositoryProvider)
          .getTripInviteStatus(tripId: tripId);
    });

class TripPrivacySettingsPage extends ConsumerWidget {
  const TripPrivacySettingsPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);

  static const Color _accentColor = Color(0xFFE28A32);

  static const Color _titleColor = Color(0xFFF2E7D5);

  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  static const Color _surfaceColor = Color(0xFF1A1512);

  static const Color _borderColor = Color(0xFF3A2A20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final tripAsync = ref.watch(tripProvider(tripId));

    final access = ref.watch(tripAccessProvider(tripId));

    final inviteStatusAsync = ref.watch(_tripInviteStatusProvider(tripId));

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
              child: tripAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
                error: (error, stackTrace) =>
                    _CenteredMessage(text: l10n.tripPrivacyLoadError),
                data: (trip) {
                  if (trip == null) {
                    return _CenteredMessage(text: l10n.tripOverviewNotFound);
                  }

                  final canView =
                      access?.can(TripPermission.viewPrivacy) ?? false;

                  if (!canView) {
                    return _CenteredMessage(text: l10n.tripPrivacyAccessDenied);
                  }

                  final canManageInvitations =
                      access?.can(TripPermission.manageInvitations) ?? false;

                  final canViewTravellers =
                      access?.can(TripPermission.viewTravellers) ?? false;

                  final canManageRoles =
                      access?.can(TripPermission.manageRoles) ?? false;

                  final roleLabel = _roleLabel(l10n, access!.role);

                  final inviteStatus = _inviteStatusLabel(
                    l10n,
                    inviteStatusAsync,
                  );

                  final archive = trip.cloudArchive;

                  final archiveText = archive == null
                      ? l10n.tripPrivacyExternalArchiveNone
                      : l10n.tripPrivacyExternalArchiveConnected(
                          _providerLabel(l10n, archive.provider),
                        );

                  final rolesText = canManageRoles
                      ? l10n.tripPrivacyRolesCurrentAllowed(roleLabel)
                      : l10n.tripPrivacyRolesCurrentReadOnly(roleLabel);

                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _SectionTitle(l10n.tripPrivacyAccessSection),

                      const SizedBox(height: 8),

                      _PrivacyNoticeCard(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.tripPrivacyAccess,
                        body: l10n.tripPrivacyAccessPrivateDetail,
                      ),

                      const SizedBox(height: 10),

                      AmaterasuSettingsCard(
                        icon: Icons.link_rounded,
                        title: l10n.tripPrivacyInviteLink,
                        subtitle: l10n.tripPrivacyInviteLinkWithStatus(
                          inviteStatus,
                        ),
                        onTap: () {
                          context.go('/trips/$tripId/settings/travellers');
                        },
                        enabled: canManageInvitations,
                      ),

                      const SizedBox(height: 10),

                      AmaterasuSettingsCard(
                        icon: Icons.group_outlined,
                        title: l10n.tripPrivacyTravellers,
                        subtitle: l10n.tripPrivacyTravellersSubtitle,
                        onTap: () {
                          context.go('/trips/$tripId/settings/travellers');
                        },
                        enabled: canViewTravellers,
                      ),

                      const SizedBox(height: 24),

                      _SectionTitle(l10n.tripPrivacyProfileSection),

                      const SizedBox(height: 8),

                      AmaterasuSettingsCard(
                        icon: Icons.badge_outlined,
                        title: l10n.tripPrivacyProfileData,
                        subtitle: l10n.tripPrivacyProfileDataSubtitle,
                        onTap: () {
                          context.go('/trips/$tripId/settings/travellers');
                        },
                        enabled: canViewTravellers,
                      ),

                      const SizedBox(height: 10),

                      _PrivacyNoticeCard(
                        icon: Icons.shield_outlined,
                        title: l10n.tripPrivacyProfileData,
                        body:
                            '${l10n.tripTravellersSensitiveDataNotice}\n\n'
                            '${l10n.tripTravellersEditProfileNote}',
                      ),

                      const SizedBox(height: 24),

                      _SectionTitle(l10n.tripPrivacyRolesSection),

                      const SizedBox(height: 8),

                      _PrivacyNoticeCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: l10n.tripPrivacyRoles,
                        body: rolesText,
                      ),

                      const SizedBox(height: 24),

                      _SectionTitle(l10n.tripPrivacyExternalSection),

                      const SizedBox(height: 8),

                      _PrivacyNoticeCard(
                        icon: Icons.cloud_outlined,
                        title: l10n.tripPrivacyExternalArchive,
                        body:
                            '$archiveText\n\n'
                            '${l10n.tripPrivacyExternalControl}',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _inviteStatusLabel(
    AppLocalizations l10n,
    AsyncValue<TripInviteStatus> status,
  ) {
    return status.when(
      loading: () => l10n.tripPrivacyInviteStatusChecking,
      error: (error, stackTrace) => l10n.tripPrivacyInviteStatusUnavailable,
      data: (value) {
        return switch (value) {
          TripInviteStatus.missing => l10n.tripPrivacyInviteStatusMissing,
          TripInviteStatus.active => l10n.tripPrivacyInviteStatusActive,
          TripInviteStatus.revoked => l10n.tripPrivacyInviteStatusRevoked,
        };
      },
    );
  }

  String _roleLabel(AppLocalizations l10n, TripRole role) {
    return switch (role) {
      TripRole.owner => l10n.tripTravellersOwnerRole,
      TripRole.traveler => l10n.tripTravellersTravelerRole,
    };
  }

  String _providerLabel(AppLocalizations l10n, TripCloudProvider provider) {
    return switch (provider) {
      TripCloudProvider.googleDrive => l10n.tripCloudGoogleDrive,
      TripCloudProvider.oneDrive => l10n.tripCloudOneDrive,
      TripCloudProvider.dropbox => l10n.tripCloudDropbox,
    };
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
                    height: 1.3,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: TripPrivacySettingsPage._secondaryTextColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TripPrivacySettingsPage._surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TripPrivacySettingsPage._borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TripPrivacySettingsPage._accentColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: TripPrivacySettingsPage._accentColor,
              size: 22,
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
                    color: TripPrivacySettingsPage._titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: TripPrivacySettingsPage._secondaryTextColor,
                    fontSize: 13,
                    height: 1.45,
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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TripPrivacySettingsPage._secondaryTextColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive_selection.dart';
import 'package:amaterasutrip/features/trips/data/services/trip_archive_management_service.dart';
import 'package:amaterasutrip/features/trips/data/services/trip_archive_naming_service.dart';
import 'package:amaterasutrip/features/trips/domain/access/trip_access.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/settings/management/trip_delete_confirmation_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/cloud_archive/trip_cloud_archive_page.dart';
import 'package:amaterasutrip/features/trips/providers/trip_cloud_archive_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_management_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripManagementSettingsPage extends ConsumerStatefulWidget {
  const TripManagementSettingsPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);

  static const Color _surfaceColor = Color(0xFF1A1512);

  static const Color _borderColor = Color(0xFF3A2A20);

  static const Color _accentColor = Color(0xFFE28A32);

  static const Color _titleColor = Color(0xFFF2E7D5);

  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  ConsumerState<TripManagementSettingsPage> createState() =>
      _TripManagementSettingsPageState();
}

class _TripManagementSettingsPageState
    extends ConsumerState<TripManagementSettingsPage> {
  TripArchiveStatus _archiveStatus = TripArchiveStatus.unchecked;

  String? _verifiedFolderName;

  bool _initialVerificationStarted = false;

  bool _working = false;

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _startInitialVerification(TripCloudArchive archive) {
    if (_initialVerificationStarted ||
        archive.provider != TripCloudProvider.googleDrive) {
      return;
    }

    _initialVerificationStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _verifyArchive(archive);
      }
    });
  }

  Future<void> _verifyArchive(
    TripCloudArchive archive, {
    bool showSuccess = false,
  }) async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final result = await ref
          .read(tripArchiveManagementServiceProvider)
          .verify(archive);

      if (!mounted) {
        return;
      }

      setState(() {
        _archiveStatus = result.status;
        _verifiedFolderName = result.folderName;
      });

      if (showSuccess && result.status == TripArchiveStatus.available) {
        _showMessage(
          AppLocalizations.of(context)!.tripManagementArchiveVerified,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _archiveStatus = TripArchiveStatus.error;
      });

      _showMessage(AppLocalizations.of(context)!.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _openArchive(TripCloudArchive archive) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _working = true;
    });

    try {
      await ref.read(tripArchiveManagementServiceProvider).open(archive);
    } catch (_) {
      _showMessage(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _reconnectArchive(TripCloudArchive archive) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _working = true;
    });

    try {
      final result = await ref
          .read(tripArchiveManagementServiceProvider)
          .reconnect(archive);

      if (!mounted) {
        return;
      }

      setState(() {
        _archiveStatus = result.status;
        _verifiedFolderName = result.folderName;
      });

      if (result.status == TripArchiveStatus.available) {
        _showMessage(l10n.tripManagementArchiveReconnectSuccess);
      } else {
        _showMessage(l10n.tripManagementArchiveReconnectUnavailable);
      }
    } catch (_) {
      _showMessage(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _configureOrChangeArchive(Trip trip) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final hasCurrentArchive =
        trip.cloudArchive != null &&
        trip.cloudArchive!.folderId.trim().isNotEmpty;

    if (hasCurrentArchive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: TripManagementSettingsPage._surfaceColor,
            surfaceTintColor: Colors.transparent,
            title: Text(
              l10n.tripManagementArchiveChangeTitle,
              style: const TextStyle(
                color: TripManagementSettingsPage._titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              l10n.tripManagementArchiveChangeBody,
              style: const TextStyle(
                color: TripManagementSettingsPage._secondaryTextColor,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.tripManagementCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.tripManagementArchiveChangeConfirm),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final selection = await Navigator.of(context)
        .push<TripCloudArchiveSelection>(
          MaterialPageRoute<TripCloudArchiveSelection>(
            builder: (_) =>
                TripCloudArchivePage(currentArchive: trip.cloudArchive),
          ),
        );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final folderName = const TripArchiveNamingService().buildTripFolderName(
        tripName: trip.name,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
      );

      final archive = await ref
          .read(googleDriveArchiveServiceProvider)
          .createTripArchive(
            tripName: folderName,
            parentFolderId: selection.parentFolderId,
          );

      await ref
          .read(tripManagementRepositoryProvider)
          .updateCloudArchive(tripId: trip.id, archive: archive);

      if (!mounted) {
        return;
      }

      setState(() {
        _archiveStatus = TripArchiveStatus.available;
        _verifiedFolderName = archive.folderName;
        _initialVerificationStarted = true;
      });

      _showMessage(l10n.tripManagementArchiveChanged);
    } catch (_) {
      _showMessage(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _changeStatus(Trip trip) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final closing = trip.status == TripStatus.active;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: TripManagementSettingsPage._surfaceColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            closing
                ? l10n.tripManagementFinalArchiveConfirmTitle
                : l10n.tripManagementFinalReactivateConfirmTitle,
            style: const TextStyle(
              color: TripManagementSettingsPage._titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            closing
                ? l10n.tripManagementFinalArchiveConfirmBody
                : l10n.tripManagementFinalReactivateConfirmBody,
            style: const TextStyle(
              color: TripManagementSettingsPage._secondaryTextColor,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tripManagementCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                closing
                    ? l10n.tripManagementFinalArchiveConfirmAction
                    : l10n.tripManagementFinalReactivateConfirmAction,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await ref
          .read(tripManagementRepositoryProvider)
          .setStatus(
            tripId: trip.id,
            status: closing ? TripStatus.closed : TripStatus.active,
          );

      if (!mounted) {
        return;
      }

      _showMessage(l10n.tripManagementFinalStatusUpdated);
    } catch (_) {
      _showMessage(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _duplicateTrip(Trip trip) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: TripManagementSettingsPage._surfaceColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.tripManagementFinalDuplicateConfirmTitle,
            style: const TextStyle(
              color: TripManagementSettingsPage._titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.tripManagementFinalDuplicateConfirmBody,
            style: const TextStyle(
              color: TripManagementSettingsPage._secondaryTextColor,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tripManagementCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tripManagementFinalDuplicateConfirmAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final duplicateName = l10n.tripManagementFinalDuplicateCopyName(
        trip.name,
      );

      final newTripId = await ref
          .read(tripManagementRepositoryProvider)
          .duplicateTrip(tripId: trip.id, duplicateName: duplicateName);

      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      final openDuplicate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: TripManagementSettingsPage._surfaceColor,
            surfaceTintColor: Colors.transparent,
            title: Text(
              l10n.tripManagementFinalDuplicateSuccessTitle,
              style: const TextStyle(
                color: TripManagementSettingsPage._titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              l10n.tripManagementFinalDuplicateSuccessBody(duplicateName),
              style: const TextStyle(
                color: TripManagementSettingsPage._secondaryTextColor,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.tripManagementFinalStayHere),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.tripManagementFinalDuplicateOpen),
              ),
            ],
          );
        },
      );

      if (openDuplicate == true && mounted) {
        context.go('/trips/$newTripId');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _working = false;
        });

        _showMessage(l10n.tripManagementOperationError);
      }
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    if (_working) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) {
            return TripDeleteConfirmationDialog(tripName: trip.name);
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await ref
          .read(tripManagementRepositoryProvider)
          .deleteTrip(tripId: trip.id, confirmationName: trip.name);

      if (!mounted) {
        return;
      }

      context.go('/trips');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      _showMessage(l10n.tripManagementOperationError);
    }
  }

  String _archiveStatusLabel(AppLocalizations l10n, bool hasArchive) {
    if (!hasArchive) {
      return l10n.tripManagementArchiveNotConfigured;
    }

    if (_working && _archiveStatus == TripArchiveStatus.unchecked) {
      return l10n.tripManagementArchiveChecking;
    }

    return switch (_archiveStatus) {
      TripArchiveStatus.available => l10n.tripManagementArchiveAvailable,
      TripArchiveStatus.unchecked => l10n.tripManagementArchiveUnchecked,
      TripArchiveStatus.authorizationRequired =>
        l10n.tripManagementArchiveAuthorizationRequired,
      TripArchiveStatus.inaccessible => l10n.tripManagementArchiveInaccessible,
      TripArchiveStatus.notFound => l10n.tripManagementArchiveNotFound,
      TripArchiveStatus.insufficientSpace =>
        l10n.tripManagementArchiveInsufficientSpace,
      TripArchiveStatus.networkUnavailable =>
        l10n.tripManagementArchiveNetworkUnavailable,
      TripArchiveStatus.error => l10n.tripManagementArchiveError,
    };
  }

  String _providerLabel(AppLocalizations l10n, TripCloudProvider provider) {
    return switch (provider) {
      TripCloudProvider.googleDrive => l10n.tripCloudGoogleDrive,
      TripCloudProvider.oneDrive => l10n.tripCloudOneDrive,
      TripCloudProvider.dropbox => l10n.tripCloudDropbox,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tripAsync = ref.watch(tripProvider(widget.tripId));

    final access = ref.watch(tripAccessProvider(widget.tripId));

    return Scaffold(
      backgroundColor: TripManagementSettingsPage._backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tripSettingsManagement,
              subtitle: l10n.tripSettingsManagementSubtitle,
              onBack: () {
                context.go('/trips/${widget.tripId}/settings');
              },
            ),
            Expanded(
              child: tripAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: TripManagementSettingsPage._accentColor,
                  ),
                ),
                error: (_, _) =>
                    _CenteredMessage(text: l10n.tripManagementLoadError),
                data: (trip) {
                  if (trip == null) {
                    return _CenteredMessage(text: l10n.tripManagementLoadError);
                  }

                  final canView =
                      access?.can(TripPermission.viewManagement) ?? false;

                  if (!canView) {
                    return _CenteredMessage(
                      text: l10n.tripManagementFinalAccessDenied,
                    );
                  }

                  final canManageArchive =
                      access?.can(TripPermission.manageArchive) ?? false;

                  final canManageStatus =
                      access?.can(TripPermission.manageStatus) ?? false;

                  final canDuplicate =
                      access?.can(TripPermission.duplicateTrip) ?? false;

                  final canDelete =
                      access?.can(TripPermission.deleteTrip) ?? false;

                  final archive = trip.cloudArchive;

                  final hasArchive =
                      archive != null && archive.folderId.trim().isNotEmpty;

                  final googleDriveArchive =
                      hasArchive &&
                      archive.provider == TripCloudProvider.googleDrive;

                  if (hasArchive && googleDriveArchive) {
                    _startInitialVerification(archive);
                  }

                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _SectionTitle(l10n.tripManagementArchiveSection),
                      const SizedBox(height: 8),

                      _InfoCard(
                        icon: hasArchive
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        title: l10n.tripManagementArchiveStatus,
                        body: _archiveStatusLabel(l10n, hasArchive),
                      ),

                      if (hasArchive) ...[
                        const SizedBox(height: 10),
                        _InfoCard(
                          icon: Icons.folder_outlined,
                          title: l10n.tripManagementArchiveFolder,
                          body:
                              '${_providerLabel(l10n, archive.provider)}\n'
                              '${_verifiedFolderName ?? archive.folderName}',
                        ),
                      ],

                      const SizedBox(height: 10),

                      if (!hasArchive)
                        AmaterasuSettingsCard(
                          icon: Icons.cloud_upload_outlined,
                          title: l10n.tripManagementFinalConfigureArchive,
                          subtitle:
                              l10n.tripManagementFinalConfigureArchiveSubtitle,
                          onTap: () => _configureOrChangeArchive(trip),
                          enabled: !_working && canManageArchive,
                        ),

                      if (googleDriveArchive) ...[
                        AmaterasuSettingsCard(
                          icon: Icons.verified_outlined,
                          title: l10n.tripManagementArchiveVerify,
                          subtitle: l10n.tripManagementArchiveVerifySubtitle,
                          onTap: () =>
                              _verifyArchive(archive, showSuccess: true),
                          enabled: !_working && canManageArchive,
                        ),
                        const SizedBox(height: 10),
                        AmaterasuSettingsCard(
                          icon: Icons.open_in_new_rounded,
                          title: l10n.tripManagementArchiveOpen,
                          subtitle: l10n.tripManagementArchiveOpenSubtitle,
                          onTap: () => _openArchive(archive),
                          enabled: !_working && canManageArchive,
                        ),
                        const SizedBox(height: 10),
                        AmaterasuSettingsCard(
                          icon: Icons.sync_rounded,
                          title: l10n.tripManagementArchiveReconnect,
                          subtitle: l10n.tripManagementArchiveReconnectSubtitle,
                          onTap: () => _reconnectArchive(archive),
                          enabled: !_working && canManageArchive,
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (hasArchive && !googleDriveArchive) ...[
                        _InfoCard(
                          icon: Icons.info_outline_rounded,
                          title: l10n.tripManagementArchiveStatus,
                          body: l10n
                              .tripManagementFinalArchiveProviderUnsupported,
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (hasArchive)
                        AmaterasuSettingsCard(
                          icon: Icons.drive_file_move_outline,
                          title: l10n.tripManagementArchiveChange,
                          subtitle: l10n.tripManagementArchiveChangeSubtitle,
                          onTap: () => _configureOrChangeArchive(trip),
                          enabled: !_working && canManageArchive,
                        ),

                      const SizedBox(height: 10),

                      _InfoCard(
                        icon: Icons.shield_outlined,
                        title: l10n.tripManagementFinalArchiveOwnershipTitle,
                        body: l10n.tripManagementFinalArchiveOwnershipBody,
                      ),

                      const SizedBox(height: 26),

                      _SectionTitle(l10n.tripManagementFinalStatusSection),

                      const SizedBox(height: 8),

                      _InfoCard(
                        icon: trip.status == TripStatus.active
                            ? Icons.play_circle_outline_rounded
                            : Icons.inventory_2_outlined,
                        title: l10n.tripManagementFinalTripStatus,
                        body: trip.status == TripStatus.active
                            ? '${l10n.tripManagementFinalStatusActive}\n'
                                  '${l10n.tripManagementFinalStatusActiveBody}'
                            : '${l10n.tripManagementFinalStatusClosed}\n'
                                  '${l10n.tripManagementFinalStatusClosedBody}',
                      ),

                      const SizedBox(height: 10),

                      AmaterasuSettingsCard(
                        icon: trip.status == TripStatus.active
                            ? Icons.archive_outlined
                            : Icons.unarchive_outlined,
                        title: trip.status == TripStatus.active
                            ? l10n.tripManagementFinalArchiveAction
                            : l10n.tripManagementFinalReactivateAction,
                        subtitle: trip.status == TripStatus.active
                            ? l10n.tripManagementFinalArchiveActionSubtitle
                            : l10n.tripManagementFinalReactivateActionSubtitle,
                        onTap: () => _changeStatus(trip),
                        enabled: !_working && canManageStatus,
                      ),

                      const SizedBox(height: 26),

                      _SectionTitle(l10n.tripManagementFinalOperationsSection),

                      const SizedBox(height: 8),

                      AmaterasuSettingsCard(
                        icon: Icons.copy_all_outlined,
                        title: l10n.tripManagementDuplicate,
                        subtitle: l10n.tripManagementDuplicateSubtitle,
                        onTap: () => _duplicateTrip(trip),
                        enabled: !_working && canDuplicate,
                      ),

                      const SizedBox(height: 26),

                      _SectionTitle(l10n.tripManagementFinalDangerSection),

                      const SizedBox(height: 8),

                      AmaterasuSettingsCard(
                        icon: Icons.delete_forever_outlined,
                        title: l10n.tripManagementDelete,
                        subtitle: l10n.tripManagementDeleteSubtitle,
                        onTap: () => _deleteTrip(trip),
                        enabled: !_working && canDelete,
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
              color: TripManagementSettingsPage._titleColor,
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
                    color: TripManagementSettingsPage._titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TripManagementSettingsPage._secondaryTextColor,
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
        color: TripManagementSettingsPage._secondaryTextColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
        color: TripManagementSettingsPage._surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TripManagementSettingsPage._borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TripManagementSettingsPage._accentColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: TripManagementSettingsPage._accentColor,
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
                    color: TripManagementSettingsPage._titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: TripManagementSettingsPage._secondaryTextColor,
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
            color: TripManagementSettingsPage._secondaryTextColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

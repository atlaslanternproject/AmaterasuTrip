import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/services/trip_archive_management_service.dart';
import 'package:amaterasutrip/features/trips/data/services/trip_archive_naming_service.dart';
import 'package:amaterasutrip/features/trips/providers/trip_cloud_archive_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/cloud_archive/trip_cloud_archive_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripManagementSettingsPage extends ConsumerStatefulWidget {
  const TripManagementSettingsPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  ConsumerState<TripManagementSettingsPage> createState() =>
      _TripManagementSettingsPageState();
}

class _TripManagementSettingsPageState
    extends ConsumerState<TripManagementSettingsPage> {
  TripArchiveStatus _status = TripArchiveStatus.unchecked;
  String? _verifiedFolderName;

  bool _initialVerificationStarted = false;
  bool _busy = false;

  void _snack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _startInitialVerification(TripCloudArchive archive) {
    if (_initialVerificationStarted) return;

    _initialVerificationStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _verify(archive);
      }
    });
  }

  Future<void> _verify(
    TripCloudArchive archive, {
    bool showSuccess = false,
  }) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      final result = await ref
          .read(tripArchiveManagementServiceProvider)
          .verify(archive);

      if (!mounted) return;

      setState(() {
        _status = result.status;
        _verifiedFolderName = result.folderName;
      });

      if (showSuccess && result.status == TripArchiveStatus.available) {
        _snack(AppLocalizations.of(context)!.tripManagementArchiveVerified);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _status = TripArchiveStatus.error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _open(TripCloudArchive archive) async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _busy = true;
    });

    try {
      await ref.read(tripArchiveManagementServiceProvider).open(archive);
    } catch (_) {
      _snack(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _reconnect(TripCloudArchive archive) async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busy = true;
    });

    try {
      final result = await ref
          .read(tripArchiveManagementServiceProvider)
          .reconnect(archive);

      if (!mounted) return;
      setState(() {
        _status = result.status;
        _verifiedFolderName = result.folderName;
      });
      if (result.status == TripArchiveStatus.available) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.tripManagementArchiveReconnectSuccess)),
          );
      } else {
        _snack(l10n.tripManagementArchiveReconnectUnavailable);
      }
    } catch (_) {
      _snack(AppLocalizations.of(context)!.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _changeArchive(dynamic trip) async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tripManagementArchiveChangeTitle),
          content: Text(l10n.tripManagementArchiveChangeBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.tripManagementCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.tripManagementArchiveChangeConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final selection = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => TripCloudArchivePage(currentArchive: trip.cloudArchive),
      ),
    );

    if (selection == null || !mounted) return;

    setState(() {
      _busy = true;
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
          .read(tripRepositoryProvider)
          .updateCloudArchive(tripId: widget.tripId, cloudArchive: archive);

      if (!mounted) return;

      setState(() {
        _status = TripArchiveStatus.available;
        _verifiedFolderName = archive.folderName;
      });

      _snack(l10n.tripManagementArchiveChanged);
    } catch (_) {
      _snack(l10n.tripManagementOperationError);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteTrip() async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tripManagementDeleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tripManagementDeleteDriveWarning,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(l10n.tripManagementDeleteBody),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.tripManagementCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.tripManagementDeleteConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      await ref.read(tripRepositoryProvider).deleteTrip(tripId: widget.tripId);

      if (!mounted) return;

      context.go('/trips');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _busy = false;
      });

      _snack(l10n.tripManagementOperationError);
    }
  }

  String _statusLabel(AppLocalizations l10n, bool hasArchive) {
    if (!hasArchive) {
      return l10n.tripManagementArchiveNotConfigured;
    }

    if (_busy && _status == TripArchiveStatus.unchecked) {
      return l10n.tripManagementArchiveChecking;
    }

    return switch (_status) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      backgroundColor: TripManagementSettingsPage._backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tripSettingsManagement,
              onBack: () {
                context.go('/trips/${widget.tripId}/settings');
              },
            ),
            Expanded(
              child: tripAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    l10n.tripManagementLoadError,
                    style: const TextStyle(
                      color: TripManagementSettingsPage._titleColor,
                    ),
                  ),
                ),
                data: (trip) {
                  if (trip == null) {
                    return Center(
                      child: Text(
                        l10n.tripManagementLoadError,
                        style: const TextStyle(
                          color: TripManagementSettingsPage._titleColor,
                        ),
                      ),
                    );
                  }

                  final archive = trip.cloudArchive;

                  final hasArchive =
                      archive != null && archive.folderId.trim().isNotEmpty;

                  if (hasArchive) {
                    _startInitialVerification(archive);
                  }

                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      _SectionTitle(l10n.tripManagementArchiveSection),
                      const SizedBox(height: 8),

                      AmaterasuSettingsCard(
                        icon: hasArchive
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        title: l10n.tripManagementArchiveStatus,
                        subtitle: _statusLabel(l10n, hasArchive),
                        onTap: () {},
                        enabled: false,
                      ),

                      if (hasArchive) ...[
                        const SizedBox(height: 10),

                        AmaterasuSettingsCard(
                          icon: Icons.folder_outlined,
                          title: l10n.tripManagementArchiveFolder,
                          subtitle: _verifiedFolderName ?? archive.folderName,
                          onTap: () {},
                          enabled: false,
                        ),

                        const SizedBox(height: 10),

                        AmaterasuSettingsCard(
                          icon: Icons.verified_outlined,
                          title: l10n.tripManagementArchiveVerify,
                          subtitle: l10n.tripManagementArchiveVerifySubtitle,
                          onTap: () => _verify(archive, showSuccess: true),
                          enabled: !_busy,
                        ),

                        const SizedBox(height: 10),

                        AmaterasuSettingsCard(
                          icon: Icons.open_in_new_rounded,
                          title: l10n.tripManagementArchiveOpen,
                          subtitle: l10n.tripManagementArchiveOpenSubtitle,
                          onTap: () => _open(archive),
                          enabled: !_busy,
                        ),

                        const SizedBox(height: 10),

                        AmaterasuSettingsCard(
                          icon: Icons.drive_file_move_outline,
                          title: l10n.tripManagementArchiveChange,
                          subtitle: l10n.tripManagementArchiveChangeSubtitle,
                          onTap: () => _changeArchive(trip),
                          enabled: !_busy,
                        ),

                        const SizedBox(height: 10),

                        AmaterasuSettingsCard(
                          icon: Icons.sync_rounded,
                          title: l10n.tripManagementArchiveReconnect,
                          subtitle: l10n.tripManagementArchiveReconnectSubtitle,
                          onTap: () => _reconnect(archive),
                          enabled: !_busy,
                        ),
                      ],

                      const SizedBox(height: 24),

                      _SectionTitle(l10n.tripManagementOperationsSection),
                      const SizedBox(height: 8),

                      AmaterasuSettingsCard(
                        icon: Icons.file_download_outlined,
                        title: l10n.tripManagementExport,
                        subtitle: l10n.tripManagementExportSubtitle,
                        onTap: () {},
                        enabled: false,
                      ),

                      const SizedBox(height: 10),

                      AmaterasuSettingsCard(
                        icon: Icons.copy_all_outlined,
                        title: l10n.tripManagementDuplicate,
                        subtitle: l10n.tripManagementDuplicateSubtitle,
                        onTap: () {},
                        enabled: false,
                      ),

                      const SizedBox(height: 10),

                      AmaterasuSettingsCard(
                        icon: Icons.delete_outline_rounded,
                        title: l10n.tripManagementDelete,
                        subtitle: l10n.tripManagementDeleteSubtitle,
                        onTap: _deleteTrip,
                        enabled: !_busy,
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
  const _Header({required this.title, required this.onBack});

  final String title;
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
            child: Text(
              title,
              style: const TextStyle(
                color: TripManagementSettingsPage._titleColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
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

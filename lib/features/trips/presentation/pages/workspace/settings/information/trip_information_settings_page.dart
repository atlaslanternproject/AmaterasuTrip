import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/core/permissions/app_permission.dart';
import 'package:amaterasutrip/core/permissions/permission_provider.dart';
import 'package:amaterasutrip/core/permissions/permission_request_handler.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/widgets/trip_cover_source_sheet.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripInformationSettingsPage extends ConsumerStatefulWidget {
  const TripInformationSettingsPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripInformationSettingsPage> createState() =>
      _TripInformationSettingsPageState();
}

class _TripInformationSettingsPageState
    extends ConsumerState<TripInformationSettingsPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _surfaceColor = Color(0xFF1A1310);
  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _accentColor = Color(0xFFFF7A3D);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  bool _isUpdatingCover = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverLostCover();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: tripAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _accentColor),
          ),
          error: (error, stackTrace) => Center(
            child: Text(
              l10n.tripOverviewError,
              style: const TextStyle(color: _secondaryTextColor),
            ),
          ),
          data: (trip) {
            if (trip == null) {
              return Center(
                child: Text(
                  l10n.tripOverviewNotFound,
                  style: const TextStyle(color: _secondaryTextColor),
                ),
              );
            }

            return Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [_buildCoverSection(context, l10n, trip)],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/trips/${widget.tripId}/settings'),
            icon: const Icon(Icons.arrow_back_rounded, color: _titleColor),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.tripSettingsInformation,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection(
    BuildContext context,
    AppLocalizations l10n,
    Trip trip,
  ) {
    final coverUrl = trip.coverUrl?.trim();
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _CoverFallback(),
                    )
                  else
                    const _CoverFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                  if (_isUpdatingCover)
                    const ColoredBox(
                      color: Color(0x99000000),
                      child: Center(
                        child: CircularProgressIndicator(color: _accentColor),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tripCoverTitle,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.tripCoverSubtitle,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdatingCover
                        ? null
                        : () => _showCoverSourceSheet(context, trip),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: const Color(0xFF160B07),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      hasCover ? l10n.tripCoverChange : l10n.tripCoverAdd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCoverSourceSheet(BuildContext context, Trip trip) async {
    final hasCover = trip.coverUrl != null && trip.coverUrl!.trim().isNotEmpty;

    final action = await showTripCoverSourceSheet(
      context: context,
      hasCover: hasCover,
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case TripCoverSourceAction.camera:
        await _pickAndUploadCover(trip, fromCamera: true);

      case TripCoverSourceAction.gallery:
        await _pickAndUploadCover(trip, fromCamera: false);

      case TripCoverSourceAction.remove:
        await _removeCover(trip);
    }
  }
  Future<void> _pickAndUploadCover(
    Trip trip, {
    required bool fromCamera,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = ref.read(permissionServiceProvider);

    final permissionGranted = await requestAppPermission(
      context: context,
      permissionService: permissionService,
      permission: fromCamera ? AppPermission.camera : AppPermission.photos,
      deniedMessage: fromCamera
          ? l10n.tripCoverCameraPermissionDenied
          : l10n.tripCoverGalleryPermissionDenied,
      permanentlyDeniedMessage: fromCamera
          ? l10n.tripCoverCameraPermissionPermanentlyDenied
          : l10n.tripCoverGalleryPermissionPermanentlyDenied,
      openSettingsLabel: l10n.tripCoverOpenSettings,
    );

    if (!permissionGranted || !mounted) {
      return;
    }

    try {
      final picker = ref.read(tripCoverPickerServiceProvider);

      final selectedCover = fromCamera
          ? await picker.pickFromCamera()
          : await picker.pickFromGallery();

      if (!mounted || selectedCover == null) {
        return;
      }

      await _uploadSelectedCover(trip, selectedCover);
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripCoverPickerError);
      }
    }
  }
  Future<void> _uploadSelectedCover(Trip trip, XFile selectedCover) async {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingCover = true;
    });

    String? newStoragePath;

    try {
      final storage = ref.read(tripCoverStorageServiceProvider);
      final repository = ref.read(tripRepositoryProvider);

      final uploaded = await storage.uploadTripCover(
        tripId: trip.id,
        cover: selectedCover,
      );

      newStoragePath = uploaded.storagePath;

      await repository.updateTripCover(
        tripId: trip.id,
        coverUrl: uploaded.downloadUrl,
        coverPath: uploaded.storagePath,
      );

      final oldPath = trip.coverPath;

      if (oldPath != null &&
          oldPath.trim().isNotEmpty &&
          oldPath != uploaded.storagePath) {
        try {
          await storage.deleteTripCover(oldPath);
        } catch (_) {
          // La nuova cover Ã¨ giÃ  salvata correttamente.
          // La pulizia del vecchio file non deve annullare l'operazione.
        }
      }

      if (mounted) {
        _showMessage(l10n.tripCoverUpdated);
      }
    } catch (_) {
      if (newStoragePath != null) {
        try {
          await ref
              .read(tripCoverStorageServiceProvider)
              .deleteTripCover(newStoragePath);
        } catch (_) {
          // Evita di mascherare l'errore principale.
        }
      }

      if (mounted) {
        _showMessage(l10n.tripCoverUploadError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCover = false;
        });
      }
    }
  }

  Future<void> _recoverLostCover() async {
    if (_isUpdatingCover) {
      return;
    }

    final recovery = ref.read(tripCoverRecoveryServiceProvider);

    if (!await recovery.isPending()) {
      return;
    }

    final pendingTripId = await recovery.getPendingTripId();

    if (pendingTripId != widget.tripId) {
      return;
    }

    XFile? recoveredCover;

    try {
      recoveredCover = await ref
          .read(tripCoverPickerServiceProvider)
          .retrieveLostCover();
    } catch (_) {
      await recovery.clearRecovery();
      return;
    }

    if (recoveredCover == null) {
      await recovery.clearRecovery();
      return;
    }

    await recovery.saveRecoveredPath(recoveredCover.path);

    final recovered = await recovery.consumeRecoveredCover();

    if (recovered == null || recovered.tripId != widget.tripId || !mounted) {
      return;
    }

    final trip = await ref.read(tripProvider(widget.tripId).future);

    if (trip == null || !mounted) {
      return;
    }

    await _uploadSelectedCover(trip, XFile(recovered.path));
  }

  Future<void> _removeCover(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingCover = true;
    });

    try {
      final repository = ref.read(tripRepositoryProvider);
      final storage = ref.read(tripCoverStorageServiceProvider);

      await repository.removeTripCover(tripId: trip.id);

      try {
        await storage.deleteTripCover(trip.coverPath);
      } catch (_) {
        // Il riferimento Firestore Ã¨ giÃ  stato rimosso.
      }

      if (mounted) {
        _showMessage(l10n.tripCoverRemoved);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripCoverRemoveError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCover = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}



class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF35160F), Color(0xFF1C100D), Color(0xFF0D0908)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 64,
          color: Color(0x66FF8A4C),
        ),
      ),
    );
  }
}


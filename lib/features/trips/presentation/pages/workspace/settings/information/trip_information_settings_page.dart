import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/core/permissions/app_permission.dart';
import 'package:amaterasutrip/core/permissions/permission_provider.dart';
import 'package:amaterasutrip/core/permissions/permission_request_handler.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/trip_destination_page.dart';
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

  final DestinationPlacesService _placesService =
      const DestinationPlacesService();

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
                    children: [
                      _buildInformationSection(context, l10n, trip),
                      const SizedBox(height: 20),
                      _buildCoverSection(context, l10n, trip),
                    ],
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

  Widget _buildInformationSection(
    BuildContext context,
    AppLocalizations l10n,
    Trip trip,
  ) {
    final startDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(trip.startDate);

    final endDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(trip.endDate);

    final description = trip.description?.trim();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text(
              l10n.tripInformationSectionTitle,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _InformationRow(
            icon: Icons.badge_outlined,
            label: l10n.tripInformationName,
            value: trip.name,
            onTap: () => _editName(trip),
          ),
          _InformationRow(
            icon: Icons.location_on_outlined,
            label: l10n.tripInformationDestination,
            onTap: () => _editDestination(trip),
            value: trip.destination,
          ),
          _InformationRow(
            icon: Icons.flight_takeoff_rounded,
            label: l10n.tripInformationStartDate,
            onTap: () => _editStartDate(trip),
            value: startDate,
          ),
          _InformationRow(
            icon: Icons.flight_land_rounded,
            label: l10n.tripInformationEndDate,
            onTap: () => _editEndDate(trip),
            value: endDate,
          ),
          _InformationRow(
            icon: Icons.notes_rounded,
            label: l10n.tripInformationDescription,
            onTap: () => _editDescription(trip),
            value: description == null || description.isEmpty
                ? l10n.tripInformationDescriptionEmpty
                : description,
          ),
          _InformationRow(
            icon: Icons.currency_exchange_rounded,
            label: l10n.tripInformationCurrency,
            onTap: () => _editCurrency(trip),
            value: trip.currency.toUpperCase(),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Future<void> _editName(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: trip.name);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            l10n.tripInformationName,
            style: const TextStyle(color: _titleColor),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: _titleColor),
            decoration: InputDecoration(
              labelText: l10n.tripInformationName,
              labelStyle: const TextStyle(color: _secondaryTextColor),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _accentColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tripInformationCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: Text(l10n.tripInformationSave),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null || result == trip.name) {
      return;
    }

    await _saveTripInformation(trip: trip, name: result);
  }

  Future<void> _editDescription(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: trip.description ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            l10n.tripInformationDescription,
            style: const TextStyle(color: _titleColor),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: _titleColor),
            decoration: InputDecoration(
              hintText: l10n.tripInformationDescriptionEmpty,
              hintStyle: const TextStyle(color: _secondaryTextColor),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _accentColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tripInformationCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.tripInformationSave),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    if (result == (trip.description ?? '').trim()) {
      return;
    }

    await _saveTripInformation(trip: trip, description: result);
  }

  Future<void> _editDestination(Trip trip) async {
    final selectedDestination = await Navigator.of(context)
        .push<TripDestination>(
          MaterialPageRoute(
            builder: (context) =>
                TripDestinationPage(initialDestination: trip.destination),
          ),
        );

    if (!mounted || selectedDestination == null) {
      return;
    }

    var currency = trip.currency;

    final suggestedCurrency = selectedDestination.suggestedCurrencyLabel;

    if (suggestedCurrency != null) {
      currency = suggestedCurrency;
    }

    await _saveTripInformation(
      trip: trip,
      destination: selectedDestination,
      currency: currency,
    );
  }

  Future<void> _editStartDate(Trip trip) async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: trip.startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    var endDate = trip.endDate;

    if (endDate.isBefore(selectedDate)) {
      endDate = selectedDate;
    }

    await _saveTripInformation(
      trip: trip,
      startDate: selectedDate,
      endDate: endDate,
    );
  }

  Future<void> _editEndDate(Trip trip) async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: trip.endDate.isBefore(trip.startDate)
          ? trip.startDate
          : trip.endDate,
      firstDate: trip.startDate,
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    await _saveTripInformation(trip: trip, endDate: selectedDate);
  }

  Future<void> _editCurrency(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    List<TripCurrency> currencies;

    try {
      currencies = await _placesService.getCurrencies(
        languageCode: languageCode,
      );
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripInformationUpdateError);
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<TripCurrency>(
      context: context,
      backgroundColor: _surfaceColor,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: trip.currency,
          title: l10n.createTripCurrency,
          searchHint: l10n.createTripCurrencySearchHint,
          noResultsText: l10n.createTripCurrencyNoResults,
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    await _saveTripInformation(trip: trip, currency: selected.label);
  }

  Future<void> _saveTripInformation({
    required Trip trip,
    String? name,
    TripDestination? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    String? description,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final destinationData = destination == null ? trip.destinationData : null;

    if (destination == null && destinationData == null) {
      _showMessage(l10n.tripInformationUpdateError);
      return;
    }

    try {
      await ref
          .read(tripRepositoryProvider)
          .updateTripInformation(
            tripId: trip.id,
            name: name ?? trip.name,
            destination: destination?.label ?? trip.destination,
            destinationPlaceId:
                destination?.placeId ?? destinationData!.placeId,
            destinationDisplayName:
                destination?.displayName ?? destinationData!.displayName,
            destinationFormattedAddress:
                destination?.formattedAddress ??
                destinationData!.formattedAddress,
            destinationLatitude:
                destination?.latitude ?? destinationData!.latitude,
            destinationLongitude:
                destination?.longitude ?? destinationData!.longitude,
            destinationCountry:
                destination?.country ?? destinationData?.country,
            destinationCountryCode:
                destination?.countryCode ?? destinationData?.countryCode,
            destinationAdministrativeArea:
                destination?.administrativeArea ??
                destinationData?.administrativeArea,
            destinationLocality:
                destination?.locality ?? destinationData?.locality,
            startDate: startDate ?? trip.startDate,
            endDate: endDate ?? trip.endDate,
            currency: currency ?? trip.currency,
            description: description ?? trip.description,
          );

      if (!mounted) {
        return;
      }

      _showMessage(l10n.tripInformationUpdated);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(l10n.tripInformationUpdateError);
    }
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
          // La nuova cover ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ giÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  salvata correttamente.
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
        // Il riferimento Firestore ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ giÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  stato rimosso.
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

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: _TripInformationSettingsPageState._secondaryTextColor,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _TripInformationSettingsPageState
                              ._secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines:
                            label ==
                                AppLocalizations.of(
                                  context,
                                )!.tripInformationDescription
                            ? 3
                            : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _TripInformationSettingsPageState._titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _TripInformationSettingsPageState._secondaryTextColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 54),
            child: Divider(height: 1, color: Color(0xFF3A2A24)),
          ),
      ],
    );
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

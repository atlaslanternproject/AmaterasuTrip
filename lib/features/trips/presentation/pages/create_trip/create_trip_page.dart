import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/cloud_archive/trip_cloud_archive_page.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/core/permissions/app_permission.dart';
import 'package:amaterasutrip/core/permissions/permission_provider.dart';
import 'package:amaterasutrip/core/permissions/permission_request_handler.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_cloud_archive_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'destination/models/trip_destination.dart';
import 'destination/services/destination_places_service.dart';
import 'destination/trip_destination_page.dart';
import 'trip_created_page.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive_selection.dart';
import 'package:amaterasutrip/features/trips/presentation/widgets/trip_cover_source_sheet.dart';
import 'currency/trip_currency_picker_sheet.dart';
import 'widgets/create_trip_button.dart';
import 'widgets/trip_cloud_selector.dart';
import 'widgets/trip_cover_picker.dart';
import 'widgets/trip_currency_selector.dart';
import 'widgets/trip_date_selector.dart';
import 'widgets/trip_destination_field.dart';
import 'widgets/trip_name_field.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _surfaceColor = Color(0xFF1A1715);

  final TextEditingController _nameController = TextEditingController();
  final DestinationPlacesService _placesService =
      const DestinationPlacesService();

  TripDestination? _selectedDestination;

  DateTime? _departureDate;
  DateTime? _returnDate;
  String? _currency;
  String? _currencySymbol;
  TripCloudArchiveSelection? _cloudArchiveSelection;

  bool get _canConfigureCloudArchive {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasDestination = _selectedDestination != null;
    final hasStartDate = _departureDate != null;
    final hasEndDate = _returnDate != null;

    return hasName && hasDestination && hasStartDate && hasEndDate;
  }

  XFile? _selectedCover;
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onFormChanged)
      ..dispose();

    super.dispose();
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _canCreateTrip {
    return _nameController.text.trim().isNotEmpty &&
        _selectedDestination != null &&
        _departureDate != null &&
        _returnDate != null &&
        _currency != null;
  }

  Future<void> _selectDepartureDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _departureDate = selectedDate;

      if (_returnDate != null && _returnDate!.isBefore(selectedDate)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _selectReturnDate() async {
    final now = DateTime.now();
    final firstDate = _departureDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _returnDate = selectedDate;
    });
  }

  Future<void> _selectDestination() async {
    final selectedDestination = await Navigator.of(context)
        .push<TripDestination>(
          MaterialPageRoute(
            builder: (context) => TripDestinationPage(
              initialDestination: _selectedDestination?.label,
            ),
          ),
        );

    if (!mounted || selectedDestination == null) {
      return;
    }

    setState(() {
      _selectedDestination = selectedDestination;

      final suggestedCurrency = selectedDestination.suggestedCurrencyLabel;

      if (suggestedCurrency != null) {
        _currency = suggestedCurrency;
        _currencySymbol = selectedDestination.suggestedCurrencySymbol;
      }
    });
  }

  Future<void> _selectCurrency() async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    List<TripCurrency> currencies;

    try {
      currencies = await _placesService.getCurrencies(
        languageCode: languageCode,
      );
    } catch (_) {
      return;
    }

    if (!mounted || currencies.isEmpty) {
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
          selectedCurrency: _currency,
          title: l10n.createTripCurrency,
          searchHint: l10n.createTripCurrencySearchHint,
          noResultsText: l10n.createTripCurrencyNoResults,
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _currency = selected.label;
      _currencySymbol = selected.symbol;
    });
  }

  Future<void> _selectCloudProvider() async {
    if (!_canConfigureCloudArchive) {
      final l10n = AppLocalizations.of(context)!;
      final missingFields = <String>[];

      if (_nameController.text.trim().isEmpty) {
        missingFields.add(l10n.createTripName);
      }

      if (_selectedDestination == null) {
        missingFields.add(l10n.createTripDestination);
      }

      if (_departureDate == null) {
        missingFields.add(l10n.createTripDepartureDate);
      }

      if (_returnDate == null) {
        missingFields.add(l10n.createTripReturnDate);
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Color(0xFFD96C32).withValues(alpha: 0.45),
              ),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD96C32),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.createTripStorageRequirementsTitle,
                    style: const TextStyle(
                      color: _titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createTripStorageRequirementsMessage,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ...missingFields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            color: Color(0xFFD96C32),
                            size: 7,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            field,
                            style: const TextStyle(
                              color: _titleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFFD96C32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      return;
    }
    final selection = await Navigator.of(context)
        .push<TripCloudArchiveSelection>(
          MaterialPageRoute<TripCloudArchiveSelection>(
            builder: (context) => const TripCloudArchivePage(),
          ),
        );

    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _cloudArchiveSelection = selection;
    });
  }

  Future<void> _changeCover() async {
    final action = await showTripCoverSourceSheet(
      context: context,
      hasCover: _selectedCover != null,
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case TripCoverSourceAction.camera:
        await _pickCover(fromCamera: true);
        break;

      case TripCoverSourceAction.gallery:
        await _pickCover(fromCamera: false);
        break;

      case TripCoverSourceAction.remove:
        setState(() {
          _selectedCover = null;
        });
        break;
    }
  }

  Future<void> _pickCover({required bool fromCamera}) async {
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

      setState(() {
        _selectedCover = selectedCover;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripCoverPickerError);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createTrip() async {
    if (!_canCreateTrip) {
      return;
    }

    final destination = _selectedDestination;

    if (destination == null) {
      return;
    }

    final tripName = _nameController.text.trim();
    final departureDate = _departureDate!;
    final returnDate = _returnDate!;
    final cloudSelection = _cloudArchiveSelection;

    TripCloudArchive? cloudArchive;

    if (cloudSelection != null) {
      try {
        switch (cloudSelection.provider) {
          case TripCloudProvider.googleDrive:
            final namingService = ref.read(tripArchiveNamingServiceProvider);
            final driveService = ref.read(googleDriveArchiveServiceProvider);

            final destinationName =
                destination.country?.trim().isNotEmpty == true
                ? destination.country!.trim()
                : destination.displayName.trim();

            final folderName = namingService.buildTripFolderName(
              tripName: tripName,
              destination: destinationName,
              startDate: departureDate,
              endDate: returnDate,
            );

            cloudArchive = await driveService.createTripArchive(
              tripName: folderName,
              parentFolderId: cloudSelection.parentFolderId,
            );
            break;

          case TripCloudProvider.oneDrive:
          case TripCloudProvider.dropbox:
            return;
        }
      } catch (_) {
        if (mounted) {
          _showMessage(AppLocalizations.of(context)!.tripCloudGoogleDriveError);
        }
        return;
      }
    }

    String tripId;

    try {
      tripId = await ref
          .read(tripRepositoryProvider)
          .createTrip(
            name: tripName,
            destination: destination.label,
            destinationPlaceId: destination.placeId,
            destinationDisplayName: destination.displayName,
            destinationFormattedAddress: destination.formattedAddress,
            destinationLatitude: destination.latitude,
            destinationLongitude: destination.longitude,
            destinationCountry: destination.country,
            destinationCountryCode: destination.countryCode,
            destinationAdministrativeArea: destination.administrativeArea,
            destinationLocality: destination.locality,
            startDate: departureDate,
            endDate: returnDate,
            currency: _currency!,
            cloudArchive: cloudArchive,
          );
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.createTripCreationError);
      }
      return;
    }

    final selectedCover = _selectedCover;

    if (selectedCover != null) {
      String? uploadedStoragePath;

      try {
        final storage = ref.read(tripCoverStorageServiceProvider);
        final repository = ref.read(tripRepositoryProvider);

        final uploaded = await storage.uploadTripCover(
          tripId: tripId,
          cover: selectedCover,
        );

        uploadedStoragePath = uploaded.storagePath;

        await repository.updateTripCover(
          tripId: tripId,
          coverUrl: uploaded.downloadUrl,
          coverPath: uploaded.storagePath,
        );
      } catch (_) {
        if (uploadedStoragePath != null) {
          try {
            await ref
                .read(tripCoverStorageServiceProvider)
                .deleteTripCover(uploadedStoragePath);
          } catch (_) {
            // Non maschera l'errore principale.
          }
        }

        if (mounted) {
          _showMessage(AppLocalizations.of(context)!.tripCoverUploadError);
        }
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TripCreatedPage(
          tripName: tripName,
          onInviteTravellers: () async {
            try {
              final invite = await ref
                  .read(tripInviteRepositoryProvider)
                  .createTripInvite(tripId: tripId);

              debugPrint('Trip invite created.');
              debugPrint('Trip ID: ${invite.tripId}');
              debugPrint('Invite ID: ${invite.inviteId}');

              if (!context.mounted) {
                return;
              }

              context.push(
                '/trip-invite/${invite.tripId}?token=${Uri.encodeQueryComponent(invite.token)}',
              );
            } catch (error, stackTrace) {
              debugPrint('Trip invite creation failed: $error');
              debugPrintStack(stackTrace: stackTrace);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Errore creazione invito: $error')),
                );
            }
          },
          onCopyLink: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.tripCreatedLinkCopied,
                ),
              ),
            );
          },
          onShare: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.tripCreatedShareComingSoon,
                ),
              ),
            );
          },
          onEnterTrip: () {
            context.go('/trips/$tripId');
          },
        ),
      ),
    );

    debugPrint('Trip created: $tripId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.createTripTitle,
          style: const TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripCoverPicker(
                changePhotoLabel: l10n.createTripChangePhoto,
                localImagePath: _selectedCover?.path,
                onTap: _changeCover,
              ),
              const SizedBox(height: 20),
              TripNameField(
                controller: _nameController,
                label: l10n.createTripName,
                hint: l10n.createTripNameHint,
              ),
              const SizedBox(height: 12),
              TripDestinationField(
                label: l10n.createTripDestination,
                hint: l10n.createTripDestinationHint,
                destination: _selectedDestination?.label,
                onTap: _selectDestination,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 9),
                child: Text(
                  l10n.createTripDates,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TripDateSelector(
                departureLabel: l10n.createTripDepartureDate,
                returnLabel: l10n.createTripReturnDate,
                departureDate: _departureDate,
                returnDate: _returnDate,
                onDepartureTap: _selectDepartureDate,
                onReturnTap: _selectReturnDate,
              ),
              const SizedBox(height: 20),
              TripCurrencySelector(
                label: l10n.createTripCurrency,
                hint: l10n.createTripCurrencyHint,
                currency: _currency,
                symbol: _currencySymbol,
                onTap: _selectCurrency,
              ),
              const SizedBox(height: 24),
              TripCloudSelector(
                sectionLabel: l10n.createTripStorageSection,
                title: l10n.createTripStorage,
                subtitle: l10n.createTripStorageSubtitle,
                configuredLabel: l10n.createTripStorageConfigured,
                selectedProvider: switch (_cloudArchiveSelection?.provider) {
                  TripCloudProvider.googleDrive => l10n.tripCloudGoogleDrive,
                  TripCloudProvider.oneDrive => l10n.tripCloudOneDrive,
                  TripCloudProvider.dropbox => l10n.tripCloudDropbox,
                  null => null,
                },
                onTap: _selectCloudProvider,
              ),
              const SizedBox(height: 28),
              CreateTripButton(
                label: l10n.createTripCreate,
                isEnabled: _canCreateTrip,
                onPressed: _createTrip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

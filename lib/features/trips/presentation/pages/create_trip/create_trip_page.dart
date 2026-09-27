import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/core/permissions/app_permission.dart';
import 'package:amaterasutrip/core/permissions/permission_provider.dart';
import 'package:amaterasutrip/core/permissions/permission_result.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'destination/models/trip_destination.dart';
import 'destination/services/destination_places_service.dart';
import 'destination/trip_destination_page.dart';
import 'trip_created_page.dart';
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
  String? _cloudProvider;

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
        return _CurrencyPickerSheet(
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

  void _selectCloudProvider() {
    setState(() {
      _cloudProvider = 'Google Drive';
    });
  }

  Future<void> _changeCover() async {
    final l10n = AppLocalizations.of(context)!;

    final action = await showModalBottomSheet<_CreateTripCoverAction>(
      context: context,
      backgroundColor: _surfaceColor,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFE86A3A),
                  ),
                  title: Text(
                    l10n.tripCoverCamera,
                    style: const TextStyle(color: _titleColor),
                  ),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_CreateTripCoverAction.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFE86A3A),
                  ),
                  title: Text(
                    l10n.tripCoverGallery,
                    style: const TextStyle(color: _titleColor),
                  ),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_CreateTripCoverAction.gallery),
                ),
                if (_selectedCover != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFD66A5E),
                    ),
                    title: Text(
                      l10n.tripCoverRemove,
                      style: const TextStyle(color: Color(0xFFD66A5E)),
                    ),
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_CreateTripCoverAction.remove),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _CreateTripCoverAction.camera:
        await _pickCover(fromCamera: true);
        break;

      case _CreateTripCoverAction.gallery:
        await _pickCover(fromCamera: false);
        break;

      case _CreateTripCoverAction.remove:
        setState(() {
          _selectedCover = null;
        });
        break;
    }
  }

  Future<void> _pickCover({required bool fromCamera}) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = ref.read(permissionServiceProvider);

    final permissionResult = await permissionService.request(
      fromCamera ? AppPermission.camera : AppPermission.photos,
    );

    if (!mounted) {
      return;
    }

    switch (permissionResult) {
      case AppPermissionResult.granted:
        break;

      case AppPermissionResult.denied:
        _showMessage(
          fromCamera
              ? l10n.tripCoverCameraPermissionDenied
              : l10n.tripCoverGalleryPermissionDenied,
        );
        return;

      case AppPermissionResult.permanentlyDenied:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                fromCamera
                    ? l10n.tripCoverCameraPermissionPermanentlyDenied
                    : l10n.tripCoverGalleryPermissionPermanentlyDenied,
              ),
              action: SnackBarAction(
                label: l10n.tripCoverOpenSettings,
                onPressed: permissionService.openSettings,
              ),
            ),
          );
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

    final tripId = await ref
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
          startDate: _departureDate!,
          endDate: _returnDate!,
          currency: _currency!,
        );

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
          onInviteTravellers: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.tripCreatedInviteComingSoon,
                ),
              ),
            );
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
                selectedProvider: _cloudProvider,
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

enum _CreateTripCoverAction { camera, gallery, remove }

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selectedCurrency,
    required this.title,
    required this.searchHint,
    required this.noResultsText,
  });

  final List<TripCurrency> currencies;
  final String? selectedCurrency;
  final String title;
  final String searchHint;
  final String noResultsText;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  static const Color _fieldColor = Color(0xFF241B17);
  static const Color _borderColor = Color(0xFF3A2A24);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);

  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TripCurrency> get _filteredCurrencies {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.currencies;
    }

    return widget.currencies.where((currency) {
      return currency.code.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query) ||
          currency.symbol.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _filteredCurrencies;

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: _secondaryTextColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: _titleColor, fontSize: 15),
              cursorColor: _accentColor,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  color: _secondaryTextColor.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _secondaryTextColor,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _secondaryTextColor,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _fieldColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accentColor, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: currencies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.noResultsText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: currencies.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: _secondaryTextColor.withValues(alpha: 0.12),
                    ),
                    itemBuilder: (context, index) {
                      final currency = currencies[index];

                      final isSelected =
                          widget.selectedCurrency?.startsWith(currency.code) ??
                          false;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(currency),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentColor.withValues(alpha: 0.12)
                                : _fieldColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? _accentColor.withValues(alpha: 0.55)
                                  : _borderColor,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                currency.symbol,
                                style: const TextStyle(
                                  color: _accentColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          currency.code,
                          style: const TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          currency.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _secondaryTextColor),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _accentColor,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: _secondaryTextColor,
                                size: 20,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

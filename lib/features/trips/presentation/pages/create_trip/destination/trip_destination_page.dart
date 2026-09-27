import 'dart:async';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/trip_destination.dart';
import 'services/destination_places_service.dart';
import 'widgets/destination_result_card.dart';
import 'widgets/destination_search_field.dart';
import 'widgets/destination_world_map.dart';

class TripDestinationPage extends StatefulWidget {
  const TripDestinationPage({super.key, this.initialDestination});

  final String? initialDestination;

  @override
  State<TripDestinationPage> createState() => _TripDestinationPageState();
}

class _TripDestinationPageState extends State<TripDestinationPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);
  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF3A2A24);
  static const Color _disabledColor = Color(0xFF3A302B);

  final TextEditingController _searchController = TextEditingController();

  final DestinationPlacesService _placesService =
      const DestinationPlacesService();

  Timer? _debounce;

  List<DestinationPrediction> _predictions = const [];

  TripDestination? _selectedDestination;

  bool _searching = false;
  bool _loadingDetails = false;
  bool _resolvingMapTap = false;

  bool _hasError = false;
  bool _noPlaceAtMapPoint = false;

  String get _languageCode => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();

    final initialDestination = widget.initialDestination?.trim();

    if (initialDestination != null && initialDestination.isNotEmpty) {
      _searchController.text = initialDestination;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _predictions = const [];
        _searching = false;
        _hasError = false;
        _noPlaceAtMapPoint = false;
      });

      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _hasError = false;
      _noPlaceAtMapPoint = false;
    });

    try {
      final results = await _placesService.search(
        query,
        languageCode: _languageCode,
      );

      if (!mounted || query != _searchController.text.trim()) {
        return;
      }

      setState(() {
        _predictions = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _predictions = const [];
        _searching = false;
        _hasError = true;
      });
    }
  }

  Future<void> _selectPrediction(DestinationPrediction prediction) async {
    setState(() {
      _loadingDetails = true;
      _hasError = false;
      _noPlaceAtMapPoint = false;
    });

    try {
      final destination = await _placesService.getDetails(
        prediction.placeId,
        languageCode: _languageCode,
      );

      if (!mounted) {
        return;
      }

      _applyDestination(destination);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDetails = false;
        _hasError = true;
      });
    }
  }

  Future<void> _selectMapPoint(LatLng point) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _resolvingMapTap = true;
      _predictions = const [];
      _hasError = false;
      _noPlaceAtMapPoint = false;
    });

    try {
      final destination = await _placesService.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
        languageCode: _languageCode,
      );

      if (!mounted) {
        return;
      }

      _applyDestination(destination);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvingMapTap = false;

        if (error.code == 'NO_DESTINATION_AT_POINT') {
          _noPlaceAtMapPoint = true;
        } else {
          _hasError = true;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvingMapTap = false;
        _hasError = true;
      });
    }
  }

  void _applyDestination(TripDestination destination) {
    setState(() {
      _selectedDestination = destination;
      _loadingDetails = false;
      _resolvingMapTap = false;
      _predictions = const [];
      _hasError = false;
      _noPlaceAtMapPoint = false;

      _searchController.text = destination.displayName;

      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });

    FocusScope.of(context).unfocus();
  }

  void _confirmDestination() {
    final destination = _selectedDestination;

    if (destination == null) {
      return;
    }

    Navigator.of(context).pop(destination);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination = _selectedDestination;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _creamColor),
        ),
        title: Text(
          l10n.destinationPickerTitle,
          style: const TextStyle(
            color: _creamColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  DestinationSearchField(
                    controller: _searchController,
                    hint: l10n.destinationPickerSearchHint,
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 18),

                  DestinationWorldMap(
                    label: l10n.destinationPickerMapLabel,
                    latitude: destination?.latitude,
                    longitude: destination?.longitude,
                    isResolvingLocation: _resolvingMapTap,
                    onMapTap: _selectMapPoint,
                  ),

                  const SizedBox(height: 18),

                  if (_searching || _loadingDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(color: _accentColor),
                      ),
                    ),

                  if (_hasError || _noPlaceAtMapPoint)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _noPlaceAtMapPoint
                                  ? l10n.destinationMapNoPlace
                                  : l10n.destinationGenericError,
                              style: const TextStyle(
                                color: _secondaryTextColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_searching &&
                      !_loadingDetails &&
                      !_resolvingMapTap &&
                      !_hasError &&
                      !_noPlaceAtMapPoint &&
                      _searchController.text.trim().length >= 2 &&
                      _predictions.isEmpty &&
                      destination == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        l10n.destinationPickerNoResults,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _secondaryTextColor),
                      ),
                    ),

                  if (_predictions.isNotEmpty)
                    ..._predictions.map(
                      (prediction) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DestinationResultCard(
                          flag: '',
                          title: prediction.primaryText,
                          subtitle: prediction.secondaryText,
                          isSelected: false,
                          onTap: () => _selectPrediction(prediction),
                        ),
                      ),
                    ),

                  if (destination != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.08),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accentColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: destination.flagEmoji.isNotEmpty
                                ? Text(
                                    destination.flagEmoji,
                                    style: const TextStyle(fontSize: 25),
                                  )
                                : const Icon(
                                    Icons.location_on_rounded,
                                    color: _accentColor,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destination.displayName,
                                  style: const TextStyle(
                                    color: _creamColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (destination
                                    .formattedAddress
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    destination.formattedAddress,
                                    style: const TextStyle(
                                      color: _secondaryTextColor,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                if (destination.country != null &&
                                    destination.country!.isNotEmpty) ...[
                                  const SizedBox(height: 7),
                                  Text(
                                    destination.country!,
                                    style: const TextStyle(
                                      color: _accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _accentColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: _backgroundColor,
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: destination == null ? null : _confirmDestination,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    disabledBackgroundColor: _disabledColor,
                    foregroundColor: _creamColor,
                    disabledForegroundColor: _secondaryTextColor.withValues(
                      alpha: 0.45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.destinationPickerConfirm,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

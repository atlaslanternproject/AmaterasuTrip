// Mappa del mondo per la destinazione, con gesti a due dita e bottoni.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaterasutrip/core/maps/amaterasu_map_style.dart';
import 'package:amaterasutrip/core/maps/amaterasu_two_finger_gesture.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class DestinationWorldMap extends StatefulWidget {
  const DestinationWorldMap({
    super.key,
    required this.label,
    required this.onMapTap,
    this.latitude,
    this.longitude,
    this.isResolvingLocation = false,
  });

  final String label;
  final double? latitude;
  final double? longitude;
  final ValueChanged<LatLng> onMapTap;
  final bool isResolvingLocation;

  @override
  State<DestinationWorldMap> createState() => _DestinationWorldMapState();
}

class _DestinationWorldMapState extends State<DestinationWorldMap> {
  static const Color _accentColor = AmaterasuColors.accentFlame;
  static const Color _creamColor = AmaterasuColors.textPrimary;

  static const CameraPosition _worldCamera = CameraPosition(
    target: LatLng(20, 0),
    zoom: 1.35,
  );

  GoogleMapController? _controller;

  bool _navigationEnabled = false;

  static const String _darkMapStyle = amaterasuDarkMapStyle;

  bool get _hasDestination =>
      widget.latitude != null && widget.longitude != null;

  LatLng get _destination =>
      LatLng(widget.latitude ?? 20, widget.longitude ?? 0);

  @override
  void didUpdateWidget(covariant DestinationWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _moveToDestination();
    }
  }

  Future<void> _moveToDestination() async {
    final controller = _controller;

    if (controller == null || !_hasDestination) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _destination, zoom: 9.5),
      ),
    );
  }

  void _enableNavigation() {
    if (_navigationEnabled) {
      return;
    }

    setState(() {
      _navigationEnabled = true;
    });
  }

  void _handleMapTap(LatLng position) {
    if (!_navigationEnabled) {
      _enableNavigation();
      return;
    }

    if (!widget.isResolvingLocation) {
      widget.onMapTap(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final markers = <Marker>{};

    if (_hasDestination) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_destination'),
          position: _destination,
          infoWindow: InfoWindow(title: widget.label),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _navigationEnabled
              ? _accentColor.withValues(alpha: 0.85)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: _navigationEnabled
            ? [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.13),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 310,
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: _hasDestination
                      ? CameraPosition(target: _destination, zoom: 9.5)
                      : _worldCamera,
                  markers: markers,
                  mapType: MapType.normal,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,

                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<AmaterasuTwoFingerMapGestureRecognizer>(
                      AmaterasuTwoFingerMapGestureRecognizer.new,
                    ),
                  },

                  rotateGesturesEnabled: _navigationEnabled,
                  scrollGesturesEnabled: _navigationEnabled,
                  zoomGesturesEnabled: _navigationEnabled,
                  tiltGesturesEnabled: _navigationEnabled,

                  style: _darkMapStyle,
                  onTap: _handleMapTap,

                  onMapCreated: (controller) {
                    _controller = controller;
                    _moveToDestination();
                  },
                ),
              ),

              Positioned(
                left: 14,
                top: 14,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDD100C0A),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _navigationEnabled
                            ? _accentColor.withValues(alpha: 0.85)
                            : _accentColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isResolvingLocation) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: AmaterasuLoader(),
                          ),
                          const SizedBox(width: AmaterasuSpacing.sm),
                        ] else if (_navigationEnabled) ...[
                          const Icon(
                            Icons.pan_tool_alt_rounded,
                            size: 13,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 7),
                        ],
                        Text(
                          widget.isResolvingLocation
                              ? l10n.destinationMapResolving
                              : widget.label,
                          style: const TextStyle(
                            color: _creamColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!_navigationEnabled)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AmaterasuColors.surfaceDeepOverlay,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              color: _accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              l10n.destinationMapTapToExplore,
                              style: const TextStyle(
                                color: _creamColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_navigationEnabled)
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AmaterasuColors.surfaceDeepOverlay,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pinch_rounded,
                            color: _accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.destinationMapTwoFingers,
                            style: const TextStyle(
                              color: _creamColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        _enableNavigation();
                        _controller?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                    const SizedBox(height: AmaterasuSpacing.sm),
                    _MapButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        _enableNavigation();
                        _controller?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                    if (_hasDestination) ...[
                      const SizedBox(height: AmaterasuSpacing.sm),
                      _MapButton(
                        icon: Icons.location_searching_rounded,
                        onTap: () {
                          _enableNavigation();
                          _moveToDestination();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AmaterasuColors.surfaceDeepOverlay,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AmaterasuColors.textPrimary, size: 21),
        ),
      ),
    );
  }
}

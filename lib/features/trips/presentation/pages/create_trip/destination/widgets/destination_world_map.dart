import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  static const Color _accentColor = Color(0xFFE86A3A);
  static const Color _creamColor = Color(0xFFF2E7D5);

  static const CameraPosition _worldCamera = CameraPosition(
    target: LatLng(20, 0),
    zoom: 1.35,
  );

  GoogleMapController? _controller;

  bool _navigationEnabled = false;

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#17120f"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#b7a99b"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#100c0a"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#4a3329"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#6b4536"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#18120f"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#211713"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9c7c68"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#33231d"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#241915"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#5a3427"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#7d4430"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2a1d18"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#090b0d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#66584f"}]
  }
]
''';

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
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
                    Factory<_TwoFingerMapGestureRecognizer>(
                      _TwoFingerMapGestureRecognizer.new,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          color: const Color(0xE6100C0A),
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
                        color: const Color(0xE6100C0A),
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
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        _enableNavigation();
                        _controller?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                    if (_hasDestination) ...[
                      const SizedBox(height: 8),
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

class _TwoFingerMapGestureRecognizer extends OneSequenceGestureRecognizer {
  final Set<int> _pointers = <int>{};
  final Set<int> _trackedPointers = <int>{};

  bool _accepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);

    _pointers.add(event.pointer);
    _trackedPointers.add(event.pointer);

    if (_pointers.length >= 2 && !_accepted) {
      _accepted = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);

      if (_trackedPointers.remove(event.pointer)) {
        stopTrackingPointer(event.pointer);
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_accepted) {
      resolve(GestureDisposition.rejected);
    }

    _pointers.clear();
    _trackedPointers.clear();
    _accepted = false;
  }

  @override
  String get debugDescription => 'twoFingerMapGesture';
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6100C0A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFFF2E7D5), size: 21),
        ),
      ),
    );
  }
}

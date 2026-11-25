// Mappa Google di Mappa e Itinerario (google_maps_flutter già nel progetto,
// stessa chiave, stile scuro comune): pin raggruppati a griglia secondo lo
// zoom, tocco su un gruppo = più vicino, tocco su un pin = riquadro; linea
// tratteggiata tra le voci di ogni giorno, solo estetica.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:amaterasutrip/core/maps/amaterasu_map_style.dart';
import 'package:amaterasutrip/core/maps/amaterasu_two_finger_gesture.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_tile.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_markers.dart';
import 'trip_map_point.dart';

typedef TripMapCanvasBuilder =
    Widget Function(
      List<TripItineraryItem> points,
      List<List<TripItineraryItem>> routes,
      ValueChanged<TripItineraryItem> onSelect,
    );

/// The real Google map; tests replace it (maps do not draw in tests).
final tripMapCanvasProvider = Provider<TripMapCanvasBuilder>(
  (ref) =>
      (points, routes, onSelect) => GoogleTripMapCanvas(
        points: points,
        routes: routes,
        onSelect: onSelect,
      ),
);

class GoogleTripMapCanvas extends StatefulWidget {
  const GoogleTripMapCanvas({
    super.key,
    required this.points,
    required this.routes,
    required this.onSelect,
  });

  final List<TripItineraryItem> points;
  final List<List<TripItineraryItem>> routes;
  final ValueChanged<TripItineraryItem> onSelect;

  @override
  State<GoogleTripMapCanvas> createState() => _GoogleTripMapCanvasState();
}

class _GoogleTripMapCanvasState extends State<GoogleTripMapCanvas> {
  GoogleMapController? _controller;
  double _zoom = 12;
  CameraPosition _camera = const CameraPosition(target: LatLng(0, 0));
  Set<Marker> _markers = {};

  LatLng _at(TripItineraryItem i) =>
      LatLng(i.place!.latitude!, i.place!.longitude!);

  @override
  void didUpdateWidget(GoogleTripMapCanvas old) {
    super.didUpdateWidget(old);
    _rebuild();
    // New filter or day: frame the visible pins again.
    final before = old.points.map((i) => i.id).join(',');
    if (before != widget.points.map((i) => i.id).join(',')) _fit();
  }

  Future<void> _rebuild() async {
    final markers = <Marker>{};
    for (final c in tripMapClusters(widget.points, _zoom)) {
      final first = c.items.first;
      markers.add(
        Marker(
          markerId: MarkerId(c.items.map((i) => i.id).join('+')),
          position: c.single ? _at(first) : LatLng(c.latitude, c.longitude),
          icon: c.single
              ? await TripMapMarkers.icon(tripItineraryIcon(first))
              : await TripMapMarkers.count(c.items.length),
          onTap: () => c.single || _zoom >= 18
              ? widget.onSelect(first)
              : _controller?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(c.latitude, c.longitude),
                    c.zoomIn(_zoom),
                  ),
                ),
        ),
      );
    }
    if (mounted) setState(() => _markers = markers);
  }

  /// Frames every visible pin with some margin (one pin: close up).
  void _fit() {
    final c = _controller;
    if (c == null || widget.points.isEmpty) return;
    final lats = widget.points.map((i) => i.place!.latitude!);
    final lngs = widget.points.map((i) => i.place!.longitude!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.points.length == 1) {
        c.animateCamera(
          CameraUpdate.newLatLngZoom(_at(widget.points.first), 15),
        );
        return;
      }
      c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
            northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
          ),
          60,
        ),
      );
    });
  }

  /// Back to north, same place and zoom.
  void _north() => _controller?.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(target: _camera.target, zoom: _camera.zoom),
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: _map()),
      Positioned(
        right: 8,
        top: 8,
        child: IconButton.filledTonal(
          key: const Key('map-north'),
          tooltip: AppLocalizations.of(context)!.mapNorth,
          onPressed: _north,
          icon: const Icon(Icons.explore_outlined),
        ),
      ),
    ],
  );

  Widget _map() => GoogleMap(
    initialCameraPosition: CameraPosition(
      target: widget.points.isEmpty
          ? const LatLng(0, 0)
          : _at(widget.points.first),
      zoom: _zoom,
    ),
    style: amaterasuDarkMapStyle,
    markers: _markers,
    polylines: {
      for (final (n, route) in widget.routes.indexed)
        Polyline(
          polylineId: PolylineId('day-$n'),
          points: [for (final i in route) _at(i)],
          color: AmaterasuColors.accentGold,
          width: 3,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
        ),
    },
    mapToolbarEnabled: false,
    zoomControlsEnabled: true,
    myLocationButtonEnabled: false,
    // Same gestures as the destination map: two fingers move, zoom and
    // rotate (also tilt).
    gestureRecognizers: {
      Factory<AmaterasuTwoFingerMapGestureRecognizer>(
        AmaterasuTwoFingerMapGestureRecognizer.new,
      ),
    },
    rotateGesturesEnabled: true,
    scrollGesturesEnabled: true,
    zoomGesturesEnabled: true,
    tiltGesturesEnabled: true,
    compassEnabled: true,
    onMapCreated: (c) {
      _controller = c;
      _fit();
      _rebuild();
    },
    onCameraMove: (p) {
      _zoom = p.zoom;
      _camera = p;
    },
    onCameraIdle: _rebuild,
  );
}

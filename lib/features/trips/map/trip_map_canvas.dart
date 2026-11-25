// Mappa Google di Mappa e Itinerario (google_maps_flutter già nel progetto,
// stessa chiave, stile scuro comune): pin raggruppati a griglia secondo lo
// zoom, tocco su un gruppo = più vicino, tocco su un pin = riquadro; linea
// tratteggiata tra le voci di ogni giorno, solo estetica.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:amaterasutrip/core/maps/amaterasu_map_style.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_tile.dart';
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
  Set<Marker> _markers = {};

  LatLng _at(TripItineraryItem i) =>
      LatLng(i.place!.latitude!, i.place!.longitude!);

  @override
  void didUpdateWidget(GoogleTripMapCanvas old) {
    super.didUpdateWidget(old);
    _rebuild();
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

  void _fit() {
    if (widget.points.isEmpty) return;
    final lats = widget.points.map((i) => i.place!.latitude!);
    final lngs = widget.points.map((i) => i.place!.longitude!);
    _controller?.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          ),
        ),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GoogleMap(
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
    onMapCreated: (c) {
      _controller = c;
      _fit();
      _rebuild();
    },
    onCameraMove: (p) => _zoom = p.zoom,
    onCameraIdle: _rebuild,
  );
}

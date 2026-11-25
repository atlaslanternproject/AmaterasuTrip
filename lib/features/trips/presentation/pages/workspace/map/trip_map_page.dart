// Pagina Mappa del viaggio: bozza funzionante con dati di esempio in
// memoria (TripMapScreen); nulla si salva su Firestore.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/map/trip_map_screen.dart';

class TripMapPage extends StatelessWidget {
  const TripMapPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => TripMapScreen(tripId: tripId);
}

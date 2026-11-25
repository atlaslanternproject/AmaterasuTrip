// Pagina Itinerario del viaggio: bozza funzionante con dati di esempio in
// memoria (TripItineraryScreen); nulla si salva su Firestore.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_screen.dart';

class TripItineraryPage extends StatelessWidget {
  const TripItineraryPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => TripItineraryScreen(tripId: tripId);
}

// Provider Riverpod dei luoghi salvati: archivio Firestore (modulo comune
// delle sezioni) ed elenco in tempo reale dei luoghi di un viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_saved_place.dart';
import '../models/trip_saved_place_codec.dart';

final tripSavedPlacesStoreProvider = Provider<TripSectionStore<TripSavedPlace>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripSavedPlaceCodec(),
  ),
);

final tripSavedPlacesProvider = StreamProvider.autoDispose
    .family<List<TripSavedPlace>, String>(
      (ref, tripId) => ref.watch(tripSavedPlacesStoreProvider).watch(tripId),
    );

// Provider Riverpod delle prenotazioni: archivio Firestore (modulo comune
// delle sezioni) ed elenco in tempo reale delle prenotazioni di un viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_reservation.dart';
import '../models/trip_reservation_codec.dart';

final tripReservationsStoreProvider =
    Provider<TripSectionStore<TripReservation>>(
      (ref) => FirestoreTripSectionStore(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
        const TripReservationCodec(),
      ),
    );

final tripReservationsProvider = StreamProvider.autoDispose
    .family<List<TripReservation>, String>(
      (ref, tripId) => ref.watch(tripReservationsStoreProvider).watch(tripId),
    );

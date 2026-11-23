// Provider Riverpod dei trasporti: archivio Firestore (modulo comune delle
// sezioni) ed elenco in tempo reale dei trasporti di un viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_transport.dart';
import '../models/trip_transport_codec.dart';

final tripTransportsStoreProvider = Provider<TripSectionStore<TripTransport>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripTransportCodec(),
  ),
);

final tripTransportsProvider = StreamProvider.autoDispose
    .family<List<TripTransport>, String>(
      (ref, tripId) => ref.watch(tripTransportsStoreProvider).watch(tripId),
    );

// Provider Riverpod dei ricordi: archivio Firestore (modulo comune delle
// sezioni) ed elenco in tempo reale del viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_memory.dart';
import '../models/trip_memory_codec.dart';

final tripMemoriesStoreProvider = Provider<TripSectionStore<TripMemory>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripMemoryCodec(),
  ),
);

final tripMemoriesProvider = StreamProvider.autoDispose
    .family<List<TripMemory>, String>(
      (ref, tripId) => ref.watch(tripMemoriesStoreProvider).watch(tripId),
    );

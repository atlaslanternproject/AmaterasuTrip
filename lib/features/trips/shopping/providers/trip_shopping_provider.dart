// Provider Riverpod dello shopping e della valigia: archivi Firestore
// (modulo comune delle sezioni) ed elenchi in tempo reale del viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_packing_item.dart';
import '../models/trip_shopping_codecs.dart';
import '../models/trip_shopping_item.dart';

final tripShoppingStoreProvider = Provider<TripSectionStore<TripShoppingItem>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripShoppingItemCodec(),
  ),
);

final tripPackingStoreProvider = Provider<TripSectionStore<TripPackingItem>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripPackingItemCodec(),
  ),
);

final tripShoppingProvider = StreamProvider.autoDispose
    .family<List<TripShoppingItem>, String>(
      (ref, tripId) => ref.watch(tripShoppingStoreProvider).watch(tripId),
    );

final tripPackingProvider = StreamProvider.autoDispose
    .family<List<TripPackingItem>, String>(
      (ref, tripId) => ref.watch(tripPackingStoreProvider).watch(tripId),
    );

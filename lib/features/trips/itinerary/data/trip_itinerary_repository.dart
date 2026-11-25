// Dati dell'Itinerario dietro un'interfaccia: la versione Firestore usa lo
// store comune delle sezioni (trips/{tripId}/itinerary, scritture firmate
// con updatedByUid, regole e test). Le schermate non sanno da dove vengono.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_codec.dart';

abstract interface class TripItineraryRepository {
  Stream<List<TripItineraryItem>> watch(String tripId);

  /// Adds (empty id) or replaces an item.
  Future<void> save(TripItineraryItem item);

  /// Allowed by the rules only to the author or the trip owner.
  Future<void> delete(TripItineraryItem item);

  /// New manual order of items without a time (decision 1).
  Future<void> reorder(List<TripItineraryItem> ordered);
}

class StoreTripItineraryRepository implements TripItineraryRepository {
  StoreTripItineraryRepository(this._store);

  final TripSectionStore<TripItineraryItem> _store;

  @override
  Stream<List<TripItineraryItem>> watch(String tripId) => _store.watch(tripId);

  @override
  Future<void> save(TripItineraryItem item) async {
    if (item.id.isEmpty) {
      await _store.create(item);
    } else {
      await _store.update(item);
    }
  }

  @override
  Future<void> delete(TripItineraryItem item) => _store.delete(item);

  @override
  Future<void> reorder(List<TripItineraryItem> ordered) async {
    for (final (n, item) in ordered.indexed) {
      if (item.order != n) await _store.update(item.copyWith(order: n));
    }
  }
}

final tripItineraryStoreProvider =
    Provider<TripSectionStore<TripItineraryItem>>(
      (ref) => FirestoreTripSectionStore(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
        const TripItineraryCodec(),
      ),
    );

final tripItineraryRepositoryProvider = Provider<TripItineraryRepository>(
  (ref) => StoreTripItineraryRepository(ref.watch(tripItineraryStoreProvider)),
);

final tripItineraryItemsProvider = StreamProvider.autoDispose
    .family<List<TripItineraryItem>, String>(
      (ref, tripId) => ref.watch(tripItineraryRepositoryProvider).watch(tripId),
    );

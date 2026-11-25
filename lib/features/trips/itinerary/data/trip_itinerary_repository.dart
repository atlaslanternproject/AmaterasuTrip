// Dati dell'Itinerario dietro un'interfaccia: la bozza usa la versione
// demo in memoria (trip_itinerary_demo.dart, non si salva); la versione
// vera su Firestore la sostituirà senza cambiare le schermate.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_demo.dart';

/// Trip facts the screens need besides the items.
class TripItineraryInfo {
  const TripItineraryInfo({
    required this.start,
    required this.end,
    required this.names,
    required this.catalog,
  });

  final DateTime start, end;

  /// Traveler uid -> username.
  final Map<String, String> names;

  /// Existing section elements with a position (map and "add from an
  /// existing element"), also those not in the itinerary.
  final List<TripItineraryItem> catalog;
}

abstract interface class TripItineraryRepository {
  /// True for the in-memory draft.
  bool get isDemo;

  TripItineraryInfo info(String tripId);

  Stream<List<TripItineraryItem>> watch(String tripId);

  /// Adds or replaces an item.
  Future<void> save(String tripId, TripItineraryItem item);

  Future<void> delete(String tripId, String itemId);

  /// New manual order of the items of one day.
  Future<void> reorder(String tripId, List<String> itemIds);
}

/// The draft: example data in memory, lost on reload.
final tripItineraryRepositoryProvider = Provider<TripItineraryRepository>(
  (ref) => DemoTripItineraryRepository(),
);

final tripItineraryItemsProvider = StreamProvider.autoDispose
    .family<List<TripItineraryItem>, String>(
      (ref, tripId) => ref.watch(tripItineraryRepositoryProvider).watch(tripId),
    );

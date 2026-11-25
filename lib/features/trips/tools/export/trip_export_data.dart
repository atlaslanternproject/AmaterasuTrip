// Dati di "Esporta" (tappa 3): alloggi, trasporti, prenotazioni,
// ristoranti e ricordi (album) letti una volta, solo quando si preme
// "Scarica" o "PDF", con gli stessi store delle sezioni (sola lettura).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';

class TripExportData {
  const TripExportData({
    this.stays = const [],
    this.transports = const [],
    this.reservations = const [],
    this.restaurants = const [],
    this.memories = const [],
  });

  final List<TripStay> stays;
  final List<TripTransport> transports;
  final List<TripReservation> reservations;
  final List<TripRestaurant> restaurants;
  final List<TripMemory> memories;
}

typedef TripExportLoader = Future<TripExportData> Function(String tripId);

final tripExportLoaderProvider = Provider<TripExportLoader>(
  (ref) => (tripId) async {
    final stays = ref.read(tripStaysRepositoryProvider).watch(tripId).first;
    final transports = ref
        .read(tripTransportsStoreProvider)
        .watch(tripId)
        .first;
    final reservations = ref
        .read(tripReservationsStoreProvider)
        .watch(tripId)
        .first;
    final restaurants = ref
        .read(tripRestaurantsStoreProvider)
        .watch(tripId)
        .first;
    final memories = ref.read(tripMemoriesStoreProvider).watch(tripId).first;
    return TripExportData(
      stays: await stays,
      transports: await transports,
      reservations: await reservations,
      restaurants: await restaurants,
      memories: await memories,
    );
  },
);

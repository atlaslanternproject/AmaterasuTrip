// Elementi del viaggio a cui collegare una nota (alloggi, trasporti,
// prenotazioni, ristoranti, luoghi salvati). Letti una volta sola, solo
// quando si apre "Collega a un elemento": nessun ascolto sempre attivo.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import '../models/trip_note.dart';

final tripNoteLinkTargetsProvider = FutureProvider.autoDispose
    .family<List<TripNoteLink>, String>((ref, tripId) async {
      Future<List<TripNoteLink>> section(
        String name,
        TripSectionStore<dynamic> store,
      ) async {
        final items = await store.watch(tripId).first;
        return [
          for (final item in items)
            TripNoteLink(section: name, id: item.id, name: item.displayName),
        ];
      }

      final stays = await ref
          .read(tripStaysRepositoryProvider)
          .watch(tripId)
          .first;
      final lists = await Future.wait([
        section('transports', ref.read(tripTransportsStoreProvider)),
        section('reservations', ref.read(tripReservationsStoreProvider)),
        section('restaurants', ref.read(tripRestaurantsStoreProvider)),
        section('savedPlaces', ref.read(tripSavedPlacesStoreProvider)),
      ]);
      return [
        for (final stay in stays)
          TripNoteLink(section: 'stays', id: stay.id, name: stay.name),
        for (final list in lists) ...list,
      ];
    });

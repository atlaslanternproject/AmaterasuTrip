// Provider Riverpod dei ristoranti: archivio Firestore (modulo comune delle
// sezioni), servizio dei voti ed elenco in tempo reale del viaggio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../data/trip_restaurant_vote_service.dart';
import '../models/trip_restaurant.dart';
import '../models/trip_restaurant_codec.dart';

final tripRestaurantsStoreProvider = Provider<TripSectionStore<TripRestaurant>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripRestaurantCodec(),
  ),
);

final tripRestaurantVotesProvider = Provider<TripRestaurantVoteService>(
  (ref) => FirestoreTripRestaurantVoteService(FirebaseFirestore.instance),
);

final tripRestaurantsProvider = StreamProvider.autoDispose
    .family<List<TripRestaurant>, String>(
      (ref, tripId) => ref.watch(tripRestaurantsStoreProvider).watch(tripId),
    );

// Provider Riverpod dei soggiorni: il repository e l'elenco in tempo reale
// dei soggiorni di un viaggio, ordinati per check-in.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_stays_repository.dart';
import '../models/trip_stay.dart';

final tripStaysRepositoryProvider = Provider<TripStaysRepository>((ref) {
  return TripStaysRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final tripStaysProvider = StreamProvider.autoDispose
    .family<List<TripStay>, String>((ref, tripId) {
      return ref.watch(tripStaysRepositoryProvider).watch(tripId);
    });

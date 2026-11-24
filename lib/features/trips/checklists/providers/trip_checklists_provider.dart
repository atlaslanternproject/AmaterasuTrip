// Provider Riverpod delle checklist: archivio Firestore che legge solo ciò
// che le regole permettono (liste condivise e proprie personali), modifiche
// delle singole voci ed elenco in tempo reale.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../data/trip_checklist_entries.dart';
import '../models/trip_checklist.dart';
import '../models/trip_checklist_codec.dart';

final tripChecklistsStoreProvider = Provider<TripSectionStore<TripChecklist>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripChecklistCodec(),
    queries: (items, uid) => [
      items.where('visibility', isEqualTo: 'shared'),
      items
          .where('visibility', isEqualTo: 'private')
          .where('createdByUid', isEqualTo: uid),
    ],
  ),
);

final tripChecklistEntriesProvider = Provider<TripChecklistEntries>(
  (ref) => FirestoreTripChecklistEntries(FirebaseFirestore.instance),
);

final tripChecklistsProvider = StreamProvider.autoDispose
    .family<List<TripChecklist>, String>(
      (ref, tripId) => ref.watch(tripChecklistsStoreProvider).watch(tripId),
    );

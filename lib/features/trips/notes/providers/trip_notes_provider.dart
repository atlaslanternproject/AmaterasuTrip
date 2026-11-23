// Provider Riverpod delle note: archivio Firestore che legge solo ciò che
// le regole permettono (note condivise e proprie private) ed elenco in
// tempo reale.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/firestore_trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_note.dart';
import '../models/trip_note_codec.dart';

final tripNotesStoreProvider = Provider<TripSectionStore<TripNote>>(
  (ref) => FirestoreTripSectionStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    const TripNoteCodec(),
    queries: (items, uid) => [
      items.where('visibility', isEqualTo: 'shared'),
      items
          .where('visibility', isEqualTo: 'private')
          .where('createdByUid', isEqualTo: uid),
    ],
  ),
);

final tripNotesProvider = StreamProvider.autoDispose
    .family<List<TripNote>, String>(
      (ref, tripId) => ref.watch(tripNotesStoreProvider).watch(tripId),
    );

// Archivio delle categorie personalizzate del viaggio usate dalle sezioni
// (trips/{tripId}/sectionCategories, come bucketCategories): si leggono una
// volta quando si apre l'editor (nessun ascolto sempre attivo) e si
// aggiunge una categoria quando la si scrive per la prima volta.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_section_categories.dart';

abstract interface class TripSectionCategoriesStore {
  Future<List<String>> labels(String tripId);

  /// Saves a new label for the trip; an existing one is left as it is.
  Future<void> add(String tripId, String label);
}

class FirestoreTripSectionCategoriesStore
    implements TripSectionCategoriesStore {
  FirestoreTripSectionCategoriesStore(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String tripId) =>
      _db.collection('trips').doc(tripId).collection('sectionCategories');

  @override
  Future<List<String>> labels(String tripId) async {
    final snap = await _col(tripId).limit(200).get();
    final labels = [
      for (final doc in snap.docs)
        if (doc.data()['label'] is String) doc.data()['label'] as String,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  @override
  Future<void> add(String tripId, String label) async {
    final uid = _auth.currentUser?.uid;
    final clean = TripSectionCategories.clean(label);
    if (uid == null || clean.isEmpty) return;
    final ref = _col(tripId).doc(TripSectionCategories.idOf(clean));
    try {
      // Only creation is allowed: an existing label is refused, which is fine.
      await ref.set({
        'label': clean,
        'createdByUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

final tripSectionCategoriesStoreProvider = Provider<TripSectionCategoriesStore>(
  (ref) => FirestoreTripSectionCategoriesStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

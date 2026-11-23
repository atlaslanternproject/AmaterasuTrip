// Voto di un viaggiatore su un ristorante: scrive solo la propria voce del
// campo votes (votes.<uid>), così modifiche e voti degli altri restano
// intatti. Le regole permettono di cambiare solo il proprio voto.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';

abstract interface class TripRestaurantVoteService {
  /// [level] SS, S, A or B; null removes the vote.
  Future<void> vote({
    required String tripId,
    required String restaurantId,
    required String uid,
    required String? level,
  });
}

class FirestoreTripRestaurantVoteService implements TripRestaurantVoteService {
  FirestoreTripRestaurantVoteService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> vote({
    required String tripId,
    required String restaurantId,
    required String uid,
    required String? level,
  }) => _firestore
      .doc(
        'trips/${tripSectionCheckedId(tripId)}/restaurants/'
        '${tripSectionCheckedId(restaurantId)}',
      )
      .update({
        FieldPath(['votes', uid]): level ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}

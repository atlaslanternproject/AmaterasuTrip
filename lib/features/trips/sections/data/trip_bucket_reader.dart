// Lettura in sola lettura delle attività della bucket list (modulo
// approvato, nessun suo file cambia) con le sue pagine da 50: usata da
// Cerca e dalla Mappa. Si sostituisce nei test.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_activity_repository.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';

typedef TripBucketReader = Future<List<BucketListItem>> Function(String tripId);

final tripBucketReaderProvider = Provider<TripBucketReader>(
  (ref) => (tripId) async {
    final repository = BucketActivityRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    final items = <BucketListItem>[];
    DocumentSnapshot<Map<String, dynamic>>? after;
    for (var page = 0; page < 40; page++) {
      final result = await repository.fetchPage(
        tripId: tripId,
        pageSize: 50,
        after: after,
      );
      items.addAll(result.items);
      if (!result.hasMore) break;
      after = result.lastDocument;
    }
    return items;
  },
);

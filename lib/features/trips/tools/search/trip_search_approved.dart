// "Cerca" nei moduli approvati (tappa 2c), in sola lettura e con le loro
// letture già esistenti: spese condivise in cui partecipo e mie private
// (BudgetApi) e bucket list a pagine da 50 (lettura condivisa).
// Nessun cambiamento a quei moduli.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/data/trip_bucket_reader.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'trip_search_sources.dart';
import 'trip_search_text.dart';

/// Expenses the user already sees in the expenses page.
Future<List<TripSearchDoc>> tripSearchExpenses(BudgetApi api) async {
  final parts = await Future.wait([
    api.sharedExpenses().first,
    api.privateExpenses().first,
  ]);
  return [
    for (final part in parts)
      for (final doc in part.docs)
        TripSearchDoc(
          section: TripSearchSection.expenses,
          id: doc.id,
          title: '${doc.data()['title'] ?? ''}'.trim(),
          texts: tripSearchTexts(doc.data()),
        ),
  ];
}

typedef TripSearchBucketLoader =
    Future<List<TripSearchDoc>> Function(String tripId);

/// Bucket list activities, read with the shared bucket list reader.
final tripSearchBucketLoaderProvider = Provider<TripSearchBucketLoader>(
  (ref) => (tripId) async => [
    for (final item in await ref.read(tripBucketReaderProvider)(tripId))
      TripSearchDoc(
        section: TripSearchSection.bucketList,
        id: item.id,
        title: item.name,
        texts: [
          for (final t in [
            item.name,
            item.city,
            item.country,
            item.notes,
            item.customCategory,
            item.address,
          ])
            if (t != null && t.trim().isNotEmpty) t.trim(),
        ],
      ),
  ],
);

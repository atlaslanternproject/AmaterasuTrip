// Test della lettura di "Cerca" (nuova tappa 2a): usa gli stessi store
// delle sezioni e prende solo ciò che restituiscono (le note private degli
// altri lo store non le legge, quindi non compaiono mai), alloggi, spese
// (condivise con me e mie private) e bucket list compresi.

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_approved.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart';

class _Stays extends FakeTripStaysRepository {
  @override
  Stream<List<TripStay>> watch(String tripId) => Stream.value([testStay('s1')]);
}

void main() {
  test('reads with the section stores, nothing else', () async {
    // What the notes store returns: shared notes and my private ones.
    final notes = FakeSectionStore<TripNote>(
      items: const [
        TripNote(id: 'n1', tripId: 't1', createdByUid: 'bruno', title: 'Frasi'),
        TripNote(
          id: 'n2',
          tripId: 't1',
          createdByUid: 'anna',
          title: 'Mia',
          isPrivate: true,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        tripStaysRepositoryProvider.overrideWithValue(_Stays()),
        tripNotesStoreProvider.overrideWithValue(notes),
        tripTransportsStoreProvider.overrideWithValue(
          FakeSectionStore<TripTransport>(),
        ),
        tripReservationsStoreProvider.overrideWithValue(
          FakeSectionStore<TripReservation>(),
        ),
        tripRestaurantsStoreProvider.overrideWithValue(
          FakeSectionStore<TripRestaurant>(),
        ),
        tripSavedPlacesStoreProvider.overrideWithValue(
          FakeSectionStore<TripSavedPlace>(),
        ),
        tripShoppingStoreProvider.overrideWithValue(
          FakeSectionStore<TripShoppingItem>(),
        ),
        tripChecklistsStoreProvider.overrideWithValue(
          FakeSectionStore<TripChecklist>(),
        ),
        tripMemoriesStoreProvider.overrideWithValue(
          FakeSectionStore<TripMemory>(),
        ),
        // Expenses: what the expenses page reads (shared with me, my own).
        tripStaysBudgetApiProvider('t1').overrideWithValue(
          FakeBudgetApi(
            shared: [
              FakeDoc('e1', {'title': 'Cena sushi', 'notes': 'Ginza'}),
            ],
            private: [
              FakeDoc('e2', {
                'title': 'Souvenir',
                'participantUids': ['A'],
              }),
            ],
          ),
        ),
        tripSearchBucketLoaderProvider.overrideWithValue(
          (id) async => const [
            TripSearchDoc(
              section: TripSearchSection.bucketList,
              id: 'b1',
              title: 'Fushimi Inari',
              texts: ['Fushimi Inari', 'Kyoto'],
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    final docs = await container.read(tripSearchDocsProvider('t1').future);
    expect(
      [for (final d in docs) '${d.section.name}:${d.id}'],
      [
        'stays:s1',
        'notes:n1',
        'notes:n2',
        'expenses:e1',
        'expenses:e2',
        'bucketList:b1',
      ],
    );
    expect(docs.first.texts, contains('Hotel Kyoto'));
    final dinner = docs.firstWhere((d) => d.id == 'e1');
    expect(dinner.title, 'Cena sushi');
    expect(dinner.texts, ['Cena sushi', 'Ginza']);
    // Identifiers are never searchable.
    expect(docs.firstWhere((d) => d.id == 'e2').texts, ['Souvenir']);
  });
}

// Test automatico della dimensione del testo (Extra E3): ogni pagina delle
// sezioni, con un elemento in vista card e con l'editor aperto, a
// larghezza telefono (390) e testo al 130% non dà errori di spazio né
// sovrapposizioni (Flutter li segnala come errori durante il disegno).
// Casi, ad esempio: "transports at 130%", "notes at 130%".

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/checklists/trip_checklists_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/memories/trip_memories_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/restaurants/trip_restaurants_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/saved_places/trip_saved_places_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/shopping/trip_shopping_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../restaurants/trip_restaurants_page_test.dart' show FakeVotes;
import 'support/fake_section_store.dart';

const long = 'Un nome molto lungo per vedere se il testo grande va a capo bene';

/// Opens [page] at phone width with text at 130 %, then its editor.
Future<void> check(
  WidgetTester tester,
  Widget page,
  List<Override> overrides,
  String addKey,
) async {
  bigWindow(tester, width: 390);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(sectionsTestApp(page, overrides: overrides));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'list');
  await tapKey(tester, addKey);
  expect(tester.takeException(), isNull, reason: 'editor');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final today = DateTime(2027, 4, 1);

  testWidgets('transports at 130%', (tester) async {
    await check(tester, TripTransportPage(tripId: 't1', today: today), [
      tripTransportsStoreProvider.overrideWithValue(
        FakeSectionStore<TripTransport>(
          items: [
            TripTransport(
              id: 'a',
              tripId: 't1',
              createdByUid: 'anna',
              type: TripTransportType.flight,
              status: TripBookingStatus.booked,
              departureDate: DateTime(2027, 4, 12),
              departureTime: '10:00',
              departureOffset: '+01:00',
              carrier: long,
            ),
          ],
        ),
      ),
    ], 'transport-add');
  });

  testWidgets('bookings at 130%', (tester) async {
    await check(tester, TripBookingsPage(tripId: 't1', today: today), [
      tripReservationsStoreProvider.overrideWithValue(
        FakeSectionStore<TripReservation>(
          items: const [
            TripReservation(
              id: 'r',
              tripId: 't1',
              createdByUid: 'anna',
              name: long,
              category: TripReservationCategory.tour,
              customCategories: ['Con i bambini', 'Da non perdere'],
            ),
          ],
        ),
      ),
    ], 'reservation-add');
  });

  testWidgets('restaurants at 130%', (tester) async {
    await check(tester, const TripRestaurantsPage(tripId: 't1'), [
      tripRestaurantsStoreProvider.overrideWithValue(
        FakeSectionStore<TripRestaurant>(
          items: const [
            TripRestaurant(
              id: 'r',
              tripId: 't1',
              createdByUid: 'anna',
              name: long,
              cuisine: 'Ramen',
              priceLevel: 2,
            ),
          ],
        ),
      ),
      tripRestaurantVotesProvider.overrideWithValue(FakeVotes()),
    ], 'restaurant-add');
  });

  testWidgets('saved places at 130%', (tester) async {
    await check(tester, const TripSavedPlacesPage(tripId: 't1'), [
      tripSavedPlacesStoreProvider.overrideWithValue(
        FakeSectionStore<TripSavedPlace>(
          items: const [
            TripSavedPlace(
              id: 'p',
              tripId: 't1',
              createdByUid: 'anna',
              name: long,
              category: TripSavedPlaceCategory.sight,
              priority: 'SS',
            ),
          ],
        ),
      ),
    ], 'saved-place-add');
  });

  testWidgets('notes at 130%', (tester) async {
    await check(tester, const TripNotesPage(tripId: 't1'), [
      tripNotesStoreProvider.overrideWithValue(
        FakeSectionStore<TripNote>(
          items: const [
            TripNote(
              id: 'n',
              tripId: 't1',
              createdByUid: 'anna',
              title: long,
              body: '# Titolo\n- voce',
            ),
          ],
        ),
      ),
    ], 'note-add');
  });

  testWidgets('shopping at 130%', (tester) async {
    await check(tester, const TripShoppingPage(tripId: 't1'), [
      tripShoppingStoreProvider.overrideWithValue(
        FakeSectionStore<TripShoppingItem>(
          items: const [
            TripShoppingItem(
              id: 's',
              tripId: 't1',
              createdByUid: 'anna',
              name: long,
              priority: 'S',
            ),
          ],
        ),
      ),
      tripPackingStoreProvider.overrideWithValue(
        FakeSectionStore<TripPackingItem>(),
      ),
    ], 'shopping-add');
  });

  testWidgets('checklists at 130%', (tester) async {
    await check(tester, const TripChecklistsPage(tripId: 't1'), [
      tripChecklistsStoreProvider.overrideWithValue(
        FakeSectionStore<TripChecklist>(
          items: const [
            TripChecklist(
              id: 'c',
              tripId: 't1',
              createdByUid: 'anna',
              title: long,
            ),
          ],
        ),
      ),
    ], 'checklist-add');
  });

  testWidgets('memories at 130%', (tester) async {
    await check(tester, const TripMemoriesPage(tripId: 't1'), [
      tripMemoriesStoreProvider.overrideWithValue(
        FakeSectionStore<TripMemory>(
          items: [
            TripMemory(
              id: 'm',
              tripId: 't1',
              createdByUid: 'anna',
              kind: TripMemoryKind.day,
              date: DateTime(2027, 4, 12),
              text: long,
            ),
          ],
        ),
      ),
    ], 'memory-add');
  });
}

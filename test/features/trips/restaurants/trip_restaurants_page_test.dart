// Test automatici della pagina Ristoranti: creazione dal luogo Google (con
// telefono e sito), voti come nella bucket list, ordine per voti, filtri,
// spesa collegata (categoria cibo) e viste.
// Casi, ad esempio: "Google place fills name, phone and website", "vote and remove the vote".

import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/restaurants/trip_restaurants_page.dart';
import 'package:amaterasutrip/features/trips/restaurants/data/trip_restaurant_vote_service.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart' show FakePlaceInfo;

class FakeVotes implements TripRestaurantVoteService {
  final calls = <(String, String, String?)>[];

  @override
  Future<void> vote({
    required String tripId,
    required String restaurantId,
    required String uid,
    required String? level,
  }) async => calls.add((restaurantId, uid, level));
}

TripRestaurant restaurant(
  String id, {
  Map<String, String> votes = const {},
  int? price,
  TripRestaurantStatus status = TripRestaurantStatus.toTry,
}) => TripRestaurant(
  id: id,
  tripId: 't1',
  createdByUid: 'anna',
  name: 'Locale $id',
  status: status,
  votes: votes,
  priceLevel: price,
  cuisine: 'Ramen',
);

Future<(FakeSectionStore<TripRestaurant>, FakeVotes)> open(
  WidgetTester tester, {
  List<TripRestaurant> items = const [],
  double width = 1000,
  FakePlaceInfo? placeInfo,
}) async {
  bigWindow(tester, width: width);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  final store = FakeSectionStore<TripRestaurant>(items: items);
  final votes = FakeVotes();
  await tester.pumpWidget(
    sectionsTestApp(
      const TripRestaurantsPage(tripId: 't1'),
      placeInfo: placeInfo,
      overrides: [
        tripRestaurantsStoreProvider.overrideWithValue(store),
        tripRestaurantVotesProvider.overrideWithValue(votes),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (store, votes);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Google place fills name, phone and website', (tester) async {
    final (store, _) = await open(
      tester,
      placeInfo: FakePlaceInfo(
        contactsResult: const AmaterasuPlaceContacts(
          phone: '+81 75 1',
          website: 'https://granvia.jp',
        ),
      ),
    );
    await tapKey(tester, 'restaurant-add');
    await tester.enterText(
      find.byKey(const Key('restaurant-place-search')),
      'granvia',
    );
    await tapKey(tester, 'restaurant-place-search-go');
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'restaurant-price-2');
    await tester.enterText(find.byKey(const Key('restaurant-party')), '4');
    await tapKey(tester, 'restaurant-save');
    final item = store.created.single;
    expect(item.name, 'Hotel Granvia Kyoto');
    expect(item.place.placeId, 'ChIJ-kyoto');
    expect(item.phone, '+81 75 1');
    expect(item.website, 'https://granvia.jp');
    expect(item.priceLevel, 2);
    expect(item.partySize, 4);
  });

  testWidgets('a wrong party size is explained', (tester) async {
    final (store, _) = await open(tester);
    await tapKey(tester, 'restaurant-add');
    await tester.enterText(find.byKey(const Key('restaurant-place-name')), 'X');
    await tester.enterText(find.byKey(const Key('restaurant-party')), '0');
    await tapKey(tester, 'restaurant-save');
    expect(find.text('Persone: scrivi un numero da 1 a 100.'), findsOneWidget);
    expect(store.created, isEmpty);
  });

  testWidgets('vote and remove the vote; most voted first', (tester) async {
    final (_, votes) = await open(
      tester,
      items: [
        restaurant('low', votes: const {'bruno': 'B'}),
        restaurant('top', votes: const {'anna': 'SS', 'bruno': 'S'}),
      ],
    );
    final cards = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('restaurant-card-'),
    );
    expect(
      (tester.widget(cards.first).key! as ValueKey<String>).value,
      'restaurant-card-top',
    );
    expect(find.text('SS · 1'), findsOneWidget);
    await tapKey(tester, 'restaurant-vote-low-A');
    await tapKey(tester, 'restaurant-vote-top-SS');
    expect(votes.calls, [('low', 'anna', 'A'), ('top', 'anna', null)]);
  });

  testWidgets('filter by price and status; three views', (tester) async {
    await open(
      tester,
      items: [
        restaurant('a', price: 1),
        restaurant('b', price: 3, status: TripRestaurantStatus.tried),
      ],
    );
    await pickFilter(tester, 'restaurant', 'restaurant-filter-kind-3');
    expect(find.byKey(const Key('restaurant-card-b')), findsOneWidget);
    expect(find.byKey(const Key('restaurant-card-a')), findsNothing);
    await pickFilter(tester, 'restaurant', 'restaurant-filter-kind-all');
    await pickFilter(tester, 'restaurant', 'restaurant-filter-status-toTry');
    expect(find.byKey(const Key('restaurant-card-a')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('restaurant-view')),
        matching: find.text('Dettagli'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restaurant-row-a')), findsOneWidget);
  });

  testWidgets('Crea spesa starts as a food expense', (tester) async {
    await open(tester, items: [restaurant('a')]);
    await tapKey(tester, 'restaurant-expense-create-a');
    final dialog = tester.widget<BudgetCreateDialog>(
      find.byType(BudgetCreateDialog),
    );
    expect(dialog.initialCategory, 'food');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, items: [restaurant('a', price: 4)]);
    await tapKey(tester, 'restaurant-add');
    expect(tester.takeException(), isNull);
  });
}

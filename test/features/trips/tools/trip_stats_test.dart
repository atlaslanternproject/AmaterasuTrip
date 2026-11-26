// Test delle Statistiche (tappa 3b): il modulo condiviso del budget dà
// per persona la stessa quota del cruscotto ("la mia quota") e converte con
// il tasso della spesa; senza tasso la spesa resta fuori; i calcoli del
// viaggio (notti, città senza doppioni, annullati esclusi, trasporti per
// tipo, ristoranti provati, luoghi visitati); lettura con le spese annullate
// escluse come nel cruscotto; pagina e 130 %.

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_totals.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/tools/stats/trip_stats.dart';
import 'package:amaterasutrip/features/trips/tools/stats/trip_stats_data.dart';
import 'package:amaterasutrip/features/trips/tools/stats/trip_stats_page.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/appearance/amaterasu_dates_test.dart'
    show FixedAppearance;
import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart';

FakeDoc expense(
  String id,
  String category,
  String currency,
  Map<String, int> shares, {
  String? lifecycle,
}) => FakeDoc(id, {
  'title': id,
  'category': category,
  'lifecycle': ?lifecycle,
  'snapshot': {
    'total': {
      'currency': currency,
      'minorUnits': shares.values.fold(0, (a, b) => a + b),
    },
    'shares': {
      for (final s in shares.entries)
        s.key: {'currency': currency, 'minorUnits': s.value},
    },
    'advances': const {},
  },
});

final yen = BudgetFxQuote(
  base: 'JPY',
  quote: 'EUR',
  rate: 0.01,
  observedDate: DateTime(2027, 4, 10),
  requestedDate: null,
  source: 'Frankfurter',
);

TripStatsData sample() => TripStatsData(
  stays: [
    testStay('s1', day: 10, nights: 3),
    testStay('s2', day: 13, nights: 2),
    testStay('s3', name: 'X', status: TripStayStatus.cancelled),
  ],
  transports: [
    TripTransport(
      id: 't1',
      tripId: 't1',
      createdByUid: 'anna',
      type: TripTransportType.flight,
      departureDate: DateTime(2027, 4, 10),
    ),
    TripTransport(
      id: 't2',
      tripId: 't1',
      createdByUid: 'anna',
      type: TripTransportType.train,
      status: TripBookingStatus.cancelled,
      departureDate: DateTime(2027, 4, 11),
    ),
  ],
  restaurants: const [
    TripRestaurant(
      id: 'r1',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'A',
      status: TripRestaurantStatus.tried,
      triedRating: 4,
    ),
    TripRestaurant(
      id: 'r2',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'B',
      status: TripRestaurantStatus.tried,
      triedRating: 5,
    ),
    TripRestaurant(id: 'r3', tripId: 't1', createdByUid: 'anna', name: 'C'),
  ],
  places: const [
    TripSavedPlace(
      id: 'p1',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'P',
      category: TripSavedPlaceCategory.sight,
      visited: true,
    ),
    TripSavedPlace(
      id: 'p2',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'Q',
      category: TripSavedPlaceCategory.food,
    ),
  ],
  expenses: TripStatsExpenses(
    currency: 'EUR',
    totals: BudgetCategoryTotals.compute(
      [
        expense('e1', 'food', 'EUR', {'anna': 3000, 'bruno': 3000}),
        expense('e2', 'transport', 'EUR', {'anna': 1000}),
      ],
      'EUR',
      const {},
      'anna',
    ),
    customCategories: const {},
    names: const {'anna': 'Anna', 'bruno': 'Bruno'},
  ),
);

class _NoStays extends FakeTripStaysRepository {
  @override
  Stream<List<TripStay>> watch(String tripId) => Stream.value(const []);
}

/// The real loader with fake sections and the given budget.
Future<TripStatsData> statsLoaderForTest(
  FakeBudgetApi api, {
  AmaterasuAppearance appearance = const AmaterasuAppearance(),
}) async {
  final container = ProviderContainer(
    overrides: [
      amaterasuAppearanceProvider.overrideWith(
        () => FixedAppearance(appearance),
      ),
      tripStaysRepositoryProvider.overrideWithValue(_NoStays()),
      tripTransportsStoreProvider.overrideWithValue(
        FakeSectionStore<TripTransport>(),
      ),
      tripRestaurantsStoreProvider.overrideWithValue(
        FakeSectionStore<TripRestaurant>(),
      ),
      tripSavedPlacesStoreProvider.overrideWithValue(
        FakeSectionStore<TripSavedPlace>(),
      ),
      tripStaysBudgetApiProvider('t1').overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container.read(tripStatsLoaderProvider)('t1');
}

void main() {
  test('shared module: per person equals my share, same rate', () {
    final docs = [
      expense('e1', 'food', 'EUR', {'anna': 1500, 'bruno': 2500}),
      expense('e2', 'food', 'JPY', {'anna': 10000, 'bruno': 10000}),
      expense('e3', 'other', 'USD', {'anna': 500}),
    ];
    final r = BudgetCategoryTotals.compute(docs, 'EUR', {'e2': yen}, 'anna');
    // JPY has no cents: 20000 yen x 0.01 = 200 EUR = 20000 cents.
    expect(r.totals, {'food': 4000 + 20000});
    expect(r.myShare, r.perPerson['anna']);
    expect(r.perPerson, {'anna': 1500 + 10000, 'bruno': 2500 + 10000});
    // No rate for USD: left out, like in the dashboard.
    expect(r.excludedCount, 1);
    expect(r.excluded, {'USD': 500});
  });

  test('trip numbers: nights, cities, cancelled left out', () {
    final s = TripStats.from(sample());
    expect(s.nights, 5);
    expect(s.transportsByType, {TripTransportType.flight: 1});
    expect((s.tried, s.restaurants, s.averageRating), (2, 3, 4.5));
    expect((s.visited, s.places), (1, 2));
  });

  testWidgets('page: numbers, donut, people, 130 % phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    bigWindow(tester, width: 390);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripStatsPage(tripId: 't1'),
        overrides: [
          tripStatsLoaderProvider.overrideWithValue((id) async => sample()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stats-category-chart')), findsOneWidget);
    expect(find.byKey(const Key('stats-person-anna')), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  test('loader: cancelled expenses left out, as in the dashboard', () async {
    final api = FakeBudgetApi(
      uid: 'anna',
      members: const [
        {'uid': 'anna', 'name': 'Anna'},
      ],
      shared: [
        expense('e1', 'food', 'EUR', {'anna': 1000}),
        expense('e2', 'food', 'EUR', {'anna': 9000}, lifecycle: 'cancelled'),
      ],
    );
    final data = await statsLoaderForTest(api);
    expect(data.expenses!.totals.total, 1000);
    expect(data.expenses!.names, {'anna': 'Anna'});
  });

  test('loader: totals in the Appearance currency, like the budget', () async {
    // Trip in yen, Appearance in euro, expenses in euro: no rate needed.
    final api = FakeBudgetApi(
      uid: 'anna',
      currency: 'JPY',
      members: const [
        {'uid': 'anna', 'name': 'Anna'},
      ],
      shared: [
        expense('e1', 'food', 'EUR', {'anna': 1000}),
      ],
    );
    final data = await statsLoaderForTest(
      api,
      appearance: const AmaterasuAppearance(displayCurrency: 'EUR'),
    );
    expect(data.expenses!.currency, 'EUR');
    expect(data.expenses!.totals.total, 1000);
    final trip = await statsLoaderForTest(api);
    expect(trip.expenses!.currency, 'JPY');
  });
}

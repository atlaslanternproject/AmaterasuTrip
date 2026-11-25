// Test automatici delle aggiunte v2 ai ristoranti: orari di Google (lettura
// della risposta, chiuso il giorno o l'ora prenotati), pannello "Orari e
// prezzi" con prezzo convertito, voto a stelle e nota di chi l'ha provato.
// Casi, ad esempio: "closed on Monday and after 22:00", "sheet warns and converts the price".

import 'package:amaterasutrip/core/places/amaterasu_place_hours_parse.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/restaurants/trip_restaurants_page.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_codec.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_hours_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart' show FakePlaceInfo;
import 'trip_restaurants_page_test.dart' show FakeVotes;

Map<String, Object?> at(int day, int hour) => {
  'day': day,
  'hour': hour,
  'minute': 0,
};

/// Tuesday to Sunday 12-15 and 18-22; Saturday until 02:00; closed Monday.
final hours = parsePlaceHours({
  'text': ['lunedì: Chiuso', 'martedì: 12:00–15:00, 18:00–22:00'],
  'periods': [
    for (final d in [0, 2, 3, 4, 5, 6]) {'open': at(d, 12), 'close': at(d, 15)},
    for (final d in [0, 2, 3, 4, 5]) {'open': at(d, 18), 'close': at(d, 22)},
    {'open': at(6, 18), 'close': at(0, 2)},
  ],
});

TripRestaurant booked({String? time = '20:00', DateTime? day}) =>
    TripRestaurant(
      id: 'r1',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'Ichiran',
      status: TripRestaurantStatus.booked,
      place: const TripSectionPlace(name: 'Ichiran', placeId: 'p1'),
      reservationDate: day ?? DateTime(2027, 4, 12),
      reservationTime: time,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('closed on Monday and outside the opening hours', () {
    final monday = DateTime(2027, 4, 12);
    final tuesday = DateTime(2027, 4, 13);
    final sunday = DateTime(2027, 4, 18);
    expect(hours.closedOn(monday), isTrue);
    expect(hours.closedOn(tuesday), isFalse);
    expect(hours.closedAt(tuesday, '13:00'), isFalse);
    expect(hours.closedAt(tuesday, '16:30'), isTrue);
    // Saturday night goes on until 02:00 on Sunday.
    expect(hours.closedAt(sunday, '01:30'), isFalse);
    expect(hours.closedAt(sunday, '03:00'), isTrue);
    expect(const AmaterasuPlaceHours().closedOn(monday), isNull);
    expect(parsePriceLevel('MODERATE'), 2);
    final range = parsePriceRange({
      'start': {'currency': 'JPY', 'units': 1000},
      'end': {'currency': 'JPY', 'units': 2000},
    })!;
    expect((range.currency, range.start, range.end), ('JPY', 1000, 2000));
  });

  test('stars and note are saved and checked', () {
    const codec = TripRestaurantCodec();
    final item = TripRestaurant(
      id: 'a',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'x',
      status: TripRestaurantStatus.tried,
      triedRating: 4,
      triedNote: 'Ottimo',
    );
    final map = codec.toMap(item);
    expect((map['triedRating'], map['triedNote']), (4, 'Ottimo'));
    expect(codec.toMap(codec.fromMap('a', map)), map);
    final bad = TripRestaurant(
      id: 'b',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'x',
      triedRating: 6,
    );
    expect(codec.problems(bad).single.field, 'rating');
  });

  testWidgets('sheet warns about the closed day and converts the price', (
    tester,
  ) async {
    bigWindow(tester);
    final info = FakePlaceInfo(
      contactsResult: AmaterasuPlaceContacts(
        hours: hours,
        priceRange: const AmaterasuPriceRange(
          currency: 'JPY',
          start: 1000,
          end: 2000,
        ),
      ),
    );
    final fx = BudgetFxService(
      load: (_) async =>
          '{"base":"JPY","quote":"EUR","rate":0.006,'
          '"date":"2026-11-20"}',
    );
    await tester.pumpWidget(
      sectionsTestApp(
        const TripRestaurantsPage(tripId: 't1'),
        placeInfo: info,
        overrides: [
          tripRestaurantsStoreProvider.overrideWithValue(
            FakeSectionStore<TripRestaurant>(items: [booked()]),
          ),
          tripSectionFxProvider.overrideWithValue(fx),
          tripRestaurantVotesProvider.overrideWithValue(FakeVotes()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Nothing is asked to Google until the button is pressed.
    expect(info.contactCalls, isEmpty);
    await tapKey(tester, 'restaurant-hours-r1');
    expect(info.contactCalls, ['p1']);
    expect(find.byKey(const Key('restaurant-closed-r1')), findsOneWidget);
    expect(find.text('lunedì: Chiuso'), findsOneWidget);
    expect(
      find.text('Prezzo indicativo su Google: 1000–2000 JPY'),
      findsOneWidget,
    );
    expect(find.text('Circa 6–12 EUR al cambio di oggi'), findsOneWidget);
  });

  testWidgets('editor asks stars and note only once tried', (tester) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripRestaurant>();
    await tester.pumpWidget(
      sectionsTestApp(
        const TripRestaurantsPage(tripId: 't1'),
        overrides: [
          tripRestaurantsStoreProvider.overrideWithValue(store),
          tripRestaurantVotesProvider.overrideWithValue(FakeVotes()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'restaurant-add');
    await tester.enterText(
      find.byKey(const Key('restaurant-place-name')),
      'Afuri',
    );
    expect(find.byKey(const Key('restaurant-rating-4')), findsNothing);
    await tapKey(tester, 'restaurant-status-tried');
    await tapKey(tester, 'restaurant-rating-4');
    await tester.enterText(
      find.byKey(const Key('restaurant-tried-note')),
      'Brodo ottimo',
    );
    await tapKey(tester, 'restaurant-save');
    final saved = store.created.single;
    expect((saved.triedRating, saved.triedNote), (4, 'Brodo ottimo'));
  });
}

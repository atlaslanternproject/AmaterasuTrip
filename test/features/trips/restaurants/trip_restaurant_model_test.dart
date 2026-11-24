// Test automatici del modello dei ristoranti: conversione Firestore (i voti
// non si scrivono con le modifiche), controlli e conteggio dei voti.
// Casi, ad esempio: "edits never write the votes", "votes count and average".

import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_codec.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_votes.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripRestaurantCodec();

TripRestaurant restaurant({
  String name = 'Ippudo',
  String? phone,
  int? party,
  Map<String, String> votes = const {},
}) => TripRestaurant(
  tripId: 'trip',
  createdByUid: 'anna',
  name: name,
  phone: phone,
  partySize: party,
  votes: votes,
);

void main() {
  allergenTests();
  test('codec round trip; edits never write the votes', () {
    final original = TripRestaurant(
      tripId: 'trip',
      createdByUid: 'anna',
      name: 'Ippudo',
      status: TripRestaurantStatus.booked,
      place: const TripSectionPlace(name: 'Nishiki', placeId: 'p1'),
      phone: '+81 75 1234',
      website: 'https://ippudo.com',
      cuisine: 'Ramen',
      priceLevel: 2,
      reservationDate: DateTime(2027, 4, 14),
      reservationTime: '19:30',
      partySize: 4,
      notes: 'Coda',
      votes: const {'anna': 'SS'},
      expenseId: 'e1',
    );
    final map = codec.toMap(original);
    expect(map.containsKey('votes'), isFalse);
    expect(codec.optionalKeys.contains('votes'), isFalse);
    final back = codec.fromMap('x', {
      ...map,
      'votes': {'anna': 'SS', 'x': 'Z'},
    });
    expect(codec.toMap(back), map);
    expect(back.votes, {'anna': 'SS'});
  });

  test('checks: name, phone, party size', () {
    expect(codec.problems(restaurant()), isEmpty);
    expect(codec.problems(restaurant(name: '')).single.field, 'name');
    expect(codec.problems(restaurant(phone: 'chiama')).single.field, 'phone');
    expect(codec.problems(restaurant(party: 0)).single.field, 'party');
  });

  test('votes count and average', () {
    const votes = {'a': 'SS', 'b': 'SS', 'c': 'B'};
    expect(TripRestaurantVotes.counts(votes), {
      'SS': 2,
      'S': 0,
      'A': 0,
      'B': 1,
    });
    expect(TripRestaurantVotes.average(votes), 3);
    expect(TripRestaurantVotes.average(const {}), 0);
  });
}

void allergenTests() {
  test('allergens and diets: known codes in order, note limit', () {
    final saved = codec.toMap(
      const TripRestaurant(
        tripId: 'trip',
        createdByUid: 'anna',
        name: 'Ippudo',
        allergens: ['gluten', 'milk'],
        allergenNotes: 'Bruno: niente latte',
        diets: ['vegan'],
      ),
    );
    expect(saved['allergens'], ['gluten', 'milk']);
    final back = codec.fromMap('x', {
      ...saved,
      'allergens': ['milk', 'pollen', 'gluten'],
    });
    expect(back.allergens, ['gluten', 'milk']);
    expect(back.diets, ['vegan']);
    expect(
      codec
          .problems(
            TripRestaurant(
              tripId: 't',
              createdByUid: 'a',
              name: 'x',
              allergenNotes: 'x' * 501,
            ),
          )
          .single
          .field,
      'allergenNotes',
    );
  });
}

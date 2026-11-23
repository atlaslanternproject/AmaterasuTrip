// Test automatici dei luoghi salvati: conversione Firestore, controlli e
// lettura dei link di Google Maps incollati (nome e coordinate).
// Casi, ad esempio: "Maps link with place name and coordinates", "codec round trip".

import 'package:amaterasutrip/features/trips/saved_places/models/trip_maps_link.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripSavedPlaceCodec();

void main() {
  test('Maps link with place name and coordinates', () {
    const url =
        'https://www.google.com/maps/place/Fushimi+Inari+Taisha/@34.9671,135.7727,17z';
    expect(TripMapsLink.isMapsLink(url), isTrue);
    final link = TripMapsLink.parse(url);
    expect(link.name, 'Fushimi Inari Taisha');
    expect(link.latitude, 34.9671);
    expect(link.longitude, 135.7727);

    final query = TripMapsLink.parse('https://maps.google.com/?q=35.01,135.76');
    expect((query.latitude, query.longitude), (35.01, 135.76));
    expect(TripMapsLink.isMapsLink('https://maps.app.goo.gl/abc'), isTrue);
    expect(TripMapsLink.isMapsLink('https://example.com/maps'), isFalse);
    expect(TripMapsLink.parse('https://maps.app.goo.gl/abc').name, isNull);
  });

  test('codec round trip and checks', () {
    const item = TripSavedPlace(
      tripId: 'trip',
      createdByUid: 'anna',
      name: 'Inari',
      category: TripSavedPlaceCategory.sight,
      place: TripSectionPlace(name: 'Inari', placeId: 'p1'),
      mapsUrl: 'https://maps.app.goo.gl/abc',
      notes: 'Alba',
    );
    final map = codec.toMap(item);
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(codec.problems(item), isEmpty);
    const bad = TripSavedPlace(
      tripId: 'trip',
      createdByUid: 'anna',
      name: ' ',
      category: TripSavedPlaceCategory.food,
      mapsUrl: 'maps.google.com',
    );
    expect(codec.problems(bad).map((p) => p.field), ['name', 'mapsUrl']);
  });
}

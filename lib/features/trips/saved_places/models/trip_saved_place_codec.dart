// Conversione dei luoghi salvati da e verso Firestore
// (trips/{tripId}/savedPlaces) e controlli con i limiti di firestore.rules.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'trip_saved_place.dart';
import 'trip_saved_place_category.dart';

class TripSavedPlaceCodec implements TripSectionCodec<TripSavedPlace> {
  const TripSavedPlaceCodec();

  @override
  String get collection => 'savedPlaces';

  @override
  List<String> get optionalKeys => [
    ...TripSectionPlace.keys('place'),
    'mapsUrl',
    'notes',
  ];

  @override
  Map<String, dynamic> toMap(TripSavedPlace item) => {
    'tripId': item.tripId,
    'createdByUid': item.createdByUid,
    'name': item.name.trim(),
    'category': item.category.code,
    ...item.place.toMap('place'),
    'mapsUrl': ?TripSectionFields.clean(item.mapsUrl),
    'notes': ?TripSectionFields.clean(item.notes),
  };

  @override
  TripSavedPlace fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final name = text('name');
    final category = TripSavedPlaceCategory.fromCode(data['category']);
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (name == null || category == null || tripId == null || author == null) {
      throw FormatException('Invalid saved place $id.');
    }
    return TripSavedPlace(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      category: category,
      place: TripSectionPlace.fromMap(data, 'place'),
      mapsUrl: text('mapsUrl'),
      notes: text('notes'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripSavedPlace item) {
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name')
      ..maxLength(item.notes, TripSectionFields.notesMax, 'notes');
    c
      ..check(item.place.invalid, TripSectionProblemKind.place, 'place')
      ..check(
        TripSectionFields.badLink(item.mapsUrl),
        TripSectionProblemKind.link,
        'mapsUrl',
      );
    return c.found;
  }
}

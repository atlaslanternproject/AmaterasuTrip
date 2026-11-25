// Conversione delle voci dell'Itinerario da e verso Firestore
// (trips/{tripId}/itinerary) e controlli con i limiti di firestore.rules.
// Lo stato di un elemento collegato non si salva: si legge dalla sezione.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import '../models/trip_itinerary_item.dart';

/// Sections an itinerary item may point to (same names in the rules).
const tripItineraryRefSections = [
  TripSearchSection.stays,
  TripSearchSection.transports,
  TripSearchSection.reservations,
  TripSearchSection.restaurants,
  TripSearchSection.savedPlaces,
  TripSearchSection.bucketList,
];

class TripItineraryCodec implements TripSectionCodec<TripItineraryItem> {
  const TripItineraryCodec();

  static const titleMax = 200;
  static const noteMax = 2000;
  static const zoneMax = 80;
  static const actualMax = 500;
  static const orderMax = 10000;
  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  @override
  String get collection => 'itinerary';

  @override
  List<String> get optionalKeys => [
    'time',
    'endTime',
    'refSection',
    'refId',
    'note',
    'zone',
    ...TripSectionPlace.keys('place'),
    'actualText',
    'actualSection',
    'actualRefId',
  ];

  @override
  Map<String, dynamic> toMap(TripItineraryItem i) => {
    'tripId': i.tripId,
    'createdByUid': i.createdByUid,
    'day': TripStayDates.format(i.day),
    'kind': i.kind.name,
    'title': i.title.trim(),
    'order': i.order,
    'time': ?i.time,
    'endTime': ?i.endTime,
    'refSection': ?i.section?.name,
    'refId': ?i.refId,
    'note': ?TripSectionFields.clean(i.note),
    'zone': ?TripSectionFields.clean(i.zone),
    if (i.place case final p?)
      ...TripSectionPlace(
        name: p.name,
        latitude: p.latitude,
        longitude: p.longitude,
      ).toMap('place'),
    'actualText': ?TripSectionFields.clean(i.actual),
    'actualSection': ?i.actualSection?.name,
    'actualRefId': ?i.actualRefId,
  };

  static TripSearchSection? _section(Object? name) =>
      tripItineraryRefSections.where((s) => s.name == name).firstOrNull;

  @override
  TripItineraryItem fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final day = TripStayDates.parse(data['day']);
    final kind = TripItineraryKind.values
        .where((k) => k.name == data['kind'])
        .firstOrNull;
    final tripId = text('tripId');
    final author = text('createdByUid');
    final title = text('title');
    if (day == null ||
        kind == null ||
        tripId == null ||
        author == null ||
        title == null) {
      throw FormatException('Invalid itinerary item $id.');
    }
    final place = TripSectionPlace.fromMap(data, 'place');
    final zone = text('zone');
    return TripItineraryItem(
      id: id,
      tripId: tripId,
      createdByUid: author,
      day: day,
      kind: kind,
      title: title,
      time: text('time'),
      endTime: text('endTime'),
      order: data['order'] is int ? data['order'] as int : 0,
      section: _section(data['refSection']),
      refId: text('refId'),
      note: text('note'),
      place: place.name == null && zone == null
          ? null
          : TripItineraryPlace(
              name: place.name ?? title,
              latitude: place.latitude,
              longitude: place.longitude,
              zone: zone,
            ),
      actual: text('actualText'),
      actualSection: _section(data['actualSection']),
      actualRefId: text('actualRefId'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripItineraryItem i) {
    bool badTime(String? t) => t != null && !_hhmm.hasMatch(t);
    bool badId(String? v) => v != null && !_id.hasMatch(v);
    final c = TripSectionChecks()
      ..required(i.title, 'title')
      ..maxLength(i.title.trim(), titleMax, 'title')
      ..maxLength(i.note, noteMax, 'note')
      ..maxLength(i.zone, zoneMax, 'zone')
      ..maxLength(i.actual, actualMax, 'actual');
    c
      ..check(
        badTime(i.time) || badTime(i.endTime),
        TripSectionProblemKind.other,
        'time',
      )
      ..check(
        i.order < 0 || i.order > orderMax,
        TripSectionProblemKind.other,
        'order',
      )
      ..check(
        i.kind == TripItineraryKind.ref &&
            (i.section == null || i.refId == null),
        TripSectionProblemKind.other,
        'ref',
      )
      ..check(
        badId(i.refId) || badId(i.actualRefId),
        TripSectionProblemKind.other,
        'ref',
      );
    return c.found;
  }
}

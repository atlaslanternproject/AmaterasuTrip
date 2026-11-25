// Conversione dei luoghi salvati da e verso Firestore
// (trips/{tripId}/savedPlaces) e controlli con i limiti di firestore.rules.

import 'package:amaterasutrip/core/places/amaterasu_contact_validator.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_links.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_priority.dart';
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
    'phone',
    'website',
    'priority',
    'visited',
    'visitMinutes',
    'ticketsUrl',
    'area',
    'plannedDay',
    'estimatedCostMinorUnits',
    'estimatedCostCurrency',
    'usefulLinks',
  ];

  static const priorities = TripSectionPriority.levels;
  static const visitMax = 1440;

  @override
  Map<String, dynamic> toMap(TripSavedPlace item) => {
    'tripId': item.tripId,
    'createdByUid': item.createdByUid,
    'name': item.name.trim(),
    'category': item.category.code,
    ...item.place.toMap('place'),
    'mapsUrl': ?TripSectionFields.clean(item.mapsUrl),
    'notes': ?TripSectionFields.clean(item.notes),
    'phone': ?TripSectionFields.clean(item.phone),
    'website': ?TripSectionFields.clean(item.website),
    'priority': ?item.priority,
    if (item.visited) 'visited': true,
    'visitMinutes': ?item.visitMinutes,
    'ticketsUrl': ?TripSectionFields.clean(item.ticketsUrl),
    'area': ?TripSectionFields.clean(item.area),
    if (item.plannedDay case final day?)
      'plannedDay': TripStayDates.format(day),
    ...TripSectionFields.costMap(
      item.entryPriceMinorUnits,
      item.entryPriceCurrency,
    ),
    ...TripSectionLinks.toMap(item.usefulLinks),
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
    final (cost, currency) = TripSectionFields.readCost(data);
    return TripSavedPlace(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      category: category,
      place: TripSectionPlace.fromMap(data, 'place'),
      mapsUrl: text('mapsUrl'),
      notes: text('notes'),
      phone: text('phone'),
      website: text('website'),
      priority: priorities.contains(data['priority'])
          ? data['priority'] as String
          : null,
      visited: data['visited'] == true,
      visitMinutes: data['visitMinutes'] is int
          ? data['visitMinutes'] as int
          : null,
      ticketsUrl: text('ticketsUrl'),
      area: text('area'),
      plannedDay: TripStayDates.parse(data['plannedDay']),
      entryPriceMinorUnits: cost,
      entryPriceCurrency: currency,
      usefulLinks: TripSectionLinks.read(data),
    );
  }

  @override
  List<TripSectionProblem> problems(TripSavedPlace item) {
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name')
      ..maxLength(item.notes, TripSectionFields.notesMax, 'notes')
      ..maxLength(item.area, TripSectionFields.shortMax, 'area');
    final minutes = item.visitMinutes;
    c
      ..check(item.place.invalid, TripSectionProblemKind.place, 'place')
      ..check(
        TripSectionFields.badLink(item.ticketsUrl),
        TripSectionProblemKind.link,
        'ticketsUrl',
      )
      ..check(
        minutes != null && (minutes < 1 || minutes > visitMax),
        TripSectionProblemKind.other,
        'visit',
      )
      ..check(
        TripSectionFields.badCost(
          item.entryPriceMinorUnits,
          item.entryPriceCurrency,
        ),
        TripSectionProblemKind.cost,
        'cost',
      )
      ..check(
        TripSectionFields.badLink(item.mapsUrl),
        TripSectionProblemKind.link,
        'mapsUrl',
      )
      ..check(
        item.phone != null && !AmaterasuContactValidator.isPhone(item.phone!),
        TripSectionProblemKind.other,
        'phone',
      )
      ..check(
        TripSectionFields.badLink(item.website),
        TripSectionProblemKind.link,
        'website',
      );
    c.check(
      TripSectionLinks.invalid(item.usefulLinks),
      TripSectionProblemKind.link,
      'usefulLinks',
    );
    return c.found;
  }
}

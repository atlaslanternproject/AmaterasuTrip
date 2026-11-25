// Conversione dei ristoranti da e verso Firestore
// (trips/{tripId}/restaurants) e controlli con i limiti di firestore.rules.
// I voti non si scrivono qui (vedi TripRestaurantVoteService): una modifica
// del ristorante non li tocca.

import 'package:amaterasutrip/core/places/amaterasu_contact_validator.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_links.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'trip_restaurant.dart';
import 'trip_restaurant_food.dart';
import 'trip_restaurant_status.dart';
import 'trip_restaurant_votes.dart';

class TripRestaurantCodec implements TripSectionCodec<TripRestaurant> {
  const TripRestaurantCodec();

  static const partyMax = 100;
  static const triedNoteMax = 1000;

  static final _zone = RegExp(r'^[A-Za-z0-9_+/-]{1,64}$');

  @override
  String get collection => 'restaurants';

  @override
  List<String> get optionalKeys => [
    ...TripSectionPlace.keys('place'),
    'phone',
    'website',
    'cuisine',
    'priceLevel',
    'reservationDate',
    'reservationTime',
    'partySize',
    'notes',
    'allergens',
    'allergenNotes',
    'diets',
    'triedRating',
    'triedNote',
    'estimatedCostMinorUnits',
    'estimatedCostCurrency',
    'expenseId',
    'usefulLinks',
    'zone',
    'zoneCity',
  ];

  @override
  Map<String, dynamic> toMap(TripRestaurant item) {
    String? text(String? value) => TripSectionFields.clean(value);
    final day = item.reservationDate;
    return {
      'tripId': item.tripId,
      'createdByUid': item.createdByUid,
      'name': item.name.trim(),
      'status': item.status.code,
      ...item.place.toMap('place'),
      'phone': ?text(item.phone),
      'website': ?text(item.website),
      'cuisine': ?text(item.cuisine),
      'priceLevel': ?item.priceLevel,
      if (day != null) 'reservationDate': TripStayDates.format(day),
      'reservationTime': ?text(item.reservationTime),
      'partySize': ?item.partySize,
      'notes': ?text(item.notes),
      if (item.allergens.isNotEmpty) 'allergens': List.of(item.allergens),
      'allergenNotes': ?text(item.allergenNotes),
      if (item.diets.isNotEmpty) 'diets': List.of(item.diets),
      'triedRating': ?item.triedRating,
      'triedNote': ?text(item.triedNote),
      ...TripSectionFields.costMap(
        item.estimatedCostMinorUnits,
        item.estimatedCostCurrency,
      ),
      'expenseId': ?text(item.expenseId),
      'zone': ?TripSectionFields.clean(item.zone),
      'zoneCity': ?TripSectionFields.clean(item.zoneCity),
      ...TripSectionLinks.toMap(item.usefulLinks),
    };
  }

  @override
  TripRestaurant fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    int? number(String key) => data[key] is int ? data[key] as int : null;
    final name = text('name');
    final status = TripRestaurantStatus.fromCode(data['status']);
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (name == null || status == null || tripId == null || author == null) {
      throw FormatException('Invalid restaurant $id.');
    }
    final (cost, currency) = TripSectionFields.readCost(data);
    return TripRestaurant(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      status: status,
      place: TripSectionPlace.fromMap(data, 'place'),
      phone: text('phone'),
      website: text('website'),
      cuisine: text('cuisine'),
      priceLevel: number('priceLevel'),
      reservationDate: TripStayDates.parse(data['reservationDate']),
      reservationTime: text('reservationTime'),
      partySize: number('partySize'),
      notes: text('notes'),
      votes: TripRestaurantVotes.read(data['votes']),
      allergens: TripRestaurantFood.read(
        data['allergens'],
        TripRestaurantFood.allergens,
      ),
      allergenNotes: text('allergenNotes'),
      triedRating: number('triedRating'),
      triedNote: text('triedNote'),
      diets: TripRestaurantFood.read(data['diets'], TripRestaurantFood.diets),
      estimatedCostMinorUnits: cost,
      estimatedCostCurrency: currency,
      expenseId: text('expenseId'),
      usefulLinks: TripSectionLinks.read(data),
      zone: TripSectionFields.readText(data, 'zone'),
      zoneCity: TripSectionFields.readText(data, 'zoneCity'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripRestaurant item) {
    const other = TripSectionProblemKind.other;
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name')
      ..maxLength(item.cuisine, TripSectionFields.shortMax, 'cuisine')
      ..maxLength(item.notes, TripSectionFields.notesMax, 'notes')
      ..maxLength(item.triedNote, triedNoteMax, 'triedNote')
      ..maxLength(
        item.allergenNotes,
        TripRestaurantFood.notesMax,
        'allergenNotes',
      );
    final phone = item.phone;
    final party = item.partySize;
    final stars = item.triedRating;
    c
      ..check(item.place.invalid, TripSectionProblemKind.place, 'place')
      ..check(
        phone != null && !AmaterasuContactValidator.isPhone(phone),
        other,
        'phone',
      )
      ..check(
        TripSectionFields.badLink(item.website),
        TripSectionProblemKind.link,
        'website',
      )
      ..check(
        item.reservationTime != null &&
            !TripStayDates.isValidTime(item.reservationTime),
        other,
        'time',
      )
      ..check(party != null && (party < 1 || party > partyMax), other, 'party')
      ..check(stars != null && (stars < 1 || stars > 5), other, 'rating')
      ..check(
        TripSectionFields.badCost(
          item.estimatedCostMinorUnits,
          item.estimatedCostCurrency,
        ),
        TripSectionProblemKind.cost,
        'cost',
      )
      ..check(
        TripSectionFields.badExpenseId(item.expenseId),
        TripSectionProblemKind.expense,
        'expenseId',
      );
    c.check(
      (item.zone != null && !_zone.hasMatch(item.zone!)) ||
          (item.zoneCity?.trim().length ?? 0) > TripSectionFields.shortMax,
      TripSectionProblemKind.other,
      'zone',
    );
    c.check(
      TripSectionLinks.invalid(item.usefulLinks),
      TripSectionProblemKind.link,
      'usefulLinks',
    );
    return c.found;
  }
}

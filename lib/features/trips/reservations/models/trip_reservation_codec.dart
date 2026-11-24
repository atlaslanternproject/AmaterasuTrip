// Conversione delle prenotazioni da e verso Firestore
// (trips/{tripId}/reservations) e controlli con gli stessi limiti di
// firestore.rules. I campi facoltativi vuoti non vengono salvati.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'trip_reservation.dart';
import 'trip_reservation_category.dart';

class TripReservationCodec implements TripSectionCodec<TripReservation> {
  const TripReservationCodec();

  static const policyMax = 2000;
  static const ticketCodeMax = 500;
  static const ticketsMax = 99;

  @override
  String get collection => 'reservations';

  @override
  List<String> get optionalKeys => [
    ...TripSectionPlace.keys('place'),
    'date',
    'time',
    'bookingCode',
    'bookingUrl',
    'participantUids',
    'cancellationPolicy',
    'bookBy',
    'holder',
    'ticketCount',
    'ticketCode',
    'notes',
    'estimatedCostMinorUnits',
    'estimatedCostCurrency',
    'expenseId',
  ];

  @override
  Map<String, dynamic> toMap(TripReservation item) {
    String? text(String? value) => TripSectionFields.clean(value);
    final date = item.date;
    return {
      'tripId': item.tripId,
      'createdByUid': item.createdByUid,
      'name': item.name.trim(),
      'category': item.category.code,
      'status': item.status.code,
      if (date != null) 'date': TripStayDates.format(date),
      'time': ?text(item.time),
      ...item.place.toMap('place'),
      'bookingCode': ?text(item.bookingCode),
      'bookingUrl': ?text(item.bookingUrl),
      if (item.participantUids.isNotEmpty)
        'participantUids': List.of(item.participantUids),
      'cancellationPolicy': ?text(item.cancellationPolicy),
      if (item.bookBy case final day?) 'bookBy': TripStayDates.format(day),
      'holder': ?text(item.holder),
      'ticketCount': ?item.ticketCount,
      'ticketCode': ?text(item.ticketCode),
      'notes': ?text(item.notes),
      ...TripSectionFields.costMap(
        item.estimatedCostMinorUnits,
        item.estimatedCostCurrency,
      ),
      'expenseId': ?text(item.expenseId),
    };
  }

  @override
  TripReservation fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final name = text('name');
    final category = TripReservationCategory.fromCode(data['category']);
    final status = TripBookingStatus.fromCode(data['status']);
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (name == null ||
        category == null ||
        status == null ||
        tripId == null ||
        author == null) {
      throw FormatException('Invalid reservation $id.');
    }
    final (cost, currency) = TripSectionFields.readCost(data);
    return TripReservation(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      category: category,
      status: status,
      date: TripStayDates.parse(data['date']),
      time: text('time'),
      place: TripSectionPlace.fromMap(data, 'place'),
      bookingCode: text('bookingCode'),
      bookingUrl: text('bookingUrl'),
      participantUids: TripSectionFields.readUids(data, 'participantUids'),
      cancellationPolicy: text('cancellationPolicy'),
      bookBy: TripStayDates.parse(data['bookBy']),
      holder: text('holder'),
      ticketCount: data['ticketCount'] is int
          ? data['ticketCount'] as int
          : null,
      ticketCode: text('ticketCode'),
      notes: text('notes'),
      estimatedCostMinorUnits: cost,
      estimatedCostCurrency: currency,
      expenseId: text('expenseId'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripReservation item) {
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name')
      ..maxLength(item.bookingCode, TripSectionFields.codeMax, 'bookingCode')
      ..maxLength(item.cancellationPolicy, policyMax, 'cancellationPolicy')
      ..maxLength(item.holder, TripSectionFields.shortMax, 'holder')
      ..maxLength(item.ticketCode, ticketCodeMax, 'ticketCode')
      ..maxLength(item.notes, TripSectionFields.notesMax, 'notes');
    c.check(item.place.invalid, TripSectionProblemKind.place, 'place');
    final tickets = item.ticketCount;
    c.check(
      tickets != null && (tickets < 1 || tickets > ticketsMax),
      TripSectionProblemKind.other,
      'tickets',
    );
    c.check(
      item.time != null && !TripStayDates.isValidTime(item.time),
      TripSectionProblemKind.other,
      'time',
    );
    c.check(
      item.participantUids.length > TripSectionFields.uidsMax,
      TripSectionProblemKind.members,
      'participantUids',
    );
    c.check(
      TripSectionFields.badLink(item.bookingUrl),
      TripSectionProblemKind.link,
      'bookingUrl',
    );
    c.check(
      TripSectionFields.badCost(
        item.estimatedCostMinorUnits,
        item.estimatedCostCurrency,
      ),
      TripSectionProblemKind.cost,
      'cost',
    );
    c.check(
      TripSectionFields.badExpenseId(item.expenseId),
      TripSectionProblemKind.expense,
      'expenseId',
    );
    return c.found;
  }
}

// Conversione dei trasporti da e verso Firestore (trips/{tripId}/transports)
// e controlli con gli stessi limiti di firestore.rules. I campi facoltativi
// vuoti non vengono salvati.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'trip_transport.dart';
import 'trip_transport_type.dart';

class TripTransportCodec implements TripSectionCodec<TripTransport> {
  const TripTransportCodec();

  static const textMax = TripSectionFields.shortMax;
  static final _offset = RegExp(r'^[+-](0\d|1[0-4]):(00|30|45)$');

  static bool isOffset(String? value) =>
      value != null && _offset.hasMatch(value);

  @override
  String get collection => 'transports';

  @override
  List<String> get optionalKeys => [
    ...TripSectionPlace.keys('from'),
    ...TripSectionPlace.keys('to'),
    'departureTime',
    'departureOffset',
    'arrivalDate',
    'arrivalTime',
    'arrivalOffset',
    'carrier',
    'number',
    'bookingCode',
    'seats',
    'passengerUids',
    'bookedVia',
    'bookingUrl',
    'notes',
    'estimatedCostMinorUnits',
    'estimatedCostCurrency',
    'expenseId',
  ];

  @override
  Map<String, dynamic> toMap(TripTransport item) {
    String? text(String? value) => TripSectionFields.clean(value);
    final arrival = item.arrivalDate;
    return {
      'tripId': item.tripId,
      'createdByUid': item.createdByUid,
      'type': item.type.code,
      'status': item.status.code,
      'departureDate': TripStayDates.format(item.departureDate),
      ...item.from.toMap('from'),
      ...item.to.toMap('to'),
      'departureTime': ?text(item.departureTime),
      'departureOffset': ?text(item.departureOffset),
      if (arrival != null) 'arrivalDate': TripStayDates.format(arrival),
      'arrivalTime': ?text(item.arrivalTime),
      'arrivalOffset': ?text(item.arrivalOffset),
      'carrier': ?text(item.carrier),
      'number': ?text(item.number),
      'bookingCode': ?text(item.bookingCode),
      'seats': ?text(item.seats),
      if (item.passengerUids.isNotEmpty)
        'passengerUids': List.of(item.passengerUids),
      'bookedVia': ?text(item.bookedVia),
      'bookingUrl': ?text(item.bookingUrl),
      'notes': ?text(item.notes),
      ...TripSectionFields.costMap(
        item.estimatedCostMinorUnits,
        item.estimatedCostCurrency,
      ),
      'expenseId': ?text(item.expenseId),
    };
  }

  @override
  TripTransport fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final type = TripTransportType.fromCode(data['type']);
    final status = TripBookingStatus.fromCode(data['status']);
    final departure = TripStayDates.parse(data['departureDate']);
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (type == null ||
        status == null ||
        departure == null ||
        tripId == null ||
        author == null) {
      throw FormatException('Invalid transport $id.');
    }
    final (cost, currency) = TripSectionFields.readCost(data);
    return TripTransport(
      id: id,
      tripId: tripId,
      createdByUid: author,
      type: type,
      status: status,
      departureDate: departure,
      from: TripSectionPlace.fromMap(data, 'from'),
      to: TripSectionPlace.fromMap(data, 'to'),
      departureTime: text('departureTime'),
      departureOffset: text('departureOffset'),
      arrivalDate: TripStayDates.parse(data['arrivalDate']),
      arrivalTime: text('arrivalTime'),
      arrivalOffset: text('arrivalOffset'),
      carrier: text('carrier'),
      number: text('number'),
      bookingCode: text('bookingCode'),
      seats: text('seats'),
      passengerUids: TripSectionFields.readUids(data, 'passengerUids'),
      bookedVia: text('bookedVia'),
      bookingUrl: text('bookingUrl'),
      notes: text('notes'),
      estimatedCostMinorUnits: cost,
      estimatedCostCurrency: currency,
      expenseId: text('expenseId'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripTransport item) {
    final c = TripSectionChecks();
    const other = TripSectionProblemKind.other;
    c.check(
      item.from.invalid || item.to.invalid,
      TripSectionProblemKind.place,
      'place',
    );
    final arrival = item.arrivalDate;
    c.check(
      arrival != null && TripStayDates.nights(item.departureDate, arrival) < 0,
      other,
      'arrivalBeforeDeparture',
    );
    for (final (value, field) in [
      (item.departureTime, 'departureTime'),
      (item.arrivalTime, 'arrivalTime'),
    ]) {
      c.check(value != null && !TripStayDates.isValidTime(value), other, field);
    }
    for (final (value, field) in [
      (item.departureOffset, 'departureOffset'),
      (item.arrivalOffset, 'arrivalOffset'),
    ]) {
      c.check(value != null && !isOffset(value), other, field);
    }
    for (final (value, field) in [
      (item.carrier, 'carrier'),
      (item.number, 'number'),
      (item.seats, 'seats'),
      (item.bookedVia, 'bookedVia'),
    ]) {
      c.maxLength(value, textMax, field);
    }
    c.maxLength(item.bookingCode, TripSectionFields.codeMax, 'bookingCode');
    c.maxLength(item.notes, TripSectionFields.notesMax, 'notes');
    c.check(
      item.passengerUids.length > TripSectionFields.uidsMax,
      TripSectionProblemKind.members,
      'passengerUids',
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

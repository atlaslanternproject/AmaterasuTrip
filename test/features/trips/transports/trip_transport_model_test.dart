// Test automatici del modello dei trasporti: conversione Firestore,
// controlli con i limiti delle regole, fusi orari e avvisi di coincidenza.
// Casi, ad esempio: "codec round trip keeps every field", "tight connection and overlap".

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_codec.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_timeline.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripTransportCodec();

TripTransport transport({
  String id = 't1',
  int day = 12,
  String? depTime,
  String? depOffset,
  int? arrDay,
  String? arrTime,
  String? arrOffset,
  TripBookingStatus status = TripBookingStatus.booked,
  String? url,
  int? cost,
  String? currency,
}) => TripTransport(
  id: id,
  tripId: 'trip',
  createdByUid: 'anna',
  type: TripTransportType.flight,
  status: status,
  departureDate: DateTime(2027, 4, day),
  departureTime: depTime,
  departureOffset: depOffset,
  arrivalDate: arrDay == null ? null : DateTime(2027, 4, arrDay),
  arrivalTime: arrTime,
  arrivalOffset: arrOffset,
  bookingUrl: url,
  estimatedCostMinorUnits: cost,
  estimatedCostCurrency: currency,
);

void main() {
  test('codec round trip keeps every field', () {
    final original = TripTransport(
      tripId: 'trip',
      createdByUid: 'anna',
      type: TripTransportType.train,
      status: TripBookingStatus.booked,
      departureDate: DateTime(2027, 4, 12),
      from: const TripSectionPlace(name: 'Roma', placeId: 'p1', latitude: 41),
      to: const TripSectionPlace(name: 'Firenze'),
      departureTime: '08:10',
      departureOffset: '+01:00',
      arrivalDate: DateTime(2027, 4, 12),
      arrivalTime: '09:45',
      carrier: 'Trenitalia',
      number: 'FR 9511',
      bookingCode: 'PNR1',
      seats: '5A',
      passengerUids: const ['anna'],
      bookedVia: 'App',
      bookingUrl: 'https://www.trenitalia.com',
      notes: 'Carrozza 5',
      estimatedCostMinorUnits: 2990,
      estimatedCostCurrency: 'EUR',
      expenseId: 'exp1',
    );
    final map = codec.toMap(original);
    expect(map['fromName'], 'Roma');
    expect(map['departureDate'], '2027-04-12');
    final back = codec.fromMap('x', map);
    expect(codec.toMap(back), map);
    expect(back.displayName, 'Trenitalia FR 9511 · Roma → Firenze');
  });

  test('empty optional fields are not saved; bad documents are rejected', () {
    final map = codec.toMap(transport());
    expect(map.keys.toSet(), {
      'tripId',
      'createdByUid',
      'type',
      'status',
      'departureDate',
    });
    expect(
      () => codec.fromMap('x', {...map, 'type': 'rocket'}),
      throwsFormatException,
    );
  });

  test('checks use the rules limits', () {
    expect(codec.problems(transport()), isEmpty);
    expect(
      codec.problems(transport(arrDay: 11)).single.field,
      'arrivalBeforeDeparture',
    );
    expect(
      codec.problems(transport(depOffset: '+15:00')).single.field,
      'departureOffset',
    );
    expect(
      codec.problems(transport(url: 'ftp://x')).single.kind,
      TripSectionProblemKind.link,
    );
    expect(
      codec.problems(transport(cost: 100)).single.kind,
      TripSectionProblemKind.cost,
    );
    expect(codec.problems(transport(cost: 100, currency: 'EUR')), isEmpty);
  });

  test('time zones turn local times into real instants', () {
    final flight = transport(
      depTime: '13:00',
      depOffset: '+01:00',
      arrDay: 13,
      arrTime: '09:00',
      arrOffset: '+09:00',
    );
    expect(
      TripTransportTimeline.departure(flight),
      DateTime.utc(2027, 4, 12, 12),
    );
    expect(TripTransportTimeline.arrival(flight), DateTime.utc(2027, 4, 13));
    expect(TripTransportTimeline.durationMinutes(flight), 12 * 60);
  });

  test('tight connection and arrival after the next departure', () {
    final first = transport(id: 'a', depTime: '08:00', arrTime: '10:00');
    final tight = transport(id: 'b', depTime: '10:40', arrTime: '12:00');
    final late = transport(id: 'c', depTime: '11:30', arrTime: '13:00');
    final relaxed = transport(id: 'd', depTime: '18:00', arrTime: '19:00');
    final warnings = TripTransportTimeline.warnings([
      relaxed,
      late,
      tight,
      first,
    ]);
    expect(warnings.map((w) => (w.first.id, w.second.id, w.minutes)), [
      ('a', 'b', 40),
      ('b', 'c', -30),
    ]);
    expect(warnings[1].overlaps, isTrue);

    final cancelled = transport(
      id: 'b',
      depTime: '10:40',
      arrTime: '12:00',
      status: TripBookingStatus.cancelled,
    );
    expect(
      TripTransportTimeline.warnings([first, cancelled, relaxed]),
      isEmpty,
    );
  });
}

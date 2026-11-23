// Test automatici del modello delle prenotazioni e del filtro comune delle
// sezioni: conversione Firestore, controlli, filtri e ordine per data.
// Casi, ad esempio: "codec round trip keeps every field", "filter by status, kind and date".

import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_codec.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripReservationCodec();

TripReservation reservation(
  String id, {
  String name = 'Museo',
  int? day,
  String? time,
  TripBookingStatus status = TripBookingStatus.booked,
  TripReservationCategory category = TripReservationCategory.entry,
}) => TripReservation(
  id: id,
  tripId: 'trip',
  createdByUid: 'anna',
  name: name,
  category: category,
  status: status,
  date: day == null ? null : DateTime(2027, 4, day),
  time: time,
);

void main() {
  test('codec round trip keeps every field', () {
    final original = TripReservation(
      tripId: 'trip',
      createdByUid: 'anna',
      name: 'Museo Ghibli',
      category: TripReservationCategory.tour,
      status: TripBookingStatus.booked,
      date: DateTime(2027, 4, 14),
      time: '10:00',
      place: const TripSectionPlace(name: 'Mitaka', placeId: 'p1'),
      bookingCode: 'GHB',
      bookingUrl: 'https://ghibli.jp',
      participantUids: const ['anna', 'bruno'],
      cancellationPolicy: 'Non rimborsabile',
      notes: 'Presto',
      estimatedCostMinorUnits: 1000,
      estimatedCostCurrency: 'JPY',
      expenseId: 'e1',
    );
    final map = codec.toMap(original);
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(map['placePlaceId'], 'p1');
    expect(codec.toMap(reservation('a')).keys.toSet(), {
      'tripId',
      'createdByUid',
      'name',
      'category',
      'status',
    });
  });

  test('checks: name required, limits, link and time', () {
    expect(codec.problems(reservation('a')), isEmpty);
    expect(
      codec.problems(reservation('a', name: ' ')).single.kind,
      TripSectionProblemKind.required,
    );
    expect(
      codec.problems(reservation('a', time: '25:00')).single.field,
      'time',
    );
    expect(() => codec.fromMap('x', {'name': 'x'}), throwsFormatException);
  });

  test('filter by status, kind and date; undated last', () {
    final items = [
      reservation('late', day: 20, time: '09:00'),
      reservation('none'),
      reservation('early', day: 12, time: '18:00'),
      reservation('same', day: 12, time: '08:00'),
      reservation('off', day: 13, status: TripBookingStatus.cancelled),
      reservation('tour', day: 2, category: TripReservationCategory.tour),
    ];
    List<String> ids(TripSectionFilter filter) => filter
        .apply(
          items,
          today: DateTime(2027, 4, 10),
          dayOf: (r) => r.date,
          timeOf: (r) => r.time,
          statusOf: (r) => r.status.code,
          kindOf: (r) => r.category.code,
        )
        .map((r) => r.id)
        .toList();
    expect(ids(const TripSectionFilter()), [
      'tour',
      'same',
      'early',
      'off',
      'late',
      'none',
    ]);
    expect(ids(const TripSectionFilter(when: 'past')), ['tour']);
    expect(ids(const TripSectionFilter(status: 'cancelled')), ['off']);
    expect(ids(const TripSectionFilter(kind: 'tour')), ['tour']);
    expect(ids(const TripSectionFilter(latestFirst: true)).first, 'late');
  });
}

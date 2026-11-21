// Test automatici del modello dei soggiorni (trips/stays).
// Casi, ad esempio: "codec round trip keeps every field", "check-out on the next check-in day is not an overlap".

import 'package:amaterasutrip/features/trips/stays/data/trip_stays_paths.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_codec.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:flutter_test/flutter_test.dart';

TripStay stay({
  String name = 'Hotel Kyoto',
  DateTime? checkIn,
  DateTime? checkOut,
  TripStayStatus status = TripStayStatus.booked,
  TripStayBookingPlatform? bookedVia,
  String? bookedViaOther,
  String? bookingUrl,
  String? checkInTime,
  List<String> guests = const [],
  String? expenseId,
  double? latitude,
}) => TripStay(
  id: 's1',
  tripId: 't1',
  name: name,
  checkInDate: checkIn ?? DateTime(2027, 4, 12),
  checkOutDate: checkOut ?? DateTime(2027, 4, 15),
  status: status,
  createdByUid: 'anna',
  bookedVia: bookedVia,
  bookedViaOther: bookedViaOther,
  bookingUrl: bookingUrl,
  checkInTime: checkInTime,
  guestUids: guests,
  expenseId: expenseId,
  latitude: latitude,
);

void main() {
  test('codec round trip keeps every field', () {
    final full = TripStay(
      id: 's9', tripId: 't1', name: ' Ryokan ',
      checkInDate: DateTime(2027, 4, 12), checkOutDate: DateTime(2027, 4, 15),
      status: TripStayStatus.toConfirm, createdByUid: 'anna',
      type: TripStayType.bnb,
      checkInTime: '15:00', checkOutTime: '10:30', address: 'Shijo 1',
      city: 'Kyoto', country: 'Japan', googlePlaceId: 'ChIJ1',
      latitude: 35.01, longitude: 135.76,
      bookedVia: TripStayBookingPlatform.other, bookedViaOther: 'Expedia',
      bookingUrl: 'https://example.com/b', propertyUrl: 'http://ryokan.jp',
      confirmationCode: 'ABC', notes: 'Colazione', guestUids: ['anna', 'bruno'],
      expenseId: 'exp_1',
    );
    final map = TripStayCodec.toMap(full);
    expect(map['name'], 'Ryokan');
    expect(map['checkInDate'], '2027-04-12');
    expect(map['status'], 'toConfirm');
    expect(map['bookedVia'], 'other');
    expect(map['type'], 'bnb');
    expect(map.containsKey('createdAt'), isFalse);
    final back = TripStayCodec.fromMap('s9', map);
    expect(TripStayCodec.toMap(back), map);
    expect(back.nights, 3);
  });

  test('empty optional fields are not saved', () {
    final map = TripStayCodec.toMap(stay(
      bookedVia: TripStayBookingPlatform.booking, bookedViaOther: 'ignored',
      bookingUrl: '  ', checkInTime: '',
    ));
    expect(map.keys.toSet(), {
      'tripId', 'name', 'checkInDate', 'checkOutDate', 'status',
      'createdByUid', 'bookedVia',
    });
  });

  test('documents with missing required fields are rejected', () {
    final map = TripStayCodec.toMap(stay());
    for (final key in ['name', 'checkInDate', 'status', 'tripId']) {
      expect(() => TripStayCodec.fromMap('x', {...map}..remove(key)),
          throwsFormatException, reason: key);
    }
    expect(() => TripStayCodec.fromMap('x', {...map, 'checkInDate': '2027-02-30'}),
        throwsFormatException);
  });

  test('validator uses the Firestore rules limits', () {
    expect(TripStayValidator.problems(stay()), isEmpty);
    expect(TripStayValidator.problems(stay(name: '  ')),
        [TripStayProblem.nameMissing]);
    expect(TripStayValidator.problems(stay(name: 'x' * 201)),
        [TripStayProblem.nameTooLong]);
    expect(TripStayValidator.problems(stay(checkOut: DateTime(2027, 4, 11))),
        [TripStayProblem.checkOutBeforeCheckIn]);
    expect(TripStayValidator.problems(stay(checkInTime: '25:00')),
        [TripStayProblem.checkInTimeInvalid]);
    expect(TripStayValidator.problems(
        stay(bookedVia: TripStayBookingPlatform.other)),
        [TripStayProblem.bookedViaOtherMissing]);
    expect(TripStayValidator.problems(stay(
        bookedVia: TripStayBookingPlatform.other, bookedViaOther: 'x' * 61)),
        [TripStayProblem.bookedViaOtherTooLong]);
    expect(TripStayValidator.problems(stay(bookingUrl: 'booking.com')),
        [TripStayProblem.bookingUrlInvalid]);
    expect(TripStayValidator.problems(
        stay(guests: List.generate(51, (i) => 'u$i'))),
        [TripStayProblem.tooManyGuests]);
    expect(TripStayValidator.problems(stay(expenseId: 'bad/id')),
        [TripStayProblem.expenseIdInvalid]);
    expect(TripStayValidator.problems(stay(latitude: 91)),
        [TripStayProblem.coordinatesInvalid]);
  });

  test('nights and same-day stays', () {
    expect(stay().nights, 3);
    expect(stay(checkOut: DateTime(2027, 4, 12)).nights, 0);
    expect(TripStayDates.nights(DateTime(2027, 3, 30), DateTime(2027, 4, 2)), 3);
  });

  test('check-out on the next check-in day is not an overlap', () {
    final a = stay();
    expect(a.overlaps(stay(checkIn: DateTime(2027, 4, 15),
        checkOut: DateTime(2027, 4, 18))), isFalse);
    expect(a.overlaps(stay(checkIn: DateTime(2027, 4, 14),
        checkOut: DateTime(2027, 4, 18))), isTrue);
    expect(a.overlaps(stay(checkIn: DateTime(2027, 4, 14),
        checkOut: DateTime(2027, 4, 18), status: TripStayStatus.cancelled)),
        isFalse);
  });

  test('day text and times', () {
    expect(TripStayDates.format(DateTime(2027, 1, 5)), '2027-01-05');
    expect(TripStayDates.parse('2027-01-05'), DateTime(2027, 1, 5));
    expect(TripStayDates.parse('2027-13-01'), isNull);
    expect(TripStayDates.isValidTime('09:05'), isTrue);
    expect(TripStayDates.isValidTime('9:05'), isFalse);
  });

  test('paths are scoped to the trip and reject unsafe IDs', () {
    expect(TripStaysPaths.stays('t1'), 'trips/t1/stays');
    expect(TripStaysPaths.stay('t1', 's1'), 'trips/t1/stays/s1');
    expect(() => TripStaysPaths.stay('t1', 'a/b'), throwsArgumentError);
    expect(() => TripStaysPaths.stays(' t1'), throwsArgumentError);
  });

  test('status and platform codes match firestore.rules', () {
    expect(TripStayStatus.values.map((s) => s.code),
        ['booked', 'toConfirm', 'cancelled']);
    expect(TripStayBookingPlatform.values.map((p) => p.code),
        ['booking', 'airbnb', 'propertySite', 'agency', 'other']);
    expect(TripStayStatus.cancelled.isActive, isFalse);
    expect(TripStayType.values.map((t) => t.code),
        ['hotel', 'bnb', 'apartment', 'hostel', 'camping', 'other']);
    expect(TripStayType.fromCode('villa'), isNull);
    expect(TripStayCodec.fromMap('x', {...TripStayCodec.toMap(stay()),
        'type': 'villa'}).type, isNull);
  });
}

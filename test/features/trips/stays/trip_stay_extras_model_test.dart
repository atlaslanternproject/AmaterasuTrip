// Test automatici dei campi aggiunti ai soggiorni nella 1.15.0: costo
// previsto, cancellazione gratuita, servizi inclusi e "come arrivare".
// Casi, ad esempio: "codec keeps the new fields", "cost needs a known currency".

import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_amenity.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_codec.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:flutter_test/flutter_test.dart';

TripStay stay({
  int? cost,
  String? currency,
  DateTime? cancellation,
  List<TripStayAmenity> amenities = const [],
  String? directions,
}) => TripStay(
  id: 's1',
  tripId: 't1',
  name: 'Hotel Kyoto',
  checkInDate: DateTime(2027, 4, 12),
  checkOutDate: DateTime(2027, 4, 15),
  status: TripStayStatus.booked,
  createdByUid: 'anna',
  estimatedCostMinorUnits: cost,
  estimatedCostCurrency: currency,
  freeCancellationUntil: cancellation,
  amenities: amenities,
  directions: directions,
);

void main() {
  test('codec keeps the new fields', () {
    final original = stay(
      cost: 45000,
      currency: 'EUR',
      cancellation: DateTime(2027, 4, 1),
      amenities: const [TripStayAmenity.wifi, TripStayAmenity.breakfast],
      directions: 'Bus 100',
    );
    final map = TripStayCodec.toMap(original);
    expect(map['estimatedCostMinorUnits'], 45000);
    expect(map['estimatedCostCurrency'], 'EUR');
    expect(map['freeCancellationUntil'], '2027-04-01');
    expect(map['amenities'], ['breakfast', 'wifi']);
    expect(map['directions'], 'Bus 100');

    final back = TripStayCodec.fromMap('s1', map);
    expect(back.estimatedCostMinorUnits, 45000);
    expect(back.estimatedCostCurrency, 'EUR');
    expect(back.freeCancellationUntil, DateTime(2027, 4, 1));
    expect(back.amenities, [TripStayAmenity.breakfast, TripStayAmenity.wifi]);
    expect(back.directions, 'Bus 100');
    expect(
      back.copyWith(status: TripStayStatus.cancelled).directions,
      'Bus 100',
    );
  });

  test('empty new fields are not saved', () {
    final map = TripStayCodec.toMap(stay(currency: 'EUR', directions: '  '));
    for (final key in [
      'estimatedCostMinorUnits',
      'estimatedCostCurrency',
      'freeCancellationUntil',
      'amenities',
      'directions',
    ]) {
      expect(map.containsKey(key), isFalse, reason: key);
    }
  });

  test('unknown amenities and half costs are ignored when reading', () {
    final map = TripStayCodec.toMap(stay())
      ..['amenities'] = ['wifi', 'pool', 'wifi']
      ..['estimatedCostMinorUnits'] = 100;
    final read = TripStayCodec.fromMap('s1', map);
    expect(read.amenities, [TripStayAmenity.wifi]);
    expect(read.estimatedCostMinorUnits, isNull);
  });

  test('cost needs a known currency and stays in the rules limits', () {
    List<TripStayProblem> problems(int? cost, String? currency) =>
        TripStayValidator.problems(stay(cost: cost, currency: currency));
    expect(problems(45000, 'EUR'), isEmpty);
    expect(problems(TripStayValidator.costMax, 'JPY'), isEmpty);
    expect(problems(null, 'EUR'), isEmpty);
    for (final bad in [
      (0, 'EUR'),
      (-1, 'EUR'),
      (TripStayValidator.costMax + 1, 'EUR'),
      (100, null),
      (100, 'XXX'),
    ]) {
      expect(problems(bad.$1, bad.$2), [TripStayProblem.costInvalid]);
    }
  });

  test('directions have the rules limit', () {
    final max = 'x' * TripStayValidator.directionsMax;
    expect(TripStayValidator.problems(stay(directions: max)), isEmpty);
    expect(TripStayValidator.problems(stay(directions: '${max}x')), [
      TripStayProblem.directionsTooLong,
    ]);
  });

  test('amenity codes match firestore.rules', () {
    expect(TripStayAmenity.values.map((a) => a.code), [
      'breakfast',
      'parking',
      'wifi',
      'kitchen',
    ]);
  });
}

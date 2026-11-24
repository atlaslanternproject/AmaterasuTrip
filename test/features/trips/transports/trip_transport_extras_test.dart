// Test automatici delle aggiunte v2 ai trasporti: scali dallo stesso codice
// di prenotazione, apertura del check-in, ora per l'aeroporto, link dello
// stato del volo, conversione di "extras", card ed editor.
// Casi, ad esempio: "layover from the same booking code", "card shows check-in and airport time".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_codec.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_extras.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_schedule.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripTransport leg(
  String id, {
  String dep = '10:00',
  String arr = '12:00',
  String? code = 'PNR1',
  String to = 'Doha',
  TripTransportExtras extras = const TripTransportExtras(),
  List<String> passengers = const [],
}) => TripTransport(
  id: id,
  tripId: 't1',
  createdByUid: 'anna',
  type: TripTransportType.flight,
  status: TripBookingStatus.booked,
  departureDate: DateTime(2027, 4, 12),
  departureTime: dep,
  arrivalTime: arr,
  bookingCode: code,
  number: 'QR 132',
  to: TripSectionPlace(name: to),
  passengerUids: passengers,
  extras: extras,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('layover from the same booking code', () {
    final layovers = TripTransportSchedule.layovers([
      leg('b', dep: '14:30', arr: '20:00', to: 'Tokyo'),
      leg('a'),
      leg('c', dep: '15:00', code: 'OTHER'),
    ]);
    expect(layovers.keys, ['b']);
    expect(layovers['b']!.minutes, 150);
    expect(layovers['b']!.place, 'Doha');
  });

  test('check-in, airport time and tracking link for flights', () {
    final flight = leg('a', dep: '01:00');
    expect(
      TripTransportSchedule.checkInOpens(flight),
      DateTime.utc(2027, 4, 11, 1),
    );
    expect(TripTransportSchedule.airportBy(flight), '23:00');
    expect(
      TripTransportSchedule.trackingUrl(flight),
      'https://www.flightaware.com/live/flight/QR132',
    );
    final custom = leg(
      'b',
      extras: const TripTransportExtras(
        checkInHoursBefore: 48,
        airportMinutesBefore: 90,
      ),
    );
    expect(TripTransportSchedule.airportBy(custom), '08:30');
    expect(
      TripTransportSchedule.checkInOpens(custom),
      DateTime.utc(2027, 4, 10, 10),
    );
  });

  test('extras are saved together and checked', () {
    const codec = TripTransportCodec();
    final item = leg(
      'a',
      extras: const TripTransportExtras(
        seats: {'anna': TripTransportSeat(letter: 'C', seat: '23A')},
        checkInUrl: 'https://qatar.com/checkin',
        fuelPolicy: 'Pieno-pieno',
      ),
    );
    final map = codec.toMap(item);
    expect(map['extras'], {
      'seatsByPassenger': {
        'anna': {'letter': 'C', 'seat': '23A'},
      },
      'checkInUrl': 'https://qatar.com/checkin',
      'fuelPolicy': 'Pieno-pieno',
    });
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(codec.toMap(leg('b')).containsKey('extras'), isFalse);
    expect(
      codec
          .problems(
            leg(
              'c',
              extras: const TripTransportExtras(checkInHoursBefore: 200),
            ),
          )
          .single
          .field,
      'checkInHours',
    );
  });

  testWidgets('card shows layover, seats, check-in and airport time', (
    tester,
  ) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripTransport>(
      items: [
        leg(
          'a',
          passengers: const ['bruno'],
          extras: const TripTransportExtras(
            seats: {'bruno': TripTransportSeat(letter: 'C', seat: '23A')},
          ),
        ),
        leg('b', dep: '14:30', arr: '20:00', to: 'Tokyo'),
      ],
    );
    await tester.pumpWidget(
      sectionsTestApp(
        TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [tripTransportsStoreProvider.overrideWithValue(store)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transport-layover-b')), findsOneWidget);
    expect(find.text('Scalo di 2 h 30 min a Doha'), findsOneWidget);
    expect(find.text('Posti: Bruno C · 23A'), findsOneWidget);
    expect(find.textContaining('Check-in apre tra'), findsNWidgets(2));
    expect(find.text('Arriva in aeroporto entro le 08:00'), findsOneWidget);
    expect(find.text('Stato del volo'), findsNWidgets(2));
  });

  testWidgets('editor saves the seat of a passenger', (tester) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripTransport>();
    await tester.pumpWidget(
      sectionsTestApp(
        TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [tripTransportsStoreProvider.overrideWithValue(store)],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'transport-add');
    await tapKey(tester, 'transport-passenger-bruno');
    await tester.tap(find.text('Posti, check-in e noleggio'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transport-seat-number-bruno')),
      '12F',
    );
    await tester.enterText(
      find.byKey(const Key('transport-checkin-hours')),
      '30',
    );
    await tapKey(tester, 'transport-save');
    final saved = store.created.single;
    expect(saved.extras.seats['bruno']!.seat, '12F');
    expect(saved.extras.checkInHoursBefore, 30);
  });
}

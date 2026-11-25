// Test del calendario .ics (tappa 3a): righe CRLF, testi protetti, righe
// lunghe spezzate a 75 byte; orari con scarto salvato e con fuso (in UTC),
// senza fuso (ora locale), senza ora (giornata intera); alloggi dal
// check-in al check-out; annullati esclusi; pagina con scelta e download.

import 'dart:convert';

import 'package:amaterasutrip/core/widgets/buttons/amaterasu_primary_button.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_export_data.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_export_page.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_ics_events.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_ics_writer.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/l10n/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart' show testStay;

String? tokyo(String zone, DateTime day) =>
    zone == 'Asia/Tokyo' ? '+09:00' : null;

final events = TripIcsEvents(AppLocalizationsIt(), offsetOf: tokyo);

final flight = TripTransport(
  id: 'f1',
  tripId: 't1',
  createdByUid: 'anna',
  type: TripTransportType.flight,
  status: TripBookingStatus.booked,
  carrier: 'ITA',
  number: 'AZ784',
  from: const TripSectionPlace(name: 'Roma Fiumicino'),
  to: const TripSectionPlace(name: 'Tokyo Haneda'),
  departureDate: DateTime(2027, 4, 10),
  departureTime: '13:30',
  departureOffset: '+02:00',
  arrivalDate: DateTime(2027, 4, 11),
  arrivalTime: '09:00',
  arrivalOffset: '+09:00',
  bookingCode: 'XK42P',
);

final data = TripExportData(
  stays: [
    testStay('s1', day: 11, nights: 3),
    testStay('s2', name: 'Annullato', status: TripStayStatus.cancelled),
  ],
  transports: [flight],
  reservations: [
    TripReservation(
      id: 'r1',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'teamLab',
      category: TripReservationCategory.ticket,
      date: DateTime(2027, 4, 12),
      time: '18:00',
      zone: 'Asia/Tokyo',
    ),
  ],
  restaurants: [
    TripRestaurant(
      id: 'k1',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'Sushi Dai',
      reservationDate: DateTime(2027, 4, 13),
    ),
  ],
);

void main() {
  test('times: saved offset and zone in UTC, else local, else all day', () {
    String line(TripIcsTime? t) => TripIcsWriter.time('DTSTART', t!);
    expect(
      line(events.at(DateTime(2027, 4, 10), '13:30', offset: '+02:00')),
      'DTSTART:20270410T113000Z',
    );
    expect(
      line(events.at(DateTime(2027, 4, 10), '20:00', offset: '-05:00')),
      'DTSTART:20270411T010000Z',
    );
    expect(
      line(events.at(DateTime(2027, 4, 12), '08:00', zone: 'Asia/Tokyo')),
      'DTSTART:20270411T230000Z',
    );
    expect(
      line(events.at(DateTime(2027, 4, 12), '08:00', zone: 'Mars/Base')),
      'DTSTART:20270412T080000',
    );
    expect(
      line(events.at(DateTime(2027, 4, 12), null)),
      'DTSTART;VALUE=DATE:20270412',
    );
    expect(events.at(null, '08:00'), isNull);
  });

  test('events: stays as whole days, cancelled left out, flight end', () {
    final stays = events.stays(data.stays);
    expect(stays.single.summary, 'Hotel Kyoto');
    expect(
      TripIcsWriter.time('DTEND', stays.single.end),
      'DTEND;VALUE=DATE:20270414',
    );
    final f = events.transports([flight]).single;
    expect(f.summary, contains('AZ784'));
    expect(f.summary, contains('Roma Fiumicino → Tokyo Haneda'));
    expect(TripIcsWriter.time('DTEND', f.end), 'DTEND:20270411T000000Z');
    expect(f.description, 'Codice di prenotazione: XK42P');
    expect(
      events.transports([
        TripTransport(
          id: 'x',
          tripId: 't1',
          createdByUid: 'anna',
          type: TripTransportType.bus,
          status: TripBookingStatus.cancelled,
          departureDate: DateTime(2027, 4, 10),
        ),
      ]),
      isEmpty,
    );
    // A restaurant without time: one whole day.
    final r = events.restaurants(data.restaurants).single;
    expect(TripIcsWriter.time('DTEND', r.end), 'DTEND;VALUE=DATE:20270414');
  });

  test('file: CRLF, escaped texts, lines of at most 75 bytes', () {
    final text = TripIcsWriter.write(
      name: 'Giappone, primavera; 2027',
      events: [
        TripIcsEvent(
          uid: 'a@amaterasutrip',
          summary: 'Città ' * 30,
          start: TripIcsTime.day(DateTime.utc(2027, 4, 10)),
          end: TripIcsTime.day(DateTime.utc(2027, 4, 11)),
          description: 'riga 1\nriga 2',
        ),
      ],
      now: DateTime.utc(2027, 1, 1),
    );
    expect(text, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(text, endsWith('END:VCALENDAR\r\n'));
    expect(text, contains(r'X-WR-CALNAME:Giappone\, primavera\; 2027'));
    expect(text, contains(r'DESCRIPTION:riga 1\nriga 2'));
    for (final line in text.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
    }
    // Unfolding gives back the whole title.
    expect(text.replaceAll('\r\n ', ''), contains('SUMMARY:${'Città ' * 30}'));
  });

  testWidgets('page: choose categories and download', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bigWindow(tester);
    final files = <(String, String)>[];
    await tester.pumpWidget(
      sectionsTestApp(
        TripExportPage(
          tripId: 't1',
          offsetOf: tokyo,
          download: (name, mime, text) {
            files.add((name, text));
            return true;
          },
        ),
        overrides: [
          tripExportLoaderProvider.overrideWithValue((id) async => data),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'export-ics-stays');
    await tapKey(tester, 'export-ics-download');
    expect(find.text('3 eventi nel calendario'), findsOneWidget);
    final text = files.single.$2;
    expect(files.single.$1, endsWith('.ics'));
    expect(text, isNot(contains('Hotel Kyoto')));
    expect(text, contains('SUMMARY:teamLab'));
    expect(text, contains('DTSTART:20270412T090000Z'));

    for (final c in ['transports', 'reservations', 'restaurants']) {
      await tapKey(tester, 'export-ics-$c');
    }
    expect(
      tester
          .widget<AmaterasuPrimaryButton>(find.byType(AmaterasuPrimaryButton))
          .onPressed,
      isNull,
    );
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    bigWindow(tester, width: 390);
    await tester.pumpWidget(
      sectionsTestApp(const TripExportPage(tripId: 't1'), overrides: const []),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

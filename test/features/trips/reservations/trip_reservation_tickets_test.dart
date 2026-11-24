// Test automatici delle aggiunte v2 alle prenotazioni: scadenza "da
// prenotare entro il" (in rosso negli ultimi 3 giorni), intestatario,
// numero di biglietti, biglietto QR a schermo intero ed editor.
// Casi, ad esempio: "book-by chip turns red in the last 3 days", "ticket opens full screen".

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_codec.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripReservation booking(
  String id, {
  TripBookingStatus status = TripBookingStatus.toBook,
  DateTime? bookBy,
  String? ticketCode,
}) => TripReservation(
  id: id,
  tripId: 't1',
  createdByUid: 'anna',
  name: 'Museo $id',
  category: TripReservationCategory.tour,
  status: status,
  bookBy: bookBy,
  holder: 'Yato',
  ticketCount: 2,
  ticketCode: ticketCode,
);

Future<FakeSectionStore<TripReservation>> open(
  WidgetTester tester,
  List<TripReservation> items,
) async {
  bigWindow(tester);
  final store = FakeSectionStore<TripReservation>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      TripBookingsPage(tripId: 't1', today: DateTime(2027, 4, 1)),
      overrides: [tripReservationsStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Color chipColor(WidgetTester tester, String key) =>
    tester.widget<TripSectionChip>(find.byKey(Key(key))).color;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('new fields are saved and checked', () {
    const codec = TripReservationCodec();
    final item = booking('a', bookBy: DateTime(2027, 3, 1), ticketCode: 'X1');
    final map = codec.toMap(item);
    expect(map['bookBy'], '2027-03-01');
    expect(map['holder'], 'Yato');
    expect(map['ticketCount'], 2);
    expect(codec.toMap(codec.fromMap('a', map)), map);
    final bad = TripReservation(
      id: 'b',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'x',
      category: TripReservationCategory.tour,
      ticketCount: 100,
    );
    expect(codec.problems(bad).single.field, 'tickets');
  });

  testWidgets('book-by chip turns red in the last 3 days', (tester) async {
    await open(tester, [
      booking('soon', bookBy: DateTime(2027, 4, 3)),
      booking('later', bookBy: DateTime(2027, 5, 1)),
      booking(
        'done',
        status: TripBookingStatus.booked,
        bookBy: DateTime(2027, 4, 2),
      ),
    ]);
    expect(
      chipColor(tester, 'reservation-book-by-soon'),
      AmaterasuColors.error,
    );
    expect(
      chipColor(tester, 'reservation-book-by-later'),
      AmaterasuColors.accentGold,
    );
    // Once booked the deadline is no longer shown.
    expect(find.byKey(const Key('reservation-book-by-done')), findsNothing);
    expect(find.text('Intestatario: Yato'), findsNWidgets(3));
    expect(find.text('2 biglietti'), findsNWidgets(3));
  });

  testWidgets('ticket opens full screen as a QR code', (tester) async {
    await open(tester, [booking('a', ticketCode: 'GHB-001'), booking('b')]);
    expect(find.byKey(const Key('reservation-ticket-b')), findsNothing);
    await tapKey(tester, 'reservation-ticket-a');
    expect(find.byKey(const Key('reservation-ticket-view-a')), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('GHB-001'), findsOneWidget);
    await tapKey(tester, 'reservation-ticket-close');
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('editor saves holder, tickets, code and book-by day', (
    tester,
  ) async {
    final store = await open(tester, const []);
    await tapKey(tester, 'reservation-add');
    await tester.enterText(find.byKey(const Key('reservation-name')), 'Tour');
    expect(find.byKey(const Key('reservation-book-by')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('reservation-holder')), 'Yato');
    await tester.enterText(find.byKey(const Key('reservation-tickets')), '3');
    await tester.enterText(
      find.byKey(const Key('reservation-ticket-code')),
      'ABC',
    );
    await tapKey(tester, 'reservation-save');
    final saved = store.created.single;
    expect(saved.holder, 'Yato');
    expect(saved.ticketCount, 3);
    expect(saved.ticketCode, 'ABC');
  });
}

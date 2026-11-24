// Test automatici della pagina Prenotazioni: creazione con l'editor (nome
// obbligatorio), luogo Google con foto, tre viste, filtri per categoria,
// spesa collegata (categoria attività) ed eliminazione.
// Casi, ad esempio: "a name is required", "Crea spesa starts as an activity expense".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripReservation reservation(
  String id, {
  String createdBy = 'anna',
  TripReservationCategory category = TripReservationCategory.entry,
  String? placeId,
}) => TripReservation(
  id: id,
  tripId: 't1',
  createdByUid: createdBy,
  name: 'Museo $id',
  category: category,
  status: TripBookingStatus.booked,
  date: DateTime(2027, 4, 14),
  time: '10:00',
  place: TripSectionPlace(name: 'Mitaka', placeId: placeId),
  cancellationPolicy: 'Non rimborsabile',
);

Future<FakeSectionStore<TripReservation>> open(
  WidgetTester tester, {
  List<TripReservation> items = const [],
  String uid = 'anna',
  double width = 1000,
}) async {
  bigWindow(tester, width: width);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  final store = FakeSectionStore<TripReservation>(uid: uid, items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      TripBookingsPage(tripId: 't1', today: DateTime(2027, 4, 1)),
      overrides: [tripReservationsStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a name is required, then the booking is saved', (tester) async {
    final store = await open(tester);
    expect(find.byKey(const Key('reservation-empty')), findsOneWidget);
    await tapKey(tester, 'reservation-add');
    await tapKey(tester, 'reservation-save');
    expect(find.text('Compila il campo «Nome».'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('reservation-name')),
      'Museo Ghibli',
    );
    await tapKey(tester, 'reservation-category-tour');
    await tapKey(tester, 'reservation-status-booked');
    await tester.enterText(
      find.byKey(const Key('reservation-place-search')),
      'granvia',
    );
    await tapKey(tester, 'reservation-place-search-go');
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'reservation-participant-bruno');
    await tester.enterText(
      find.byKey(const Key('reservation-policy')),
      'Gratis 24h',
    );
    await tapKey(tester, 'reservation-save');
    final item = store.created.single;
    expect(item.name, 'Museo Ghibli');
    expect(item.category, TripReservationCategory.tour);
    expect(item.status, TripBookingStatus.booked);
    expect(item.place.placeId, 'ChIJ-kyoto');
    expect(item.participantUids, ['bruno']);
    expect(item.cancellationPolicy, 'Gratis 24h');
  });

  testWidgets('card with photo placeholder, policy and three views', (
    tester,
  ) async {
    await open(tester, items: [reservation('a', placeId: 'p1')]);
    expect(find.byKey(const Key('reservation-card-a')), findsOneWidget);
    expect(find.text('Cancellazione: Non rimborsabile'), findsOneWidget);
    for (final (label, key) in [
      ('Elenco', 'reservation-compact-a'),
      ('Dettagli', 'reservation-row-a'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('reservation-view')),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key(key)), findsOneWidget);
      expect(find.byKey(const Key('reservation-quick-map-a')), findsOneWidget);
    }
  });

  testWidgets('filter by category', (tester) async {
    await open(
      tester,
      items: [
        reservation('a'),
        reservation('b', category: TripReservationCategory.tour),
      ],
    );
    await pickFilter(tester, 'reservation', 'reservation-filter-kind-tour');
    expect(find.byKey(const Key('reservation-card-b')), findsOneWidget);
    expect(find.byKey(const Key('reservation-card-a')), findsNothing);
  });

  testWidgets('Crea spesa starts as an activity expense', (tester) async {
    await open(tester, items: [reservation('a')]);
    await tapKey(tester, 'reservation-expense-create-a');
    final dialog = tester.widget<BudgetCreateDialog>(
      find.byType(BudgetCreateDialog),
    );
    expect(dialog.initialCategory, 'activities');
    expect(dialog.initialTitle, 'Museo a');
  });

  testWidgets('another member cannot delete; the creator can', (tester) async {
    final store = await open(
      tester,
      uid: 'bruno',
      items: [
        reservation('a'),
        reservation('b', createdBy: 'bruno'),
      ],
    );
    expect(find.byKey(const Key('reservation-menu-a')), findsNothing);
    await tapKey(tester, 'reservation-menu-b');
    await tester.tap(find.byKey(const Key('reservation-delete-b')));
    await tester.pumpAndSettle();
    // Two steps: destructive actions are confirmed twice.
    await tapKey(tester, 'reservation-delete-ok');
    expect(
      find.text('Sei sicuro? Questa azione non si può annullare.'),
      findsOneWidget,
    );
    await tapKey(tester, 'reservation-delete-ok');
    expect(store.deleted.single.id, 'b');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, items: [reservation('a')]);
    await tapKey(tester, 'reservation-add');
    expect(tester.takeException(), isNull);
  });
}

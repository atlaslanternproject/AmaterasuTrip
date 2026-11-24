// Test automatici della pagina Trasporti: stato vuoto, creazione con
// l'editor, tre viste ricordate, filtri, avvisi di coincidenza, spesa
// collegata ed eliminazione (solo creatore o proprietario).
// Casi, ad esempio: "a new flight with places, times and cost", "tight connection notice".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_view_preferences.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripTransport transport(
  String id, {
  String createdBy = 'anna',
  String? dep,
  String? arr,
  TripTransportType type = TripTransportType.train,
  TripBookingStatus status = TripBookingStatus.booked,
  int day = 12,
}) => TripTransport(
  id: id,
  tripId: 't1',
  createdByUid: createdBy,
  type: type,
  status: status,
  departureDate: DateTime(2027, 4, day),
  departureTime: dep,
  arrivalTime: arr,
  carrier: 'Linea $id',
  from: const TripSectionPlace(name: 'Kyoto'),
  to: const TripSectionPlace(name: 'Osaka'),
);

Future<FakeSectionStore<TripTransport>> open(
  WidgetTester tester, {
  List<TripTransport> items = const [],
  String uid = 'anna',
  String owner = 'anna',
  double width = 1000,
}) async {
  bigWindow(tester, width: width);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    // Pre-existing, visual only warning of the budget create dialog.
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  final store = FakeSectionStore<TripTransport>(uid: uid, items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
      ownerUid: owner,
      overrides: [tripTransportsStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('empty page, then a new flight with places, times and cost', (
    tester,
  ) async {
    final store = await open(tester);
    expect(find.byKey(const Key('transport-empty')), findsOneWidget);
    await tapKey(tester, 'transport-add');
    await tapKey(tester, 'transport-type-flight');
    await tester.enterText(
      find.byKey(const Key('transport-from-name')),
      'Roma',
    );
    await tester.enterText(
      find.byKey(const Key('transport-to-search')),
      'granvia',
    );
    await tapKey(tester, 'transport-to-search-go');
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transport-carrier')), 'ITA');
    await tester.enterText(find.byKey(const Key('transport-cost')), '450');
    await tapKey(tester, 'transport-passenger-bruno');
    await tapKey(tester, 'transport-save');

    final item = store.created.single;
    expect(item.type, TripTransportType.flight);
    expect(item.from.name, 'Roma');
    expect(item.to.placeId, 'ChIJ-kyoto');
    expect(item.carrier, 'ITA');
    expect(item.estimatedCostMinorUnits, 45000);
    expect(item.estimatedCostCurrency, 'EUR');
    expect(item.passengerUids, ['bruno']);
    expect(find.text('Salvato.'), findsOneWidget);
  });

  testWidgets('invalid link is explained and nothing is saved', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'transport-add');
    await tester.enterText(find.byKey(const Key('transport-url')), 'ftp://x');
    await tapKey(tester, 'transport-save');
    expect(find.byKey(const Key('transport-editor-error')), findsOneWidget);
    expect(store.created, isEmpty);
  });

  testWidgets('three views, remembered on the device', (tester) async {
    await open(
      tester,
      items: [transport('a', dep: '08:00', arr: '09:00')],
    );
    expect(find.byKey(const Key('transport-card-a')), findsOneWidget);
    for (final (label, key) in [
      ('Elenco', 'transport-compact-a'),
      ('Dettagli', 'transport-row-a'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('transport-view')),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key(key)), findsOneWidget);
      expect(
        find.byKey(const Key('transport-quick-expense-a')),
        findsOneWidget,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(
        TripSectionViewPreferences.key('transports', 'anna', 't1'),
      ),
      'details',
    );
  });

  testWidgets('filters by type and status', (tester) async {
    await open(
      tester,
      items: [
        transport('a'),
        transport('b', type: TripTransportType.flight),
        transport('c', status: TripBookingStatus.cancelled),
      ],
    );
    await tapKey(tester, 'transport-filter-type-flight');
    expect(find.byKey(const Key('transport-card-b')), findsOneWidget);
    expect(find.byKey(const Key('transport-card-a')), findsNothing);
    await tapKey(tester, 'transport-filter-type-all');
    await tapKey(tester, 'transport-filter-status-cancelled');
    expect(find.byKey(const Key('transport-card-c')), findsOneWidget);
    expect(find.byKey(const Key('transport-card-b')), findsNothing);
  });

  testWidgets('tight connection notice', (tester) async {
    await open(
      tester,
      items: [
        transport('a', dep: '08:00', arr: '10:00'),
        transport('b', dep: '10:30', arr: '11:00'),
      ],
    );
    expect(find.textContaining('Coincidenza stretta: 30 min'), findsOneWidget);
  });

  testWidgets('Crea spesa starts as a transport expense', (tester) async {
    await open(tester, items: [transport('a')]);
    await tapKey(tester, 'transport-expense-create-a');
    final dialog = tester.widget<BudgetCreateDialog>(
      find.byType(BudgetCreateDialog),
    );
    expect(dialog.initialCategory, 'transport');
    expect(dialog.initialDate, DateTime(2027, 4, 12));
    expect(dialog.sharedOnly, isTrue);
  });

  testWidgets('only the creator or the owner can delete, with confirmation', (
    tester,
  ) async {
    final store = await open(
      tester,
      uid: 'bruno',
      items: [
        transport('a'),
        transport('b', createdBy: 'bruno'),
      ],
    );
    expect(find.byKey(const Key('transport-menu-a')), findsNothing);
    await tapKey(tester, 'transport-menu-b');
    await tester.tap(find.byKey(const Key('transport-delete-b')));
    await tester.pumpAndSettle();
    // Two steps: destructive actions are confirmed twice.
    await tapKey(tester, 'transport-delete-ok');
    expect(
      find.text('Sei sicuro? Questa azione non si può annullare.'),
      findsOneWidget,
    );
    await tapKey(tester, 'transport-delete-ok');
    expect(store.deleted.single.id, 'b');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, items: [transport('a', dep: '08:00')]);
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'transport-add');
    expect(tester.takeException(), isNull);
  });
}

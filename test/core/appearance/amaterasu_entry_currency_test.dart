// Test automatici della valuta per le nuove voci (Extra E6): con una valuta
// scelta in Aspetto l'editor di un trasporto nuovo parte da quella; "Crea
// spesa" su una voce senza costo parte da quella, su una voce con costo
// resta la valuta del costo (importo e calcoli invariati).
// Casi, ad esempio: "new entry starts in the chosen currency".

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/trips/sections/support/fake_section_store.dart';
import 'amaterasu_appearance_test.dart' show FakeAppearanceStore;

TripTransport leg(String id, {int? cost, String? currency}) => TripTransport(
  id: id,
  tripId: 't1',
  createdByUid: 'anna',
  type: TripTransportType.train,
  status: TripBookingStatus.booked,
  departureDate: DateTime(2027, 4, 12),
  estimatedCostMinorUnits: cost,
  estimatedCostCurrency: currency,
);

Future<FakeSectionStore<TripTransport>> open(
  WidgetTester tester,
  List<TripTransport> items,
) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester);
  // Pre-existing visual warning of the expense dialog, tolerated as in the
  // other budget tests.
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  final store = FakeSectionStore<TripTransport>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
      overrides: [
        tripTransportsStoreProvider.overrideWithValue(store),
        amaterasuAppearanceStoreProvider.overrideWithValue(
          FakeAppearanceStore(
            const AmaterasuAppearance(defaultCurrency: 'USD'),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('a new entry starts in the chosen currency', (tester) async {
    final store = await open(tester, const []);
    await tapKey(tester, 'transport-add');
    await tester.enterText(find.byKey(const Key('transport-cost')), '20');
    await tapKey(tester, 'transport-save');
    expect(store.created.single.estimatedCostCurrency, 'USD');
  });

  testWidgets('Crea spesa: chosen currency without a cost, else the cost one', (
    tester,
  ) async {
    await open(tester, [leg('a'), leg('b', cost: 12000, currency: 'JPY')]);
    await tapKey(tester, 'transport-expense-create-a');
    expect(
      tester
          .widget<BudgetCreateDialog>(find.byType(BudgetCreateDialog))
          .currency,
      'USD',
    );
    Navigator.of(tester.element(find.byType(BudgetCreateDialog))).pop();
    await tester.pumpAndSettle();
    await tapKey(tester, 'transport-expense-create-b');
    final dialog = tester.widget<BudgetCreateDialog>(
      find.byType(BudgetCreateDialog),
    );
    expect((dialog.currency, dialog.initialMinorUnits), ('JPY', 12000));
  });
}

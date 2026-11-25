// Test automatico della valuta del costo previsto di un trasporto con il
// selettore comune del budget, usando una lista di valute finta al posto
// di quella di Google (così il test non va in rete).
// Casi, ad esempio: "the cost currency is chosen from the shared sheet".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_currency_choice.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    budgetCurrencyFetch = (_) async => const [
      TripCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
      TripCurrency(code: 'JPY', name: 'Yen giapponese', symbol: '¥'),
    ];
  });

  testWidgets('the cost currency is chosen from the shared sheet', (
    tester,
  ) async {
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
    await tapKey(tester, 'transport-cost-currency');
    expect(find.text('Yen giapponese'), findsOneWidget);
    await tester.tap(find.text('JPY'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transport-cost')), '12000');
    await tapKey(tester, 'transport-save');
    final saved = store.created.single;
    expect(saved.estimatedCostCurrency, 'JPY');
    expect(saved.estimatedCostMinorUnits, 12000);
  });
}

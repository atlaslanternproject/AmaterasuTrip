// Test automatici di "Converti" (nuova tappa 1): calcoli di unità, taglie
// e mancia; pagina con un tasso finto (stesso percorso del budget), cambio
// delle unità e della mancia; nessun errore di spazio al 130 % su telefono.
// Casi, ad esempio: "100 EUR with a fake rate", "tip for three people".

import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/tools/convert/trip_convert_math.dart';
import 'package:amaterasutrip/features/trips/tools/convert/trip_convert_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

Future<BudgetFxQuote> fakeRate(String from, String to) async => BudgetFxQuote(
  base: from,
  quote: to,
  rate: 1.1,
  observedDate: DateTime(2027, 4, 10),
  requestedDate: null,
  source: 'Frankfurter',
);

Future<void> open(WidgetTester tester, {double width = 1000}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  await tester.pumpWidget(
    sectionsTestApp(
      TripConvertPage(tripId: 't1', loader: fakeRate),
      overrides: const [],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('units, sizes and tip', () {
    expect(TripConvertMath.celsiusToFahrenheit(20), 68);
    expect(TripConvertMath.show(TripConvertMath.kmToMiles(10)), '6.21');
    expect(TripConvertMath.show(TripConvertMath.poundsToKg(10)), '4.54');
    expect(TripConvertMath.shoes.first.eu, 36);
    final t = TripConvertMath.tip(60, 10, 3);
    expect((t.tip, t.total, t.each), (6.0, 66.0, 22.0));
    expect(TripConvertMath.parse('12,5'), 12.5);
  });

  testWidgets('currency with the budget rate path', (tester) async {
    await open(tester);
    final result = tester.widget<Text>(find.byKey(const Key('convert-result')));
    expect(result.data, contains('110'));
    expect(find.textContaining('Frankfurter'), findsOneWidget);
  });

  testWidgets('units and tip change with the inputs', (tester) async {
    await open(tester);
    await tester.tap(find.text('Unità di misura'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'convert-unit-km-mi');
    await tester.enterText(find.byKey(const Key('convert-unit-value')), '10');
    await tester.pumpAndSettle();
    expect(find.text('10 km = 6.21 mi'), findsOneWidget);
    await tester.tap(find.text('Mancia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('convert-tip-people')), '3');
    await tester.enterText(find.byKey(const Key('convert-tip-bill')), '60');
    await tester.pumpAndSettle();
    expect(find.textContaining('22 EUR a testa'), findsOneWidget);
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, width: 390);
    expect(tester.takeException(), isNull);
  });
}

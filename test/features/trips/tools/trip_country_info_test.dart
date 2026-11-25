// Test automatici di "Info paese" (nuova tappa 1c): il file generato da
// tool/build_country_info.mjs ha fonte, licenza e data e dati sensati per
// l'Italia; la pagina parte dal paese del viaggio, mostra fonte su ogni
// voce, nasconde le voci senza dati, cambia paese, ha l'avviso e i link
// ufficiali; nessun errore di spazio al 130 % su telefono.

import 'dart:io';

import 'package:amaterasutrip/features/trips/tools/country_info/trip_country_info_data.dart';
import 'package:amaterasutrip/features/trips/tools/country_info/trip_country_info_entries.dart';
import 'package:amaterasutrip/features/trips/tools/country_info/trip_country_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

const fakeFile = '''
{"source": {"name": "Wikidata", "licence": "CC0 1.0"},
 "generated": "2026-11-25",
 "countries": {
  "JP": {"iso3": "JPN", "wikidata": "Q17",
   "name": {"it": "Giappone", "en": "Japan"}, "callingCode": ["+81"],
   "emergency": ["110", "119"], "plugs": ["A", "B"], "voltage": ["100"],
   "driving": "left", "timeZones": ["Asia/Tokyo"]},
  "XK": {"name": {"it": "Kosovo", "en": "Kosovo"}, "plugs": ["BS 546"]}
 }}''';

Future<void> open(WidgetTester tester, {double width = 1000}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripCountryInfoPage(tripId: 't1'),
      overrides: [
        tripCountryCodeProvider('t1').overrideWith((ref) => 'JP'),
        tripCountryInfoBookProvider.overrideWith(
          (ref) async => TripCountryInfoBook.fromJson(fakeFile),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the generated file: source, licence, date and Italy', () {
    final book = TripCountryInfoBook.fromJson(
      File(tripCountryInfoAsset).readAsStringSync(),
    );
    expect(book.source, 'Wikidata');
    expect(book.licence, 'CC0 1.0');
    expect(book.generated, isNotNull);
    expect(book.countries.length, greaterThan(150));
    final it = book.countries['IT']!;
    expect(it.iso3, 'ITA');
    expect(it.callingCode, ['+39']);
    expect(it.emergency, contains('112'));
    expect(it.plugs, containsAll(['C', 'F', 'L']));
    expect(it.driving, 'right');
    expect(book.countries['GB']!.driving, 'left');
    for (final c in book.countries.values) {
      expect(c.name('it'), isNotEmpty, reason: c.code);
    }
  });

  test('official link uses the ISO alpha-3 code', () {
    expect(
      tripCountryViaggiareSicuri('JPN'),
      'https://www.viaggiaresicuri.it/find-country/country/JPN',
    );
  });

  testWidgets('trip country first, source on every entry', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('country-info-verify')), findsOneWidget);
    expect(find.text('+81'), findsOneWidget);
    expect(find.text('110 · 119'), findsOneWidget);
    expect(find.text('Tipo A, B'), findsOneWidget);
    expect(find.text('100 V'), findsOneWidget);
    expect(find.text('Si guida a sinistra'), findsOneWidget);
    expect(find.textContaining('Fonte: Wikidata (CC0 1.0)'), findsNWidgets(6));
    expect(find.byKey(const Key('country-info-vs')), findsOneWidget);
    expect(find.byKey(const Key('country-info-consulate')), findsOneWidget);
  });

  testWidgets('another country: entries without data are hidden', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('country-info-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kosovo').last);
    await tester.pumpAndSettle();
    expect(find.text('BS 546'), findsOneWidget);
    expect(find.byKey(const Key('country-info-calling')), findsNothing);
    expect(find.byKey(const Key('country-info-driving')), findsNothing);
    expect(find.textContaining('Fonte: Wikidata'), findsOneWidget);
    // No ISO alpha-3: no Viaggiare Sicuri link, the consulate link stays.
    expect(find.byKey(const Key('country-info-vs')), findsNothing);
    expect(find.byKey(const Key('country-info-consulate')), findsOneWidget);
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, width: 390);
    expect(tester.takeException(), isNull);
  });
}

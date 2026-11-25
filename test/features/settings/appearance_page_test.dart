// Test automatici della pagina "Aspetto" (Extra E2): ogni scelta si salva
// subito nel profilo (archivio finto), la valuta di visualizzazione mostra
// quella predefinita quando non è scelta e si torna al valore automatico
// con la ×; frase introduttiva e card come Privacy (COERENZA F), a tutta
// larghezza su schermo largo e senza errori di spazio al 130 % su telefono.
// Casi, ad esempio: "choices are saved at once", "display currency follows the default".

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/appearance/appearance_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/amaterasu_appearance_test.dart'
    show FakeAppearanceStore;

Future<FakeAppearanceStore> open(
  WidgetTester tester, [
  AmaterasuAppearance? remote,
  double width = 900,
]) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = FakeAppearanceStore(remote);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [amaterasuAppearanceStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(
        locale: Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AppearancePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('choices are saved at once', (tester) async {
    final store = await open(tester);
    expect(find.textContaining('Scegli come'), findsOneWidget);
    await tap(tester, 'appearance-card-text');
    await tap(tester, 'appearance-text-120');
    await tap(tester, 'appearance-card-units');
    await tap(tester, 'appearance-units-mi');
    await tap(tester, 'appearance-card-datetime');
    await tap(tester, 'appearance-date-ymd');
    await tap(tester, 'appearance-time-12');
    expect(store.saved.last.toMap(), {
      'textScale': 120,
      'units': 'mi',
      'dateFormat': 'ymd',
      'timeFormat': '12',
    });
    // The card shows the current choice as its description.
    expect(find.text('120%'), findsWidgets);
    await tap(tester, 'appearance-card-currencies');
    expect(find.textContaining('Gli importi originali'), findsOneWidget);
  });

  testWidgets('display currency follows the default, × goes back', (
    tester,
  ) async {
    final store = await open(
      tester,
      const AmaterasuAppearance(defaultCurrency: 'EUR'),
    );
    await tap(tester, 'appearance-card-currencies');
    expect(
      find.text('Valuta di visualizzazione: come le nuove voci (EUR)'),
      findsOneWidget,
    );
    await tap(tester, 'appearance-default-currency-clear');
    expect(store.saved.last.defaultCurrency, isNull);
    expect(
      find.text('Valuta di visualizzazione: quella originale'),
      findsOneWidget,
    );
  });

  testWidgets('wide screen: cards as wide as the page', (tester) async {
    await open(tester, null, 1400);
    final card = tester.getSize(find.byKey(const Key('appearance-card-text')));
    expect(card.width, greaterThan(1300));
  });

  testWidgets('phone at 130% without overflow, every card open', (
    tester,
  ) async {
    await open(tester, const AmaterasuAppearance(textScale: 130), 390);
    for (final id in ['text', 'units', 'datetime', 'currencies']) {
      await tap(tester, 'appearance-card-$id');
    }
    expect(tester.takeException(), isNull);
  });
}

// Test automatici dell'esportazione delle spese: lettura dei documenti,
// totali per valuta e per persona (annullate escluse), CSV per Excel e
// pagina da stampare, pulsante con le due scelte.
// Casi, ad esempio: "totals skip cancelled expenses", "CSV uses ; and the decimal comma".

import 'package:amaterasutrip/features/trips/budget/export/budget_export_model.dart';
import 'package:amaterasutrip/features/trips/budget/export/budget_export_writer.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/expenses/trip_expenses_export_button.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/l10n/app_localizations_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart' show FakeBudgetApi;

Map<String, dynamic> money(int minor, String currency) => {
  'minorUnits': minor,
  'currency': currency,
};

Map<String, dynamic> expense(
  String title,
  int total, {
  String currency = 'EUR',
  bool cancelled = false,
}) => {
  'title': title,
  'category': 'food',
  'expenseDate': '2027-04-12',
  'participantNames': {'a': 'Yato', 'b': 'Bruno'},
  if (cancelled) 'lifecycle': 'cancelled',
  'snapshot': {
    'total': money(total, currency),
    'status': 'paid',
    'shares': {
      'a': money(total ~/ 2, currency),
      'b': money(total ~/ 2, currency),
    },
    'advances': {'a': money(total, currency)},
  },
};

BudgetExport sample() => BudgetExport.fromDocs(
  shared: [
    expense('Cena', 4000),
    expense('Treno', 2000, cancelled: true),
    expense('Ramen', 1200, currency: 'JPY'),
  ],
  personal: [expense('Gelato', 300)],
  refundsByTitle: {
    'Cena': [
      {
        'debtorUid': 'b',
        'creditorUid': 'a',
        'minorUnits': 2000,
        'currency': 'EUR',
        'status': 'confirmed',
      },
    ],
  },
  nameOf: (uid) => uid == 'b' ? 'Bruno' : 'Yato',
);

void main() {
  test('totals skip cancelled expenses; shares only for shared ones', () {
    final data = sample();
    expect(data.expenses, hasLength(4));
    expect(data.totals, {'EUR': 4300, 'JPY': 1200});
    expect(data.sharesByPerson[('Bruno', 'EUR')], 2000);
    expect(data.paidByPerson[('Yato', 'EUR')], 4000);
    expect(data.refunds.single.from, 'Bruno');
  });

  test('CSV uses ; and the decimal comma, with a BOM for Excel', () {
    final texts = TripExpensesExportButton.texts(AppLocalizationsIt(), true);
    final csv = BudgetExportWriter(sample(), texts).csv();
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, contains('"2027-04-12";"Cena";"Cibo e bevande"'));
    expect(csv, contains('"40,00";"EUR"'));
    expect(csv, contains('"Annullata"'));
    expect(csv, contains('"Bruno";"Yato";"20,00"'));
  });

  test('the print page escapes text', () {
    final texts = TripExpensesExportButton.texts(AppLocalizationsIt(), true);
    final data = BudgetExport.fromDocs(
      shared: [expense('<b>Cena</b>', 100)],
      personal: const [],
      refundsByTitle: const {},
      nameOf: (uid) => uid,
    );
    final html = BudgetExportWriter(data, texts).html();
    expect(html, contains('&lt;b&gt;Cena&lt;/b&gt;'));
    expect(html, isNot(contains('<b>Cena')));
  });

  testWidgets('menu downloads the CSV or opens the print page', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              TripExpensesExportButton(
                api: FakeBudgetApi(),
                load: (_) async => sample(),
                download: (name, mime, text) {
                  calls.add(name);
                  return true;
                },
                print: (html) {
                  calls.add('print');
                  return false;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('expenses-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expenses-export-csv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expenses-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expenses-export-pdf')));
    await tester.pumpAndSettle();
    expect(calls, ['spese.csv', 'print']);
    expect(find.textContaining('Esportazione non riuscita'), findsOneWidget);
  });
}

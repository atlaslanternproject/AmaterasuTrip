import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_display_amount.dart';

void main() {
  Widget screen(
    BudgetDisplayAmount amount, {
    Locale locale = const Locale('it'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: amount)),
    );
  }

  testWidgets('same currency shows original in Italian', (tester) async {
    await tester.pumpWidget(
      screen(
        const BudgetDisplayAmount(
          minorUnits: 1250,
          originalCurrency: 'EUR',
          displayCurrency: 'EUR',
        ),
      ),
    );

    expect(find.text('12,50 EUR'), findsOneWidget);
    expect(find.text('Originale: 12,50 EUR'), findsOneWidget);
  });

  testWidgets('same currency shows original in English', (tester) async {
    await tester.pumpWidget(
      screen(
        const BudgetDisplayAmount(
          minorUnits: 1250,
          originalCurrency: 'EUR',
          displayCurrency: 'EUR',
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('12,50 EUR'), findsOneWidget);
    expect(find.text('Original: 12,50 EUR'), findsOneWidget);
  });

  testWidgets('converted amount keeps original beneath', (tester) async {
    await tester.pumpWidget(
      screen(
        BudgetDisplayAmount(
          minorUnits: 10000,
          originalCurrency: 'EUR',
          displayCurrency: 'JPY',
          quoteLoader: (from, to) async => BudgetFxQuote(
            base: from,
            quote: to,
            rate: 150,
            observedDate: DateTime.utc(2026, 11, 7),
            requestedDate: null,
            source: 'TestProvider',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('15000 JPY'), findsOneWidget);
    expect(find.text('Originale: 100,00 EUR'), findsOneWidget);
  });

  testWidgets('missing exchange rate never fabricates a value', (tester) async {
    await tester.pumpWidget(
      screen(
        BudgetDisplayAmount(
          minorUnits: 10000,
          originalCurrency: 'EUR',
          displayCurrency: 'JPY',
          quoteLoader: (_, _) async => throw Exception('FX offline'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('— JPY'), findsOneWidget);
    expect(find.text('Originale: 100,00 EUR'), findsOneWidget);
    expect(find.text('Tasso di cambio non disponibile'), findsOneWidget);
  });
}

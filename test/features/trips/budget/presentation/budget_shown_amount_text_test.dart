// Test automatici dell'importo mostrato nella valuta di Aspetto (Extra E7):
// senza preferenza o con la stessa valuta solo l'originale; con un'altra
// valuta l'importo convertito con il tasso bloccato della spesa (lo stesso
// del budget) e "Originale: X"; senza tasso resta l'originale. Anche la
// valuta da cui parte la pagina spese (Aspetto, altrimenti nessuna).
// Casi, ad esempio: "converted with the locked rate of the expense".

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_entry_currency.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_shown_amount_text.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedAppearance extends AmaterasuAppearanceController {
  FixedAppearance(this.value);

  final AmaterasuAppearance value;

  @override
  AmaterasuAppearance build() => value;
}

const locked = {
  'fxHistorical': {
    'base': 'EUR',
    'quote': 'USD',
    'rate': 1.1,
    'date': '2027-04-10',
  },
};

Future<void> pump(
  WidgetTester tester,
  AmaterasuAppearance a,
  Widget child,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        amaterasuAppearanceProvider.overrideWith(() => FixedAppearance(a)),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget amount({Map<String, dynamic>? expense}) => BudgetShownAmountText(
  minorUnits: 10000,
  currency: 'EUR',
  expense: expense,
  text: (a) => 'Costo: $a',
);

void main() {
  testWidgets('no preference or same currency: only the original', (
    tester,
  ) async {
    await pump(tester, const AmaterasuAppearance(), amount());
    expect(find.textContaining('Costo:'), findsOneWidget);
    expect(find.textContaining('Originale'), findsNothing);
    await pump(
      tester,
      const AmaterasuAppearance(displayCurrency: 'EUR'),
      amount(),
    );
    expect(find.textContaining('Originale'), findsNothing);
  });

  testWidgets('converted with the locked rate of the expense', (tester) async {
    await pump(
      tester,
      const AmaterasuAppearance(displayCurrency: 'USD'),
      amount(expense: locked),
    );
    final text = tester.widget<Text>(find.textContaining('Costo:')).data!;
    expect(text, contains('110'));
    expect(text, contains('Originale:'));
    expect(text, contains('100'));
  });

  testWidgets('display currency follows the default one', (tester) async {
    await pump(
      tester,
      const AmaterasuAppearance(defaultCurrency: 'USD'),
      amount(expense: locked),
    );
    expect(find.textContaining('Originale:'), findsOneWidget);
  });

  testWidgets('the expenses page starts from Appearance', (tester) async {
    String? shown;
    await pump(
      tester,
      const AmaterasuAppearance(displayCurrency: 'JPY'),
      Builder(
        builder: (context) {
          shown = amaterasuShownCurrency(context);
          return const SizedBox();
        },
      ),
    );
    expect(shown, 'JPY');
  });
}

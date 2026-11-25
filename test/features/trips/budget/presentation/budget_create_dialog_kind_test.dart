// Test automatici delle correzioni del dialogo spese (Crea spesa): tipo
// "Con tutti" e "Anticipata per altri", pulsante "Tutti", prezzo per
// persona (totale = prezzo x partecipanti), link e sezione di origine.
// Casi, ad esempio: "per person: total is price times participants", "everyone button".

import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_traveler_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';
import 'budget_create_dialog_initial_test.dart' show pump;

FakeBudgetApi api() => FakeBudgetApi(
  members: [
    {'uid': 'A', 'name': 'Anna'},
    {'uid': 'B', 'name': 'Bruno'},
    {'uid': 'C', 'name': 'Carla'},
  ],
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

List<bool> selection(WidgetTester tester) => [
  for (final t in tester.widgetList<BudgetTravelerTile>(
    find.byType(BudgetTravelerTile),
  ))
    t.selected,
];

Future<void> next(WidgetTester tester) =>
    tap(tester, find.byType(FilledButton).last);

void main() {
  testWidgets('everyone button and kind "with everyone"', (tester) async {
    await pump(
      tester,
      BudgetCreateDialog(api: api(), currency: 'EUR', initialTitle: 'Cena'),
    );
    await tap(tester, find.text('Con tutti'));
    await next(tester);
    expect(selection(tester), [true, true, true]);
    await tap(tester, find.text('Bruno'));
    expect(selection(tester), [true, false, true]);
    await tap(tester, find.byKey(const Key('budget-create-all')));
    expect(selection(tester), [true, true, true]);
  });

  testWidgets('paid for others leaves the current traveler out', (
    tester,
  ) async {
    await pump(
      tester,
      BudgetCreateDialog(api: api(), currency: 'EUR', initialTitle: 'Taxi'),
    );
    await tap(tester, find.text('Con tutti'));
    await tap(tester, find.text('Anticipata per altri'));
    await next(tester);
    expect(selection(tester), [false, true, true]);
  });

  testWidgets('per person: total is price times participants', (tester) async {
    final fake = api();
    await pump(
      tester,
      BudgetCreateDialog(
        api: fake,
        currency: 'EUR',
        initialTitle: 'Museo',
        source: ('reservations', 'r1'),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('budget-create-link')),
      'https://museo.jp',
    );
    await tap(tester, find.text('Con tutti'));
    await next(tester);
    await tap(tester, find.text('Per persona'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Prezzo a persona'),
      '12',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(BudgetMoneyFormatter.format(3600, 'EUR')),
      findsWidgets,
    );
    // Save: a progress bar runs while the confirmation is open.
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final saved = fake.createdExpenses.single;
    expect(saved['minorUnits'], 3600);
    expect(saved['participants'], ['A', 'B', 'C']);
    expect(saved['source'], ('reservations', 'r1'));
    expect(saved['link'], 'https://museo.jp');
  });
}

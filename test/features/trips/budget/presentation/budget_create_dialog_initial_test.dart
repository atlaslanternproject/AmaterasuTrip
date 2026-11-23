// Test automatici dei valori iniziali facoltativi del dialogo spese.
// Casi, ad esempio: "starts from the given title, amount and date", "without values nothing changes".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

/// Pre-existing, visual only warning tolerated also in b87_create_dialog_test.
const knownWarning = 'ListTile background color or ink splashes';

Future<void> pump(WidgetTester tester, Widget dialog) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains(knownWarning)) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  await tester.pumpWidget(budgetTestApp(dialog));
  await tester.pumpAndSettle();
}

void main() {
  final api = FakeBudgetApi(
    members: [
      {'uid': 'A', 'name': 'Anna'},
      {'uid': 'B', 'name': 'Bruno'},
    ],
  );

  testWidgets('starts from the given title, amount and date, shared only', (
    tester,
  ) async {
    await pump(
      tester,
      BudgetCreateDialog(
        api: api,
        currency: 'EUR',
        initialTitle: 'Alloggio: Hotel Kyoto',
        initialCategory: 'accommodation',
        initialDate: DateTime(2027, 4, 12),
        initialMinorUnits: 12000,
        sharedOnly: true,
      ),
    );
    expect(find.text('Alloggio: Hotel Kyoto'), findsOneWidget);
    expect(find.text('Personale'), findsNothing);
    expect(find.text('Condivisa'), findsOneWidget);

    // The amount is on the second step; the title lets the user go on.
    final next = find.byType(FilledButton).last;
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('120.00'), findsOneWidget);
  });

  testWidgets('without values the dialog is the same as before', (
    tester,
  ) async {
    await pump(tester, BudgetCreateDialog(api: api, currency: 'EUR'));
    expect(find.text('Personale'), findsOneWidget);
    expect(find.text('Condivisa'), findsOneWidget);
    expect(find.text('120.00'), findsNothing);
  });

  test(
    'BudgetApi.create returns the ID of the new expense (fake API)',
    () async {
      final id = await FakeBudgetApi().create(
        title: 'x',
        category: 'other',
        notes: '',
        shared: true,
        currency: 'EUR',
        minorUnits: 100,
        status: 'planned',
        participants: ['A'],
      );
      expect(id, isNotEmpty);
    },
  );
}

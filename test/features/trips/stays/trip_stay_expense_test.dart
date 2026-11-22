// Test automatici della spesa collegata a un alloggio.
// Casi, ad esempio: "Crea spesa opens a prefilled shared expense", "linked expense shows title, amount and Vedi spesa".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

/// Pre-existing, visual only warning of the budget create dialog.
const knownWarning = 'ListTile background color or ink splashes';

Map<String, dynamic> hotelExpense() => {
  'title': 'Hotel Kyoto',
  'snapshot': {
    'total': eur(36000),
    'status': 'paid',
    'shares': {'anna': eur(18000), 'bruno': eur(18000)},
    'advances': {'anna': eur(36000)},
  },
  'participantUids': ['anna', 'bruno'],
  'participantNames': {'anna': 'Anna', 'bruno': 'Bruno'},
  'category': 'accommodation',
};

Future<void> big(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains(knownWarning)) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  testWidgets('Crea spesa opens a prefilled shared-only expense dialog', (
    tester,
  ) async {
    await big(tester);
    final budget = FakeBudgetApi(
      uid: 'anna',
      members: [
        {'uid': 'anna', 'name': 'Anna'},
        {'uid': 'bruno', 'name': 'Bruno'},
      ],
    );
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')],
        repository: FakeTripStaysRepository(),
        budget: budget,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stay-expense-create-s1')));
    await tester.pumpAndSettle();
    final dialog = tester.widget<BudgetCreateDialog>(
      find.byType(BudgetCreateDialog),
    );
    expect(dialog.initialTitle, 'Hotel Kyoto');
    expect(dialog.initialCategory, 'accommodation');
    expect(dialog.initialDate, DateTime(2027, 4, 12));
    expect(dialog.sharedOnly, isTrue);
    expect(find.text('Personale'), findsNothing);
  });

  for (final fail in [false, true]) {
    testWidgets('after Crea spesa the new expense is linked (fail: $fail)', (
      tester,
    ) async {
      await big(tester);
      final repo = FakeTripStaysRepository()..failLink = fail;
      await tester.pumpWidget(
        staysTestApp(
          const TripHotelsPage(tripId: 't1'),
          stays: [testStay('s1')],
          repository: repo,
          budget: FakeBudgetApi(
            uid: 'anna',
            members: [
              {'uid': 'anna', 'name': 'Anna'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stay-expense-create-s1')));
      await tester.pumpAndSettle();

      // As if the user completed the expense dialog.
      tester
          .widget<BudgetCreateDialog>(find.byType(BudgetCreateDialog))
          .onCreated!('exp-9');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      if (fail) {
        expect(repo.links, isEmpty);
        expect(
          find.text(
            'La spesa è stata creata ma non è stata collegata '
            'all\'alloggio. Usa "Collega spesa esistente" per collegarla.',
          ),
          findsOneWidget,
        );
      } else {
        expect(repo.links, [('s1', 'exp-9')]);
        expect(find.text('Spesa collegata all\'alloggio.'), findsOneWidget);
      }
    });
  }

  testWidgets('an existing shared expense can be linked later', (tester) async {
    await big(tester);
    final repo = FakeTripStaysRepository();
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')],
        repository: repo,
        budget: FakeBudgetApi(
          uid: 'anna',
          shared: [
            FakeDoc('e-hotel', hotelExpense()),
            FakeDoc('e-gone', {
              ...hotelExpense(),
              'title': 'Annullata',
              'lifecycle': 'cancelled',
            }),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stay-expense-link-s1')));
    await tester.pumpAndSettle();
    expect(find.text('Scegli una spesa condivisa'), findsOneWidget);
    expect(find.byKey(const Key('stay-pick-e-gone')), findsNothing);
    await tester.tap(find.byKey(const Key('stay-pick-e-hotel')));
    await tester.pumpAndSettle();
    expect(repo.links, [('s1', 'e-hotel')]);
    expect(find.text('Spesa collegata all\'alloggio.'), findsOneWidget);
  });

  testWidgets('a failed link is explained', (tester) async {
    await big(tester);
    final repo = FakeTripStaysRepository()..failLink = true;
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')],
        repository: repo,
        budget: FakeBudgetApi(
          uid: 'anna',
          shared: [FakeDoc('e-hotel', hotelExpense())],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stay-expense-link-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stay-pick-e-hotel')));
    await tester.pumpAndSettle();
    expect(repo.links, isEmpty);
    expect(find.textContaining('Impossibile salvare'), findsOneWidget);
  });

  testWidgets('linked expense shows title, amount and Vedi spesa', (
    tester,
  ) async {
    await big(tester);
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [
          testStay('s1', expenseId: 'e-hotel'),
          testStay('s2', name: 'Altro', day: 20, expenseId: 'e-missing'),
        ],
        repository: FakeTripStaysRepository(),
        budget: FakeBudgetApi(
          uid: 'anna',
          members: [
            {'uid': 'anna', 'name': 'Anna'},
            {'uid': 'bruno', 'name': 'Bruno'},
          ],
          shared: [FakeDoc('e-hotel', hotelExpense())],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Spesa collegata: Hotel Kyoto'), findsOneWidget);
    expect(find.textContaining('360,00'), findsOneWidget);
    expect(find.byKey(const Key('stay-expense-create-s1')), findsNothing);
    expect(
      find.text('Spesa collegata (non visibile per te o eliminata).'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('stay-expense-view-s1')));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetExpenseDetailsDialog), findsOneWidget);
  });
}

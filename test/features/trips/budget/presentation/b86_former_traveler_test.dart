import 'package:amaterasutrip/features/trips/budget/presentation/budget_people.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_reimbursements_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

/// Anna (A) paid 100 EUR for Anna and Bruno (B). Bruno then left the trip.
Map<String, dynamic> expense({Map<String, String>? names}) => {
  'title': 'Cena',
  'snapshot': {
    'total': eur(10000),
    'status': 'paid',
    'shares': {'A': eur(5000), 'B': eur(5000)},
    'advances': {'A': eur(10000)},
  },
  'participantUids': ['A', 'B'],
  'participantNames': ?names,
};

Widget panel(FakeBudgetApi api, Map<String, dynamic> data) => budgetTestApp(
  BudgetReimbursementsPanel(
    api: api,
    expenseId: 'e1',
    expense: data,
    displayCurrency: 'EUR',
  ),
);

void main() {
  group('BudgetPeople', () {
    test('current name, then recorded name, then fallback', () {
      final data = expense(names: {'A': 'Anna old', 'B': 'Bruno'});
      expect(
        BudgetPeople.name(
          'A',
          live: {'A': 'Anna'},
          expense: data,
          fallback: 'Ex',
        ),
        'Anna',
      );
      expect(
        BudgetPeople.name('B', live: {}, expense: data, fallback: 'Ex'),
        'Bruno',
      );
      expect(
        BudgetPeople.name('ZZ-internal-id', live: {}, fallback: 'Ex'),
        'Ex',
      );
      expect(
        BudgetPeople.name(
          'B',
          live: {'B': '  '},
          recordedNames: {'B': 'Bruno'},
          fallback: 'Ex',
        ),
        'Bruno',
      );
    });

    test('old expenses without recorded names never break', () {
      expect(BudgetPeople.recorded({}), isEmpty);
      expect(BudgetPeople.recorded({'participantNames': 'bad'}), isEmpty);
      expect(
        BudgetPeople.recorded({
          'participantNames': {'A': 'Anna', 'B': 3, 'C': ''},
        }),
        {'A': 'Anna'},
      );
      expect(
        BudgetPeople.recordedAll([
          {
            'participantNames': {'A': 'Anna'},
          },
          {
            'participantNames': {'B': 'Bruno'},
          },
        ]),
        {'A': 'Anna', 'B': 'Bruno'},
      );
      expect(BudgetPeople.isFormer('B', {'A'}), isTrue);
      expect(BudgetPeople.isFormer('A', {'A'}), isFalse);
    });
  });

  group('reimbursements panel with a former traveler', () {
    testWidgets('creditor sees the recorded name and can close the debt', (
      tester,
    ) async {
      final api = FakeBudgetApi(
        uid: 'A',
        members: [
          {'uid': 'A', 'name': 'Anna'},
        ],
      );
      await tester.pumpWidget(
        panel(api, expense(names: {'A': 'Anna', 'B': 'Bruno'})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bruno → Anna'), findsOneWidget);
      expect(find.textContaining('B →'), findsNothing);
      expect(
        find.text('Ex viaggiatore: debito in sola lettura'),
        findsOneWidget,
      );
      expect(find.text('Segnala un rimborso'), findsNothing);

      await tester.tap(find.byKey(const Key('b86-close-B')));
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Chiudi debito');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('b86-close-reason')),
        'Ha lasciato il gruppo',
      );
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(api.closures, [
        {
          'expenseId': 'e1',
          'debtorUid': 'B',
          'reason': 'Ha lasciato il gruppo',
        },
      ]);
    });

    testWidgets('old expense without recorded names shows "Ex viaggiatore"', (
      tester,
    ) async {
      final api = FakeBudgetApi(
        uid: 'A',
        members: [
          {'uid': 'A', 'name': 'Anna'},
        ],
      );
      await tester.pumpWidget(panel(api, expense()));
      await tester.pumpAndSettle();

      expect(find.text('Ex viaggiatore → Anna'), findsOneWidget);
      expect(find.textContaining('B '), findsNothing);
    });

    testWidgets('a closed debt stays visible, read-only, with its reason', (
      tester,
    ) async {
      final api = FakeBudgetApi(
        uid: 'A',
        members: [
          {'uid': 'A', 'name': 'Anna'},
        ],
        refunds: {
          'e1': [
            FakeDoc('c1', {
              'kind': 'closure',
              'debtorUid': 'B',
              'creditorUid': 'A',
              'minorUnits': 5000,
              'status': 'writtenOff',
              'decidedByUid': 'A',
              'reason': 'Ha lasciato il gruppo',
            }),
          ],
        },
      );
      await tester.pumpWidget(
        panel(api, expense(names: {'A': 'Anna', 'B': 'Bruno'})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('b86-close-B')), findsNothing);
      expect(find.text('Chiuso (ex viaggiatore)'), findsOneWidget);
      expect(
        find.text('Bruno → Anna · Chiuso (ex viaggiatore)'),
        findsOneWidget,
      );
      expect(find.text('Chiuso da Anna'), findsOneWidget);
      expect(find.text('Motivo: Ha lasciato il gruppo'), findsOneWidget);
    });

    testWidgets('a debtor who is still a member does not get read-only', (
      tester,
    ) async {
      final api = FakeBudgetApi(
        uid: 'B',
        members: [
          {'uid': 'A', 'name': 'Anna'},
          {'uid': 'B', 'name': 'Bruno'},
        ],
      );
      await tester.pumpWidget(
        panel(api, expense(names: {'A': 'Anna', 'B': 'Bruno'})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Segnala un rimborso'), findsOneWidget);
      expect(find.text('Ex viaggiatore: debito in sola lettura'), findsNothing);
      expect(find.byKey(const Key('b86-close-B')), findsNothing);
    });
  });
}

import 'package:amaterasutrip/features/trips/budget/presentation/budget_history_view.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

const allTypes = [
  'created',
  'revised',
  'reimbursementRequested',
  'reimbursementConfirmed',
  'reimbursementRejected',
  'debtClosed',
  'cancellationRequested',
  'cancellationApproved',
  'cancellationRejected',
  'cancelled',
  'rateChanged',
];

Map<String, dynamic> response() => {
  'events': [
    {
      'expenseId': 'e1',
      'type': 'debtClosed',
      'actorUid': 'A',
      'counterpartUid': 'B',
      'minorUnits': 5000,
      'currency': 'EUR',
      'reason': 'Ha lasciato il gruppo',
      'at': DateTime(2026, 11, 3, 18).millisecondsSinceEpoch,
    },
    {
      'expenseId': 'e1',
      'type': 'reimbursementRejected',
      'actorUid': 'A',
      'counterpartUid': 'GONE',
      'at': null,
    },
    {'expenseId': 'p1', 'type': 'created', 'actorUid': 'A', 'at': 1},
  ],
  'expenses': {
    'e1': {'title': 'Cena', 'visibility': 'shared'},
    'p1': {'title': 'Museo', 'visibility': 'private'},
  },
  'names': {'B': 'Bruno'},
};

void main() {
  test('every event type has a sentence in Italian and English', () {
    for (final locale in ['it', 'en']) {
      final l10n = lookupAppLocalizations(Locale(locale));
      for (final type in allTypes) {
        final text = budgetHistoryText(
          BudgetHistoryEvent(
            expenseId: 'e',
            type: type,
            actorUid: 'A',
            counterpartUid: 'B',
            version: 2,
            rate: 0.0061,
          ),
          l10n,
          (uid) => uid == 'A' ? 'Anna' : 'Bruno',
        );
        expect(text, isNot(l10n.b86EvUnknown), reason: '$locale $type');
        expect(text, contains('Anna'), reason: '$locale $type');
        expect(text.contains(RegExp(r'\bA\b|\bB\b')), isFalse);
      }
    }
    final l10n = lookupAppLocalizations(const Locale('it'));
    expect(
      budgetHistoryText(
        const BudgetHistoryEvent(expenseId: 'e', type: 'future-type'),
        l10n,
        (_) => 'x',
      ),
      l10n.b86EvUnknown,
    );
  });

  test('malformed responses are read safely', () {
    final data = BudgetHistoryData.fromResponse({
      'events': [
        'bad',
        {'type': 'created', 'minorUnits': '12', 'at': 'yesterday'},
      ],
      'expenses': 'bad',
      'names': {'A': 3},
    });
    expect(data.events.single.type, 'created');
    expect(data.events.single.minorUnits, isNull);
    expect(data.events.single.at, isNull);
    expect(data.titles, isEmpty);
    expect(data.recordedNames, isEmpty);
  });

  testWidgets('trip history shows names, titles, private tag and reasons', (
    tester,
  ) async {
    final api = FakeBudgetApi(
      members: [
        {'uid': 'A', 'name': 'Anna'},
      ],
      historyResponse: response(),
    );
    await tester.pumpWidget(budgetTestApp(BudgetHistoryList(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Anna ha chiuso il debito di Bruno'), findsOneWidget);
    expect(
      find.text('Anna ha rifiutato il rimborso di Ex viaggiatore'),
      findsOneWidget,
    );
    expect(find.text('Anna ha creato la spesa'), findsOneWidget);
    expect(find.textContaining('Motivo: Ha lasciato il gruppo'), findsOneWidget);
    expect(find.textContaining('Cena'), findsNWidgets(2));
    expect(find.textContaining('Museo · Privata'), findsOneWidget);
    expect(find.textContaining('Data non disponibile'), findsOneWidget);
    expect(find.textContaining('GONE'), findsNothing);
  });

  testWidgets('expense history hides the expense title', (tester) async {
    final api = FakeBudgetApi(historyResponse: response());
    await tester.pumpWidget(
      budgetTestApp(BudgetHistoryList(api: api, expenseId: 'e1')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Cena'), findsNothing);
  });

  testWidgets('empty and failing history show a message', (tester) async {
    await tester.pumpWidget(
      budgetTestApp(BudgetHistoryList(api: FakeBudgetApi())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nessuna operazione registrata.'), findsOneWidget);

    await tester.pumpWidget(
      budgetTestApp(
        BudgetHistoryList(
          key: const Key('failing'),
          api: FakeBudgetApi(),
          loader: () async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Impossibile caricare lo storico.'), findsOneWidget);
  });
}

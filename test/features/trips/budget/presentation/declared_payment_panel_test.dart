// Test automatici di "Segna come pagato" nel pannello rimborsi.
// Casi, ad esempio: "creditor records the remaining debt", "debtor sees who recorded the payment".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_history_view.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_payment_errors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_reimbursements_panel.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

/// Anna (A) paid 100 EUR for Anna and Bruno (B): Bruno owes Anna 50 EUR.
Map<String, dynamic> expense() => {
  'title': 'Cena',
  'snapshot': {
    'total': eur(10000),
    'status': 'paid',
    'shares': {'A': eur(5000), 'B': eur(5000)},
    'advances': {'A': eur(10000)},
  },
  'participantUids': ['A', 'B'],
  'participantNames': {'A': 'Anna', 'B': 'Bruno'},
};

const members = [
  {'uid': 'A', 'name': 'Anna'},
  {'uid': 'B', 'name': 'Bruno'},
];

Widget panel(FakeBudgetApi api) => budgetTestApp(
  SingleChildScrollView(
    child: BudgetReimbursementsPanel(
      api: api,
      expenseId: 'e1',
      expense: expense(),
      displayCurrency: 'EUR',
    ),
  ),
);

FakeDoc declared(String id, int minor, {String status = 'confirmed'}) =>
    FakeDoc(id, {
      'kind': 'declared',
      'origin': 'creditor',
      'debtorUid': 'B',
      'creditorUid': 'A',
      'recordedByUid': 'A',
      'minorUnits': minor,
      'currency': 'EUR',
      'status': status,
      'paidOn': '2026-11-10',
      'note': 'Contanti al bar',
      if (status == 'voided') ...{
        'voidedByUid': 'A',
        'voidReason': 'Importo sbagliato',
      },
    });

String today() {
  final now = DateUtils.dateOnly(DateTime.now());
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

void main() {
  testWidgets('creditor records the remaining debt with one tap', (
    tester,
  ) async {
    final api = FakeBudgetApi(uid: 'A', members: members);
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paid-mark-B')));
    await tester.pumpAndSettle();
    expect(
      find.text('Bruno ti ha pagato, anche fuori dall\'app.'),
      findsOneWidget,
    );
    expect(find.text('50.00'), findsOneWidget, reason: 'default: remaining');

    await tester.tap(find.byKey(const Key('paid-save')));
    await tester.pumpAndSettle();

    expect(api.declarations, [
      {
        'expenseId': 'e1',
        'debtorUid': 'B',
        'minorUnits': 5000,
        'paidOn': today(),
        'note': '',
        'paymentMethods': null,
      },
    ]);
  });

  testWidgets('creditor records a partial payment with method and note', (
    tester,
  ) async {
    final api = FakeBudgetApi(uid: 'A', members: members);
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paid-mark-B')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paid-amount')), '20');
    await tester.tap(find.byKey(const Key('paid-method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contanti').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paid-note')), 'Al bar');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paid-save')));
    await tester.pumpAndSettle();

    expect(api.declarations.single['minorUnits'], 2000);
    expect(api.declarations.single['note'], 'Al bar');
    expect(api.declarations.single['paymentMethods'], [
      {'payerUid': 'B', 'method': 'cash', 'minorUnits': 2000},
    ]);
  });

  testWidgets('an amount above the remaining debt cannot be saved', (
    tester,
  ) async {
    final api = FakeBudgetApi(uid: 'A', members: members);
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paid-mark-B')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paid-amount')), '50.01');
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.byKey(const Key('paid-save')),
    );
    expect(save.onPressed, isNull);
    expect(
      find.text(
        'Inserisci un importo maggiore di zero e non superiore al residuo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('with a pending request the button offers to confirm it', (
    tester,
  ) async {
    final api = FakeBudgetApi(
      uid: 'A',
      members: members,
      refunds: {
        'e1': [
          FakeDoc('r1', {
            'debtorUid': 'B',
            'creditorUid': 'A',
            'minorUnits': 1500,
            'status': 'pending',
          }),
        ],
      },
    );
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paid-mark-B')));
    await tester.pumpAndSettle();
    expect(find.text('C\'è una richiesta in attesa'), findsOneWidget);
    expect(find.byKey(const Key('paid-confirm-pending')), findsOneWidget);

    await tester.tap(find.byKey(const Key('paid-record-another')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paid-save')), findsOneWidget);
  });

  testWidgets('debtor sees who recorded the payment and the new remaining', (
    tester,
  ) async {
    final api = FakeBudgetApi(
      uid: 'B',
      members: members,
      refunds: {
        'e1': [declared('p1', 2000)],
      },
    );
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paid-mark-B')), findsNothing);
    expect(find.text('Registrato da Anna'), findsOneWidget);
    expect(find.text('Nota: Contanti al bar'), findsOneWidget);
    expect(find.byKey(const Key('paid-void-p1')), findsNothing);
    expect(find.textContaining('30,00'), findsWidgets);
  });

  testWidgets('creditor cancels a recorded payment with a reason', (
    tester,
  ) async {
    final api = FakeBudgetApi(
      uid: 'A',
      members: members,
      refunds: {
        'e1': [declared('p1', 2000)],
      },
    );
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paid-void-p1')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('paid-void-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('paid-void-reason')),
      'Importo sbagliato',
    );
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(api.voids, [
      {'expenseId': 'e1', 'refundId': 'p1', 'reason': 'Importo sbagliato'},
    ]);
  });

  testWidgets('a cancelled payment is shown but no longer counted', (
    tester,
  ) async {
    final api = FakeBudgetApi(
      uid: 'A',
      members: members,
      refunds: {
        'e1': [declared('p1', 2000, status: 'voided')],
      },
    );
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('Annullato'), findsWidgets);
    expect(find.text('Annullato da Anna'), findsOneWidget);
    expect(find.text('Motivo: Importo sbagliato'), findsOneWidget);
    expect(find.byKey(const Key('paid-void-p1')), findsNothing);
    expect(find.textContaining('50,00'), findsWidgets);
    expect(find.byKey(const Key('paid-mark-B')), findsOneWidget);
  });

  testWidgets('no button for a debt of a former traveler', (tester) async {
    final api = FakeBudgetApi(
      uid: 'A',
      members: [
        {'uid': 'A', 'name': 'Anna'},
      ],
    );
    await tester.pumpWidget(panel(api));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paid-mark-B')), findsNothing);
    expect(find.byKey(const Key('b86-close-B')), findsOneWidget);
  });

  test('default amount text is the opposite of parsing', () {
    expect(BudgetMoneyInput.plainText(5000, 'EUR'), '50.00');
    expect(BudgetMoneyInput.plainText(5, 'EUR'), '0.05');
    expect(BudgetMoneyInput.plainText(1200, 'JPY'), '1200');
    for (final (minor, currency) in [
      (5000, 'EUR'),
      (5, 'EUR'),
      (1200, 'JPY'),
    ]) {
      expect(
        BudgetMoneyInput.parse(
          BudgetMoneyInput.plainText(minor, currency),
          currency,
        ),
        minor,
      );
    }
  });

  test('history sentences and clear errors in both languages', () {
    for (final locale in ['it', 'en']) {
      final l10n = lookupAppLocalizations(Locale(locale));
      String name(String? uid) => uid == 'A' ? 'Anna' : 'Bruno';
      final declaredText = budgetHistoryText(
        BudgetHistoryEvent.fromMap({
          'expenseId': 'e1',
          'type': 'paymentDeclared',
          'actorUid': 'A',
          'counterpartUid': 'B',
        }),
        l10n,
        name,
      );
      final voidedText = budgetHistoryText(
        BudgetHistoryEvent.fromMap({
          'expenseId': 'e1',
          'type': 'paymentVoided',
          'actorUid': 'A',
          'counterpartUid': 'B',
        }),
        l10n,
        name,
      );
      expect(declaredText, contains('Anna'));
      expect(declaredText, contains('Bruno'));
      expect(declaredText, isNot(l10n.b86EvUnknown));
      expect(voidedText, isNot(l10n.b86EvUnknown));
      expect(
        budgetPaymentErrorText('Reimbursement exceeds remaining debt.', l10n),
        l10n.btPaidRequestExceeds,
      );
      expect(budgetPaymentErrorText('Something else.', l10n), isNull);
    }
    expect(
      budgetHistoryText(
        BudgetHistoryEvent.fromMap({
          'expenseId': 'e1',
          'type': 'paymentDeclared',
          'actorUid': 'A',
          'counterpartUid': 'B',
        }),
        lookupAppLocalizations(const Locale('it')),
        (uid) => uid == 'A' ? 'Anna' : 'Bruno',
      ),
      'Anna ha registrato un pagamento di Bruno',
    );
  });
}

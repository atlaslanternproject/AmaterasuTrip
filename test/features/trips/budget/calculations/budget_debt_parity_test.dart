import 'dart:convert';
import 'dart:io';

import 'package:amaterasutrip/features/trips/budget/calculations/budget_snapshot_debts.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/expense_debt_calculator.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same fixture is checked by functions/test/budget-calc-parity.test.cjs,
/// so the app and the Cloud Functions must agree on every case.
final Map<String, dynamic> fixture =
    jsonDecode(File('test/fixtures/budget_debt_parity.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> cases(String key) => (fixture[key] as List)
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();

BudgetPairDebt pair(Map<String, dynamic> raw) => BudgetPairDebt(
  raw['debtorUid'] as String,
  raw['creditorUid'] as String,
  raw['minorUnits'] as int,
);

Map<String, MoneyAmount> amounts(Object? raw) => {
  for (final entry in (raw as Map).entries)
    entry.key as String: MoneyAmount(
      currency: (entry.value as Map)['currency'] as String,
      minorUnits: (entry.value as Map)['minorUnits'] as int,
    ),
};

void main() {
  group('debt allocation matches the Cloud Functions fixture', () {
    for (final item in cases('debtCases')) {
      final snapshot = Map<String, dynamic>.from(item['snapshot'] as Map);
      final expected = (item['debts'] as List)
          .map((raw) => pair(Map<String, dynamic>.from(raw as Map)))
          .toList();

      test('raw data: ${item['name']}', () {
        expect(BudgetSnapshotDebts.allocate(snapshot), expected);
      });

      if (snapshot['status'] == 'paid') {
        test('model calculator: ${item['name']}', () {
          final total = Map<String, dynamic>.from(snapshot['total'] as Map);
          final debts = ExpenseDebtCalculator.calculate(
            expenseId: 'fixture',
            expense: ExpenseFinancialSnapshot(
              total: MoneyAmount(
                currency: total['currency'] as String,
                minorUnits: total['minorUnits'] as int,
              ),
              status: ExpensePaymentStatus.paid,
              shares: amounts(snapshot['shares']),
              advances: amounts(snapshot['advances']),
            ),
          );
          expect(
            debts
                .map(
                  (debt) => BudgetPairDebt(
                    debt.debtorUid,
                    debt.creditorUid,
                    debt.amount.minorUnits,
                  ),
                )
                .toList(),
            expected,
          );
        });
      }
    }
  });

  group('settlement sums match the Cloud Functions fixture', () {
    for (final item in cases('settlementCases')) {
      test(item['name'], () {
        final debt = pair(Map<String, dynamic>.from(item['debt'] as Map));
        final refunds = (item['reimbursements'] as List)
            .map((raw) => Map<String, dynamic>.from(raw as Map))
            .toList();

        expect(
          BudgetSnapshotDebts.sumFor(
            refunds,
            debt.debtorUid,
            debt.creditorUid,
            BudgetSnapshotDebts.settledStatuses,
          ),
          item['settled'],
        );
        expect(
          BudgetSnapshotDebts.sumFor(
            refunds,
            debt.debtorUid,
            debt.creditorUid,
            const {'pending'},
          ),
          item['pending'],
        );
        expect(BudgetSnapshotDebts.remaining(debt, refunds), item['remaining']);
      });
    }
  });
}

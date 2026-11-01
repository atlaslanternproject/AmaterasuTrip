import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/expense_financial_validator.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

ExpenseFinancialSnapshot expense({
  required ExpensePaymentStatus status,
  required Map<String, MoneyAmount> advances,
}) {
  return ExpenseFinancialSnapshot(
    total: eur(12000),
    status: status,
    shares: {'anna': eur(4000), 'luca': eur(4000), 'marco': eur(4000)},
    advances: advances,
  );
}

void main() {
  test('planned expense without advances is valid', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(status: ExpensePaymentStatus.planned, advances: {}),
      ),
      returnsNormally,
    );
  });

  test('outstanding expense with partial advance is valid', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(
          status: ExpensePaymentStatus.outstanding,
          advances: {'luca': eur(3000)},
        ),
      ),
      returnsNormally,
    );
  });

  test('confirmed but unpaid expense is outstanding', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(status: ExpensePaymentStatus.outstanding, advances: {}),
      ),
      returnsNormally,
    );
  });

  test('fully paid expense is valid', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(
          status: ExpensePaymentStatus.paid,
          advances: {'anna': eur(4000), 'luca': eur(8000)},
        ),
      ),
      returnsNormally,
    );
  });

  test('planned expense cannot contain actual payment', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(
          status: ExpensePaymentStatus.planned,
          advances: {'anna': eur(1000)},
        ),
      ),
      throwsArgumentError,
    );
  });

  test('paid status cannot hide supplier debt', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(
          status: ExpensePaymentStatus.paid,
          advances: {'anna': eur(3000)},
        ),
      ),
      throwsArgumentError,
    );
  });

  test('outstanding status cannot be fully paid', () {
    expect(
      () => ExpenseFinancialValidator.validate(
        expense(
          status: ExpensePaymentStatus.outstanding,
          advances: {'anna': eur(12000)},
        ),
      ),
      throwsArgumentError,
    );
  });

  test('shares must still equal total expense', () {
    final invalid = ExpenseFinancialSnapshot(
      total: eur(12000),
      status: ExpensePaymentStatus.planned,
      shares: {'anna': eur(4000), 'luca': eur(4000)},
      advances: {},
    );

    expect(
      () => ExpenseFinancialValidator.validate(invalid),
      throwsArgumentError,
    );
  });
}

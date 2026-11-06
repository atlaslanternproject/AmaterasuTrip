import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/budget/models/budget_payment_allocation.dart';
import 'package:amaterasutrip/features/trips/budget/models/budget_payment_plan.dart';

void main() {
  BudgetPaymentAllocation pay(
    String uid,
    BudgetPaymentMethod method,
    int minor, {
    String? label,
  }) {
    return BudgetPaymentAllocation(
      payerUid: uid,
      method: method,
      minorUnits: minor,
      otherLabel: label,
    );
  }

  const members = {'atlas', 'yato', 'reiji'};

  void check(
    BudgetPaymentPlan plan, {
    required String status,
    required int total,
    required Map<String, int> advances,
  }) {
    plan.validate(
      status: status,
      expenseTotalMinor: total,
      advancesMinor: advances,
      activeTravelerUids: members,
    );
  }

  test('single payer and cash', () {
    final plan = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.cash, 10000),
    ]);

    check(plan, status: 'paid', total: 10000, advances: {'atlas': 10000});

    expect(plan.totalMinor, 10000);
    expect(plan.approvalsRequired('atlas'), isEmpty);
  });

  test('one payer, several payment methods', () {
    final plan = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.cash, 4000),
      pay('atlas', BudgetPaymentMethod.card, 6000),
    ]);

    check(plan, status: 'paid', total: 10000, advances: {'atlas': 10000});

    expect(plan.amountByPayer['atlas'], 10000);
  });

  test('multiple payers require other payer approval', () {
    final plan = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.cash, 4000),
      pay('yato', BudgetPaymentMethod.paypal, 6000),
    ]);

    check(
      plan,
      status: 'paid',
      total: 10000,
      advances: {'atlas': 4000, 'yato': 6000},
    );

    expect(plan.approvalsRequired('atlas'), {'yato'});
    expect(plan.approvalsRequired('yato'), {'atlas'});
  });

  test('supports transfer and Satispay', () {
    final plan = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.bankTransfer, 3000),
      pay('atlas', BudgetPaymentMethod.satispay, 2000),
    ]);

    check(plan, status: 'paid', total: 5000, advances: {'atlas': 5000});
  });

  test('other method needs a description', () {
    expect(pay('atlas', BudgetPaymentMethod.other, 2000).isValid, isFalse);

    expect(
      pay(
        'atlas',
        BudgetPaymentMethod.other,
        2000,
        label: 'Carta prepagata',
      ).isValid,
      isTrue,
    );
  });

  test('planned expense has no payment methods', () {
    check(
      const BudgetPaymentPlan([]),
      status: 'planned',
      total: 10000,
      advances: const {},
    );

    expect(
      () => check(
        BudgetPaymentPlan([pay('atlas', BudgetPaymentMethod.cash, 1000)]),
        status: 'planned',
        total: 10000,
        advances: {'atlas': 1000},
      ),
      throwsFormatException,
    );
  });

  test('outstanding expense accepts partial payments', () {
    check(
      BudgetPaymentPlan([pay('atlas', BudgetPaymentMethod.cash, 2500)]),
      status: 'outstanding',
      total: 10000,
      advances: {'atlas': 2500},
    );
  });

  test('outstanding expense rejects full payment', () {
    expect(
      () => check(
        BudgetPaymentPlan([pay('atlas', BudgetPaymentMethod.card, 10000)]),
        status: 'outstanding',
        total: 10000,
        advances: {'atlas': 10000},
      ),
      throwsFormatException,
    );
  });

  test('paid expense rejects incomplete payments', () {
    expect(
      () => check(
        BudgetPaymentPlan([pay('atlas', BudgetPaymentMethod.card, 5000)]),
        status: 'paid',
        total: 10000,
        advances: {'atlas': 5000},
      ),
      throwsFormatException,
    );
  });

  test('methods must match actual payer advances', () {
    expect(
      () => check(
        BudgetPaymentPlan([pay('atlas', BudgetPaymentMethod.cash, 10000)]),
        status: 'paid',
        total: 10000,
        advances: {'yato': 10000},
      ),
      throwsFormatException,
    );
  });

  test('rejects unknown payer', () {
    expect(
      () => check(
        BudgetPaymentPlan([pay('stranger', BudgetPaymentMethod.card, 10000)]),
        status: 'paid',
        total: 10000,
        advances: {'stranger': 10000},
      ),
      throwsFormatException,
    );
  });

  test('rejects zero or negative payment portion', () {
    expect(pay('atlas', BudgetPaymentMethod.cash, 0).isValid, isFalse);

    expect(pay('atlas', BudgetPaymentMethod.cash, -1).isValid, isFalse);
  });

  test('round trip preserves payment details', () {
    final original = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.cash, 1200),
      pay('yato', BudgetPaymentMethod.other, 800, label: 'Voucher'),
    ]);

    final restored = BudgetPaymentPlan.fromPayload(original.toPayload());

    expect(restored, isNotNull);
    expect(restored!.amountByPayer['atlas'], 1200);
    expect(restored.amountByPayer['yato'], 800);
    expect(restored.allocations[1].otherLabel, 'Voucher');
  });

  test('invalid method identifier is rejected', () {
    final value = BudgetPaymentAllocation.fromMap({
      'payerUid': 'atlas',
      'method': 'cryptocurrencyUnknown',
      'minorUnits': 1000,
    });

    expect(value, isNull);
  });

  test('extra fields are rejected', () {
    final value = BudgetPaymentAllocation.fromMap({
      'payerUid': 'atlas',
      'method': 'cash',
      'minorUnits': 1000,
      'unexpected': true,
    });

    expect(value, isNull);
  });

  test('no approval required when recorder is only payer', () {
    final plan = BudgetPaymentPlan([
      pay('atlas', BudgetPaymentMethod.card, 3000),
      pay('atlas', BudgetPaymentMethod.cash, 7000),
    ]);

    expect(plan.approvalsRequired('atlas'), isEmpty);
  });
}

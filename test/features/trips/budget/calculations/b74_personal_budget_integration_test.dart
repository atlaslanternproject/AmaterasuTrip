import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/budget/calculations/personal_budget_spending_calculator.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/budget/models/personal_trip_budget.dart';

Map<String, dynamic> expense({
  required String currency,
  required int totalMinor,
  required String status,
  String lifecycle = 'active',
  int? atlasShare,
  int? yatoShare,
  int? atlasAdvance,
}) {
  return {
    'lifecycle': lifecycle,
    'snapshot': {
      'status': status,
      'total': {'currency': currency, 'minorUnits': totalMinor},
      'shares': {
        if (atlasShare != null)
          'atlas': {'currency': currency, 'minorUnits': atlasShare},
        if (yatoShare != null)
          'yato': {'currency': currency, 'minorUnits': yatoShare},
      },
      'advances': {
        if (atlasAdvance != null)
          'atlas': {'currency': currency, 'minorUnits': atlasAdvance},
      },
    },
  };
}

int ownAmount(Map<String, dynamic> value, {bool personal = false}) {
  if (!PersonalBudgetSpendingCalculator.isIncluded(value)) {
    return 0;
  }

  final share = PersonalBudgetSpendingCalculator.ownShare(
    value,
    uid: 'atlas',
    privateExpense: personal,
  );

  if (share == null) {
    throw StateError('Invalid share: must not be counted as zero.');
  }

  return share.minorUnits;
}

void main() {
  group('B7.4 - calcoli del budget personale', () {
    test('A: 500 EUR, utilizzato 200 EUR, disponibile 300 EUR', () {
      const budget = PersonalTripBudget(amountMinor: 50000, currency: 'EUR');

      final personalPaid = expense(
        currency: 'EUR',
        totalMinor: 10000,
        status: 'paid',
      );

      final sharedPaid = expense(
        currency: 'EUR',
        totalMinor: 20000,
        status: 'paid',
        atlasShare: 10000,
        yatoShare: 10000,
        atlasAdvance: 20000,
      );

      final planned = expense(
        currency: 'EUR',
        totalMinor: 5000,
        status: 'planned',
        atlasShare: 5000,
      );

      final used =
          ownAmount(personalPaid, personal: true) +
          ownAmount(sharedPaid) +
          ownAmount(planned);

      expect(used, 20000);
      expect(budget.remainingMinor(used), 30000);
      expect(budget.isExceeded(used), isFalse);
    });

    test('B: 150 EUR, utilizzato 200 EUR, eccedenza 50 EUR', () {
      const budget = PersonalTripBudget(amountMinor: 15000, currency: 'EUR');

      const used = 20000;

      expect(budget.remainingMinor(used), -5000);
      expect(budget.exceededMinor(used), 5000);
      expect(budget.isExceeded(used), isTrue);
    });

    test('anticipo di altri viaggiatori non altera la quota', () {
      final shared = expense(
        currency: 'EUR',
        totalMinor: 40000,
        status: 'paid',
        atlasShare: 10000,
        yatoShare: 30000,
        atlasAdvance: 40000,
      );

      expect(ownAmount(shared), 10000);
    });

    test('spesa outstanding inclusa', () {
      final shared = expense(
        currency: 'EUR',
        totalMinor: 6000,
        status: 'outstanding',
        atlasShare: 3000,
        yatoShare: 3000,
      );

      expect(ownAmount(shared), 3000);
    });

    test('spesa planned esclusa', () {
      final planned = expense(
        currency: 'EUR',
        totalMinor: 10000,
        status: 'planned',
        atlasShare: 5000,
      );

      expect(ownAmount(planned), 0);
    });

    test('spesa cancelled esclusa', () {
      final cancelled = expense(
        currency: 'EUR',
        totalMinor: 10000,
        status: 'paid',
        lifecycle: 'cancelled',
        atlasShare: 5000,
      );

      expect(ownAmount(cancelled), 0);
    });

    test('mancanza quota non equivale a zero', () {
      final malformed = expense(
        currency: 'EUR',
        totalMinor: 10000,
        status: 'paid',
        yatoShare: 10000,
      );

      expect(
        PersonalBudgetSpendingCalculator.ownShare(
          malformed,
          uid: 'atlas',
          privateExpense: false,
        ),
        isNull,
      );
    });

    test('rimborso non conteggiato come spesa', () {
      final repayment = {'kind': 'repayment', 'amountMinor': 5000};

      expect(PersonalBudgetSpendingCalculator.isIncluded(repayment), isFalse);
    });

    test('JPY non utilizza centesimi', () {
      final yen = expense(
        currency: 'JPY',
        totalMinor: 25000,
        status: 'paid',
        atlasShare: 12500,
        yatoShare: 12500,
      );

      expect(ownAmount(yen), 12500);
    });

    test('conversione EUR/JPY con tasso controllato', () {
      final quote = BudgetFxQuote(
        base: 'JPY',
        quote: 'EUR',
        rate: 0.006,
        observedDate: DateTime(2026, 11, 5),
        requestedDate: DateTime(2026, 11, 5),
        source: 'test',
      );

      final converted = BudgetFxService.convertMinor(
        10000,
        'JPY',
        'EUR',
        quote,
      );

      expect(converted, 6000);
    });

    test('FX assente non produce un falso zero', () {
      final converted = BudgetFxService.convertMinor(10000, 'JPY', 'EUR', null);

      expect(converted, isNull);
    });

    test('FX con valuta errata viene rifiutato', () {
      final wrongQuote = BudgetFxQuote(
        base: 'USD',
        quote: 'EUR',
        rate: 0.9,
        observedDate: DateTime(2026, 11, 5),
        requestedDate: null,
        source: 'test',
      );

      expect(
        BudgetFxService.convertMinor(10000, 'JPY', 'EUR', wrongQuote),
        isNull,
      );
    });

    test('conversione stessa valuta mantiene importo', () {
      expect(BudgetFxService.convertMinor(12345, 'EUR', 'EUR', null), 12345);
    });

    test('budget personale facoltativo', () {
      expect(PersonalTripBudget.fromMap(null), isNull);
    });
  });
}

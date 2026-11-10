import 'package:amaterasutrip/features/trips/budget/models/personal_trip_budget.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_dashboard.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_charts.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/personal_trip_budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

/// Anna (A) and Bruno (B). Dates are in the past, so the "last N days"
/// filter is not involved unless a test sets it.
FakeBudgetApi tripApi({bool foreign = false}) => FakeBudgetApi(
  uid: 'A',
  shared: [
    expenseDoc(
      'Cena',
      category: 'food',
      total: 6000,
      shares: {'A': 3000, 'B': 3000},
      advances: {'A': 6000},
      day: '2026-11-01',
    ),
    expenseDoc(
      'Treno',
      category: 'transport',
      total: 4000,
      status: 'outstanding',
      shares: {'A': 2000, 'B': 2000},
      day: '2026-11-03',
    ),
    expenseDoc(
      'Annullata',
      category: 'shopping',
      total: 9900,
      shares: {'A': 9900},
      advances: {'A': 9900},
      day: '2026-11-02',
      extra: {'lifecycle': 'cancelled'},
    ),
    if (foreign)
      expenseDoc(
        'Ramen',
        category: 'food',
        currency: 'JPY',
        total: 1000,
        shares: {'A': 500, 'B': 500},
        advances: {'A': 1000},
        day: '2026-11-02',
      ),
  ],
  private: [
    expenseDoc(
      'Museo',
      category: 'activities',
      total: 1500,
      shares: {'A': 1500},
      advances: {'A': 1500},
      day: '2026-11-02',
    ),
  ],
);

Widget dashboard(
  FakeBudgetApi api, {
  BudgetExpenseFilters filters = const BudgetExpenseFilters(),
}) => budgetTestApp(
  BudgetCategoryDashboard(
    api: api,
    mainCurrency: 'EUR',
    displayCurrency: 'EUR',
    filters: filters,
    onFiltersChanged: (_) {},
  ),
);

Future<void> setScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('trend data', () {
    test('one bar per day, empty days kept, same day summed', () {
      final trend = BudgetTrend.from({
        DateTime(2026, 11, 1, 9): 100,
        DateTime(2026, 11, 1, 20): 50,
        DateTime(2026, 11, 4): 300,
      });
      expect(trend.monthly, isFalse);
      expect(trend.points, [
        BudgetTrendPoint(DateTime(2026, 11, 1), 150),
        BudgetTrendPoint(DateTime(2026, 11, 2), 0),
        BudgetTrendPoint(DateTime(2026, 11, 3), 0),
        BudgetTrendPoint(DateTime(2026, 11, 4), 300),
      ]);
    });

    test('daylight saving change does not skip or repeat a day', () {
      final trend = BudgetTrend.from({
        DateTime(2026, 3, 28): 1,
        DateTime(2026, 3, 31): 2,
      });
      expect(trend.points.map((p) => p.period.day), [28, 29, 30, 31]);
    });

    test('long trips are grouped by month', () {
      final trend = BudgetTrend.from({
        DateTime(2026, 1, 10): 100,
        DateTime(2026, 1, 20): 50,
        DateTime(2026, 4, 2): 10,
      });
      expect(trend.monthly, isTrue);
      expect(trend.points, [
        BudgetTrendPoint(DateTime(2026, 1), 150),
        BudgetTrendPoint(DateTime(2026, 2), 0),
        BudgetTrendPoint(DateTime(2026, 3), 0),
        BudgetTrendPoint(DateTime(2026, 4), 10),
      ]);
    });

    test('no data, no bars', () {
      expect(BudgetTrend.from({}).points, isEmpty);
    });
  });

  group('category dashboard', () {
    testWidgets('group view shows both charts and keeps cancelled out', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1800));
      await tester.pumpWidget(dashboard(tripApi()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('b85-category-chart')), findsOneWidget);
      expect(find.byKey(const Key('b85-trend-chart')), findsOneWidget);
      expect(find.text('Ripartizione per categoria'), findsOneWidget);
      expect(find.text('Andamento nel tempo'), findsOneWidget);
      expect(find.text('Totale per giorno'), findsOneWidget);
      expect(find.text('Cibo e bevande'), findsOneWidget);
      expect(find.text('Trasporti'), findsOneWidget);
      expect(find.text('Shopping'), findsNothing);
      expect(find.text('Attività'), findsNothing);
      expect(find.text('100,00 EUR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('personal view never mixes in shared expenses', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1800));
      await tester.pumpWidget(dashboard(tripApi()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Le mie spese personali'));
      await tester.pumpAndSettle();

      expect(find.text('Attività'), findsOneWidget);
      expect(find.text('Cibo e bevande'), findsNothing);
      expect(find.text('Trasporti'), findsNothing);
      expect(find.byKey(const Key('b85-category-chart')), findsOneWidget);
    });

    testWidgets('shared filters apply to the charts', (tester) async {
      await setScreen(tester, const Size(1200, 1800));
      await tester.pumpWidget(
        dashboard(
          tripApi(),
          filters: const BudgetExpenseFilters(category: 'transport'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trasporti'), findsOneWidget);
      expect(find.text('Cibo e bevande'), findsNothing);
    });

    testWidgets('missing exchange rates are excluded and said so', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1800));
      final api = tripApi(foreign: true);
      await tester.pumpWidget(dashboard(api));
      await tester.pumpAndSettle();

      expect(
        find.text('I grafici non includono le spese senza tasso di cambio.'),
        findsOneWidget,
      );
      expect(find.textContaining('JPY'), findsWidgets);
      // The chart total is the EUR expenses only.
      expect(find.text('100,00 EUR'), findsWidgets);
    });

    testWidgets('no expenses, no charts', (tester) async {
      await tester.pumpWidget(dashboard(FakeBudgetApi()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('b85-category-chart')), findsNothing);
      expect(find.byKey(const Key('b85-trend-chart')), findsNothing);
    });

    for (final size in const [Size(320, 900), Size(390, 844), Size(800, 1200)]) {
      testWidgets('layout holds on ${size.width.toInt()} px', (tester) async {
        await setScreen(tester, size);
        await tester.pumpWidget(dashboard(tripApi(foreign: true)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('b85-trend-chart')), findsOneWidget);
      });
    }
  });

  group('personal budget card', () {
    Widget card(FakeBudgetApi api, FakePersonalBudgetRepository repo) =>
        budgetTestApp(
          PersonalTripBudgetCard(
            api: api,
            defaultCurrency: 'EUR',
            displayCurrency: 'EUR',
            repository: repo,
          ),
        );

    testWidgets('without a budget offers to set one', (tester) async {
      await tester.pumpWidget(card(tripApi(), FakePersonalBudgetRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Imposta budget'), findsOneWidget);
    });

    testWidgets('own shares of shared and private expenses count', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1800));
      final repo = FakePersonalBudgetRepository(
        const PersonalTripBudget(amountMinor: 10000, currency: 'EUR'),
      );
      await tester.pumpWidget(card(tripApi(), repo));
      await tester.pumpAndSettle();

      expect(find.text('Budget previsto'), findsOneWidget);
      // 30 (dinner share) + 20 (train share) + 15 (museum) = 65 EUR.
      expect(find.text('65,00 EUR'), findsOneWidget);
      expect(find.text('Disponibile'), findsOneWidget);
      expect(find.text('35,00 EUR'), findsOneWidget);
    });

    testWidgets('a missing exchange rate makes the remaining unknown', (
      tester,
    ) async {
      final repo = FakePersonalBudgetRepository(
        const PersonalTripBudget(amountMinor: 10000, currency: 'EUR'),
      );
      await tester.pumpWidget(card(tripApi(foreign: true), repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rimanente non determinabile'), findsOneWidget);
    });

    for (final size in const [Size(320, 900), Size(1200, 900)]) {
      testWidgets('layout holds on ${size.width.toInt()} px', (tester) async {
        await setScreen(tester, size);
        final repo = FakePersonalBudgetRepository(
          const PersonalTripBudget(amountMinor: 10000, currency: 'EUR'),
        );
        await tester.pumpWidget(card(tripApi(foreign: true), repo));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

import 'package:amaterasutrip/features/trips/budget/calculations/budget_snapshot_debts.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/personal_budget_spending_calculator.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_dashboard.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_day.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_list.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_people.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_user_settlement_summary.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/expenses/trip_expenses_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_budget_api.dart';

/// B8.7: expense documents in the format written before B8.4-B8.6:
/// no expenseDate, no fxHistorical, no paymentMethods, no
/// participantNames, no lifecycle, only createdAt.
final created = DateTime.now().subtract(const Duration(days: 2));

FakeDoc legacyShared() => FakeDoc('legacy1', {
  'title': 'Hotel vecchio formato',
  'category': 'accommodation',
  'participantUids': ['A', 'B'],
  'createdByUid': 'A',
  'visibility': 'shared',
  'version': 1,
  'createdAt': Timestamp.fromDate(created),
  'snapshot': {
    'total': eur(20000),
    'status': 'paid',
    'shares': {'A': eur(10000), 'B': eur(10000)},
    'advances': {'A': eur(20000)},
  },
});

FakeDoc legacyPrivate() => FakeDoc('legacyP', {
  'title': 'Souvenir vecchio formato',
  'category': 'shopping',
  'participantUids': ['A'],
  'createdByUid': 'A',
  'visibility': 'private',
  'version': 1,
  'createdAt': Timestamp.fromDate(created),
  'snapshot': {
    'total': eur(2500),
    'status': 'paid',
    'shares': {'A': eur(2500)},
    'advances': {'A': eur(2500)},
  },
});

/// Anna is the current traveler; Bruno (B) left the trip.
FakeBudgetApi legacyApi() =>
    FakeBudgetApi(
        uid: 'A',
        members: [
          {'uid': 'A', 'name': 'Anna'},
        ],
        shared: [legacyShared()],
        private: [legacyPrivate()],
        historyResponse: {
          'events': [
            {
              'expenseId': 'legacy1',
              'type': 'created',
              'actorUid': 'A',
              'at': created.millisecondsSinceEpoch,
            },
          ],
          'expenses': {
            'legacy1': {
              'title': 'Hotel vecchio formato',
              'visibility': 'shared',
            },
          },
          'names': {},
        },
      )
      ..revisionDocs = {
        'legacy1': [
          FakeDoc('1', {
            'number': 1,
            'actorUid': 'A',
            'createdAt': Timestamp.fromDate(created),
            'snapshot': legacyShared().data()['snapshot'],
          }),
        ],
      };

Future<void> setScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget localized(Widget home) => MaterialApp(
  locale: const Locale('it'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('old expense format: calculations', () {
    final data = legacyShared().data();

    test('day falls back to createdAt', () {
      expect(budgetExpenseDay(data), created);
    });

    test('debts and remaining work without new fields', () {
      final debts = BudgetSnapshotDebts.allocate(data['snapshot']);
      expect(debts, [const BudgetPairDebt('B', 'A', 10000)]);
      expect(BudgetSnapshotDebts.remaining(debts.single, const []), 10000);
    });

    test('filters by period use createdAt', () {
      final now = DateTime.now();
      expect(const BudgetExpenseFilters(days: 7).matches(data, now), isTrue);
      expect(const BudgetExpenseFilters(days: 1).matches(data, now), isFalse);
    });

    test('personal spending and names never need the new fields', () {
      expect(PersonalBudgetSpendingCalculator.isIncluded(data), isTrue);
      expect(
        BudgetPeople.name('B', live: {}, expense: data, fallback: 'Ex'),
        'Ex',
      );
    });
  });

  group('main budget screens', () {
    for (final size in const [Size(390, 844), Size(1280, 900)]) {
      testWidgets(
        'expenses page renders old data at ${size.width.toInt()} px',
        (tester) async {
          await setScreen(tester, size);
          await tester.pumpWidget(
            localized(TripExpensesPage(tripId: 'trip1', api: legacyApi())),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const Key('b85-category-chart')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.byKey(const Key('b85-category-chart')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Hotel vecchio formato'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('Hotel vecchio formato'), findsWidgets);
        },
      );
    }

    testWidgets('trip history opens from the expenses page', (tester) async {
      await setScreen(tester, const Size(1280, 900));
      await tester.pumpWidget(
        localized(TripExpensesPage(tripId: 'trip1', api: legacyApi())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Storico del viaggio'));
      await tester.pumpAndSettle();

      expect(find.text('Storico del viaggio'), findsWidgets);
      expect(find.text('Anna ha creato la spesa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expense list shows old shared and private expenses', (
      tester,
    ) async {
      final api = legacyApi();
      for (final private in [false, true]) {
        await tester.pumpWidget(
          budgetTestApp(
            BudgetExpenseList(
              key: ValueKey(private),
              api: api,
              private: private,
              filters: const BudgetExpenseFilters(),
              displayCurrency: 'EUR',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            private ? 'Souvenir vecchio formato' : 'Hotel vecchio formato',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('details of an old expense, with a former traveler', (
      tester,
    ) async {
      await setScreen(tester, const Size(900, 2400));
      final api = legacyApi();
      await tester.pumpWidget(
        budgetTestApp(
          BudgetExpenseDetailsDialog(
            expense: legacyShared().data(),
            expenseId: 'legacy1',
            api: api,
            isPrivate: false,
            displayCurrency: 'EUR',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gestisci spesa'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Hotel vecchio formato'), findsWidgets);
      expect(find.text('Ex viaggiatore → Anna'), findsOneWidget);
      expect(find.text('Storico della spesa'), findsOneWidget);
      expect(find.textContaining('legacy1'), findsNothing);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('settlement summary names a former traveler, not an ID', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1600));
      await tester.pumpWidget(
        budgetTestApp(
          BudgetUserSettlementSummary(api: legacyApi(), displayCurrency: 'EUR'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Ex viaggiatore'), findsWidgets);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('dashboard trend uses createdAt for old expenses', (
      tester,
    ) async {
      await setScreen(tester, const Size(1200, 1800));
      await tester.pumpWidget(
        budgetTestApp(
          BudgetCategoryDashboard(
            api: legacyApi(),
            mainCurrency: 'EUR',
            displayCurrency: 'EUR',
            filters: const BudgetExpenseFilters(),
            onFiltersChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('b85-trend-chart')), findsOneWidget);
      expect(find.text('Alloggio'), findsOneWidget);
    });
  });
}

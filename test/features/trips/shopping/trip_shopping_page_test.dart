// Test automatici della pagina Shopping: acquisto con per chi, budget e
// prezzo reale, "comprato" dalla card, spesa collegata dal prezzo reale,
// scheda Valigia con voce per persona, spunta e filtro per persona.
// Casi, ad esempio: "new item with budget and real price", "packing per person".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/shopping/trip_shopping_page.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

typedef Stores = (
  FakeSectionStore<TripShoppingItem>,
  FakeSectionStore<TripPackingItem>,
);

Future<Stores> open(
  WidgetTester tester, {
  List<TripShoppingItem> shopping = const [],
  List<TripPackingItem> packing = const [],
  double width = 1000,
}) async {
  bigWindow(tester, width: width);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  final shop = FakeSectionStore<TripShoppingItem>(items: shopping);
  final pack = FakeSectionStore<TripPackingItem>(items: packing);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripShoppingPage(tripId: 't1'),
      overrides: [
        tripShoppingStoreProvider.overrideWithValue(shop),
        tripPackingStoreProvider.overrideWithValue(pack),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (shop, pack);
}

const tea = TripShoppingItem(
  id: 'tea',
  tripId: 't1',
  createdByUid: 'anna',
  name: 'Tè matcha',
  forUid: 'bruno',
  estimatedCostMinorUnits: 1500,
  estimatedCostCurrency: 'JPY',
  actualCostMinorUnits: 1200,
  actualCostCurrency: 'JPY',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('new item with budget and real price', (tester) async {
    final (shop, _) = await open(tester);
    await tapKey(tester, 'shopping-add');
    await tester.enterText(find.byKey(const Key('shopping-name')), 'Kimono');
    await tapKey(tester, 'shopping-for-bruno');
    await tester.enterText(find.byKey(const Key('shopping-where')), 'Gion');
    await tester.enterText(find.byKey(const Key('shopping-budget-cost')), '80');
    await tester.enterText(find.byKey(const Key('shopping-price-cost')), '75');
    await tapKey(tester, 'shopping-save');
    final item = shop.created.single;
    expect(item.forUid, 'bruno');
    expect(item.where, 'Gion');
    expect(item.estimatedCostMinorUnits, 8000);
    expect(item.actualCostMinorUnits, 7500);
    expect(item.bought, isFalse);
  });

  testWidgets(
    'card shows prices; bought from the card; expense from the real price',
    (tester) async {
      final (shop, _) = await open(tester, shopping: [tea]);
      expect(find.text('Per Bruno'), findsOneWidget);
      expect(find.textContaining('Prezzo reale:'), findsOneWidget);
      await tapKey(tester, 'shopping-done-tea');
      expect(shop.updated.single.bought, isTrue);
      await tapKey(tester, 'shopping-expense-create-tea');
      final dialog = tester.widget<BudgetCreateDialog>(
        find.byType(BudgetCreateDialog),
      );
      expect(dialog.initialCategory, 'shopping');
      expect(dialog.initialMinorUnits, 1200);
      expect(dialog.currency, 'JPY');
    },
  );

  testWidgets('packing per person, tick and filter', (tester) async {
    final (_, pack) = await open(
      tester,
      packing: const [
        TripPackingItem(
          id: 'a',
          tripId: 't1',
          createdByUid: 'anna',
          name: 'Adattatore',
        ),
        TripPackingItem(
          id: 'b',
          tripId: 't1',
          createdByUid: 'anna',
          name: 'Calze',
          personUid: 'bruno',
          quantity: 3,
        ),
      ],
    );
    await tester.tap(find.text('Valigia'));
    await tester.pumpAndSettle();
    expect(find.text('Calze × 3'), findsOneWidget);
    expect(find.text('Per tutti'), findsOneWidget);
    await pickFilter(tester, 'packing', 'packing-filter-kind-bruno');
    expect(find.byKey(const Key('packing-card-a')), findsNothing);
    await tapKey(tester, 'packing-done-b');
    expect(pack.updated.single.packed, isTrue);

    await tapKey(tester, 'packing-add');
    await tester.enterText(find.byKey(const Key('packing-name')), 'Ombrello');
    await tester.enterText(find.byKey(const Key('packing-quantity')), '0');
    await tapKey(tester, 'packing-save');
    expect(find.text('Quantità: scrivi un numero da 1 a 99.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('packing-quantity')), '1');
    await tapKey(tester, 'packing-save');
    expect(pack.created.single.name, 'Ombrello');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, shopping: [tea]);
    await tapKey(tester, 'shopping-add');
    expect(tester.takeException(), isNull);
  });
}

// Test automatici dei modelli di shopping e valigia: conversione Firestore,
// comprato/spuntata e controlli (prezzo reale, quantità).
// Casi, ad esempio: "shopping round trip with real price", "packing quantity limits".

import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_codecs.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping round trip with real price', () {
    const codec = TripShoppingItemCodec();
    const item = TripShoppingItem(
      tripId: 't',
      createdByUid: 'anna',
      name: 'Tè',
      forUid: 'bruno',
      where: 'Nishiki',
      bought: true,
      estimatedCostMinorUnits: 1500,
      estimatedCostCurrency: 'JPY',
      actualCostMinorUnits: 1200,
      actualCostCurrency: 'JPY',
      notes: 'Regalo',
      expenseId: 'e1',
    );
    final map = codec.toMap(item);
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(codec.toMap(item.toggled('anna'))['bought'], isFalse);
    expect(codec.problems(item), isEmpty);
    const bad = TripShoppingItem(
      tripId: 't',
      createdByUid: 'anna',
      name: 'Tè',
      actualCostMinorUnits: 0,
      actualCostCurrency: 'JPY',
    );
    expect(codec.problems(bad).single.field, 'actualCost');
  });

  test('packing round trip and quantity limits', () {
    const codec = TripPackingItemCodec();
    const item = TripPackingItem(
      tripId: 't',
      createdByUid: 'anna',
      name: 'Adattatore',
      personUid: 'bruno',
      quantity: 2,
    );
    final map = codec.toMap(item);
    expect(map['packed'], isFalse);
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(codec.fromMap('x', codec.toMap(item.toggled())).packed, isTrue);
    expect(
      codec
          .problems(
            const TripPackingItem(
              tripId: 't',
              createdByUid: 'a',
              name: 'x',
              quantity: 100,
            ),
          )
          .single
          .kind,
      TripSectionProblemKind.other,
    );
  });
}

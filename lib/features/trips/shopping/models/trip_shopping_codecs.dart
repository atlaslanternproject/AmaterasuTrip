// Conversione da e verso Firestore delle voci dello shopping
// (trips/{tripId}/shoppingItems) e della valigia (packingItems), con i
// controlli dei limiti di firestore.rules.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'trip_packing_item.dart';
import 'trip_shopping_item.dart';

(String, String) _base(Map<String, dynamic> data, String id) {
  final tripId = TripSectionFields.readText(data, 'tripId');
  final author = TripSectionFields.readText(data, 'createdByUid');
  if (tripId == null || author == null) {
    throw FormatException('Invalid item $id.');
  }
  return (tripId, author);
}

class TripShoppingItemCodec implements TripSectionCodec<TripShoppingItem> {
  const TripShoppingItemCodec();

  @override
  String get collection => 'shoppingItems';

  @override
  List<String> get optionalKeys => const [
    'forUid',
    'where',
    'estimatedCostMinorUnits',
    'estimatedCostCurrency',
    'actualCostMinorUnits',
    'actualCostCurrency',
    'notes',
    'expenseId',
  ];

  @override
  Map<String, dynamic> toMap(TripShoppingItem item) {
    String? text(String? value) => TripSectionFields.clean(value);
    final actual = item.actualCostCurrency == null
        ? null
        : item.actualCostMinorUnits;
    return {
      'tripId': item.tripId,
      'createdByUid': item.createdByUid,
      'name': item.name.trim(),
      'bought': item.bought,
      'forUid': ?text(item.forUid),
      'where': ?text(item.where),
      ...TripSectionFields.costMap(
        item.estimatedCostMinorUnits,
        item.estimatedCostCurrency,
      ),
      if (actual != null) ...{
        'actualCostMinorUnits': actual,
        'actualCostCurrency': item.actualCostCurrency,
      },
      'notes': ?text(item.notes),
      'expenseId': ?text(item.expenseId),
    };
  }

  @override
  TripShoppingItem fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final (tripId, author) = _base(data, id);
    final name = text('name');
    if (name == null || data['bought'] is! bool) {
      throw FormatException('Invalid shopping item $id.');
    }
    final (cost, currency) = TripSectionFields.readCost(data);
    final actual = data['actualCostMinorUnits'];
    final actualCurrency = text('actualCostCurrency');
    final hasActual = actual is int && actualCurrency != null;
    return TripShoppingItem(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      bought: data['bought'] as bool,
      forUid: text('forUid'),
      where: text('where'),
      estimatedCostMinorUnits: cost,
      estimatedCostCurrency: currency,
      actualCostMinorUnits: hasActual ? actual : null,
      actualCostCurrency: hasActual ? actualCurrency : null,
      notes: text('notes'),
      expenseId: text('expenseId'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripShoppingItem item) {
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name')
      ..maxLength(item.where, TripSectionFields.nameMax, 'where')
      ..maxLength(item.notes, TripSectionFields.notesMax, 'notes');
    c
      ..check(
        TripSectionFields.badCost(
          item.estimatedCostMinorUnits,
          item.estimatedCostCurrency,
        ),
        TripSectionProblemKind.cost,
        'cost',
      )
      ..check(
        TripSectionFields.badCost(
          item.actualCostMinorUnits,
          item.actualCostCurrency,
        ),
        TripSectionProblemKind.cost,
        'actualCost',
      )
      ..check(
        TripSectionFields.badExpenseId(item.expenseId),
        TripSectionProblemKind.expense,
        'expenseId',
      );
    return c.found;
  }
}

class TripPackingItemCodec implements TripSectionCodec<TripPackingItem> {
  const TripPackingItemCodec();

  static const quantityMax = 99;

  @override
  String get collection => 'packingItems';

  @override
  List<String> get optionalKeys => const ['personUid', 'quantity'];

  @override
  Map<String, dynamic> toMap(TripPackingItem item) => {
    'tripId': item.tripId,
    'createdByUid': item.createdByUid,
    'name': item.name.trim(),
    'packed': item.packed,
    'personUid': ?TripSectionFields.clean(item.personUid),
    'quantity': ?item.quantity,
  };

  @override
  TripPackingItem fromMap(String id, Map<String, dynamic> data) {
    final (tripId, author) = _base(data, id);
    final name = TripSectionFields.readText(data, 'name');
    if (name == null || data['packed'] is! bool) {
      throw FormatException('Invalid packing item $id.');
    }
    final quantity = data['quantity'];
    return TripPackingItem(
      id: id,
      tripId: tripId,
      createdByUid: author,
      name: name,
      packed: data['packed'] as bool,
      personUid: TripSectionFields.readText(data, 'personUid'),
      quantity: quantity is int ? quantity : null,
    );
  }

  @override
  List<TripSectionProblem> problems(TripPackingItem item) {
    final quantity = item.quantity;
    final c = TripSectionChecks()
      ..required(item.name, 'name')
      ..maxLength(item.name.trim(), TripSectionFields.nameMax, 'name');
    c.check(
      quantity != null && (quantity < 1 || quantity > quantityMax),
      TripSectionProblemKind.other,
      'quantity',
    );
    return c.found;
  }
}

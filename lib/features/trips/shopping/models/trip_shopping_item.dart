// Una voce dello shopping del viaggio: cosa, per chi (un viaggiatore),
// dove, budget stimato, comprato sì/no, prezzo reale, note e spesa
// collegata.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripShoppingItem implements TripSectionItem {
  const TripShoppingItem({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    this.forUid,
    this.where,
    this.bought = false,
    this.estimatedCostMinorUnits,
    this.estimatedCostCurrency,
    this.actualCostMinorUnits,
    this.actualCostCurrency,
    this.notes,
    this.expenseId,
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String name;

  /// Traveler the item is for; null = for everyone / not set.
  final String? forUid;

  /// Shop or area, free text.
  final String? where;
  final bool bought;

  /// Estimated budget.
  final int? estimatedCostMinorUnits;
  final String? estimatedCostCurrency;

  /// Real price paid.
  final int? actualCostMinorUnits;
  final String? actualCostCurrency;
  final String? notes;
  @override
  final String? expenseId;

  @override
  String get displayName => name;

  TripShoppingItem toggled() => TripShoppingItem(
    id: id,
    tripId: tripId,
    createdByUid: createdByUid,
    name: name,
    forUid: forUid,
    where: where,
    bought: !bought,
    estimatedCostMinorUnits: estimatedCostMinorUnits,
    estimatedCostCurrency: estimatedCostCurrency,
    actualCostMinorUnits: actualCostMinorUnits,
    actualCostCurrency: actualCostCurrency,
    notes: notes,
    expenseId: expenseId,
  );
}

// Una voce dello shopping del viaggio: cosa, per chi (un viaggiatore e/o
// un destinatario scritto liberamente), priorità SS/S/A/B, dove, budget
// stimato, comprato sì/no e da chi, prezzo reale, note e spesa collegata.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripShoppingItem implements TripSectionItem {
  const TripShoppingItem({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    this.forUid,
    this.forText,
    this.priority,
    this.where,
    this.bought = false,
    this.boughtByUid,
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

  /// Free recipient, e.g. "Grandma" (also someone outside the trip).
  final String? forText;

  /// SS, S, A or B (TripSectionPriority).
  final String? priority;

  /// Shop or area, free text.
  final String? where;
  final bool bought;

  /// Traveler who bought it (set when it is marked as bought).
  final String? boughtByUid;

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

  /// Marks as bought by [uid], or back to "to buy".
  TripShoppingItem toggled(String? uid) => TripShoppingItem(
    id: id,
    tripId: tripId,
    createdByUid: createdByUid,
    name: name,
    forUid: forUid,
    forText: forText,
    priority: priority,
    where: where,
    bought: !bought,
    boughtByUid: bought ? null : uid,
    estimatedCostMinorUnits: estimatedCostMinorUnits,
    estimatedCostCurrency: estimatedCostCurrency,
    actualCostMinorUnits: actualCostMinorUnits,
    actualCostCurrency: actualCostCurrency,
    notes: notes,
    expenseId: expenseId,
  );
}

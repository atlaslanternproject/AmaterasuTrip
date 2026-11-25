// Stato modificabile dell'editor dello shopping: cosa, per chi (un
// viaggiatore e/o un destinatario scritto liberamente), priorità, dove,
// comprato (e da chi), budget stimato, prezzo reale e note. Si trasforma
// in TripShoppingItem.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_links_field.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';

class TripShoppingDraft {
  TripShoppingDraft(this._initial, String currency)
    : name = TextEditingController(text: _initial?.name),
      where = TextEditingController(text: _initial?.where),
      notes = TextEditingController(text: _initial?.notes),
      forText = TextEditingController(text: _initial?.forText),
      forUid = _initial?.forUid,
      priority = _initial?.priority,
      bought = _initial?.bought ?? false,
      budget = TripSectionCostDraft(
        minorUnits: _initial?.estimatedCostMinorUnits,
        currency: _initial?.estimatedCostCurrency,
        fallback: currency,
      ),
      price = TripSectionCostDraft(
        minorUnits: _initial?.actualCostMinorUnits,
        currency: _initial?.actualCostCurrency,
        fallback: currency,
      );

  final TripShoppingItem? _initial;
  final TextEditingController name;
  final TextEditingController where;
  final TextEditingController notes;
  final TextEditingController forText;
  String? forUid;
  String? priority;
  bool bought;
  final TripSectionCostDraft budget;
  final TripSectionCostDraft price;

  /// Useful links, as in the bucket list.
  late final links = AmaterasuLinksDraft(_initial?.usefulLinks ?? const []);

  bool get isNew => _initial == null;

  TripShoppingItem toItem({required String tripId, required String authorUid}) {
    final initial = _initial;
    // Who bought it: kept when already bought, otherwise whoever saves.
    final boughtBy = !bought
        ? null
        : (initial?.bought == true ? initial?.boughtByUid : authorUid);
    return TripShoppingItem(
      id: initial?.id ?? '',
      tripId: tripId,
      createdByUid: initial?.createdByUid ?? authorUid,
      name: name.text.trim(),
      forUid: forUid,
      forText: TripSectionFields.clean(forText.text),
      priority: priority,
      where: TripSectionFields.clean(where.text),
      bought: bought,
      boughtByUid: boughtBy,
      estimatedCostMinorUnits: budget.minorUnits,
      estimatedCostCurrency: budget.savedCurrency,
      actualCostMinorUnits: price.minorUnits,
      actualCostCurrency: price.savedCurrency,
      notes: TripSectionFields.clean(notes.text),
      expenseId: initial?.expenseId,
      usefulLinks: links.links,
    );
  }

  void dispose() {
    links.dispose();
    for (final c in [name, where, notes, forText]) {
      c.dispose();
    }
    budget.dispose();
    price.dispose();
  }
}

// Shopping e valigia nelle viste: come appare una voce da comprare (per
// chi, dove, budget stimato, prezzo reale, comprato) e una voce della
// valigia (per chi, quantità, messa in valigia), più la casella da spuntare.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

TripSectionEntry tripShoppingEntry(
  BuildContext context,
  TripShoppingItem item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  String? money(int? minor, String? currency) =>
      minor == null || currency == null
      ? null
      : BudgetMoneyFormatter.format(minor, currency);
  final budget = money(
    item.estimatedCostMinorUnits,
    item.estimatedCostCurrency,
  );
  final price = money(item.actualCostMinorUnits, item.actualCostCurrency);
  final forUid = item.forUid;
  return TripSectionEntry(
    id: item.id,
    icon: Icons.shopping_bag_outlined,
    title: item.name,
    subtitle: item.where,
    highlight: forUid == null ? null : l10n.shoppingForValue(nameOf(forUid)),
    inactive: item.bought,
    chips: [
      TripSectionChip(
        label: item.bought ? l10n.shoppingBought : l10n.shoppingToBuy,
        color: item.bought
            ? AmaterasuColors.success
            : AmaterasuColors.accentGold,
      ),
    ],
    lines: [
      if (budget != null)
        TripSectionLine(
          Icons.savings_outlined,
          l10n.shoppingBudgetValue(budget),
        ),
      if (price != null)
        TripSectionLine(
          Icons.payments_outlined,
          l10n.shoppingPriceValue(price),
        ),
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
  );
}

TripSectionEntry tripPackingEntry(
  BuildContext context,
  TripPackingItem item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  final person = item.personUid;
  final quantity = item.quantity;
  return TripSectionEntry(
    id: item.id,
    icon: Icons.luggage_outlined,
    title: quantity == null || quantity == 1
        ? item.name
        : '${item.name} × $quantity',
    highlight: person == null
        ? l10n.packingForEveryone
        : l10n.shoppingForValue(nameOf(person)),
    inactive: item.packed,
    chips: [
      TripSectionChip(
        label: item.packed ? l10n.packingPacked : l10n.packingToPack,
        color: item.packed
            ? AmaterasuColors.success
            : AmaterasuColors.accentGold,
      ),
    ],
  );
}

/// "Comprato" / "In valigia" box in the big card.
class TripSectionDoneBox extends StatelessWidget {
  const TripSectionDoneBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AmaterasuColors.accentBudget,
      value: value,
      onChanged: (_) => onChanged(),
      title: Text(
        label,
        style: const TextStyle(
          color: AmaterasuColors.textPrimary,
          fontSize: 14,
        ),
      ),
    ),
  );
}

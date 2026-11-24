// Blocco "Allergeni e dieta" dell'editor di un ristorante: i 14 allergeni
// UE da segnalare (spuntabili), una nota libera e le etichette di dieta.
// Valgono per il ristorante, non per le singole persone.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_food.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_restaurant_food_labels.dart';

class TripRestaurantFoodBlock extends StatelessWidget {
  const TripRestaurantFoodBlock({
    super.key,
    required this.allergens,
    required this.diets,
    required this.notes,
    required this.onChanged,
  });

  final Set<String> allergens;
  final Set<String> diets;
  final TextEditingController notes;
  final VoidCallback onChanged;

  Widget _chips(
    String prefix,
    List<String> codes,
    Set<String> selected,
    String Function(String) label,
  ) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final code in codes)
        FilterChip(
          key: Key('$prefix-$code'),
          label: Text(label(code)),
          selected: selected.contains(code),
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (on) {
            on ? selected.add(code) : selected.remove(code);
            onChanged();
          },
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionBlock(
      title: l10n.restaurantBlockFood,
      icon: Icons.no_food_outlined,
      summary: [
        ...allergens.map((c) => TripRestaurantFoodLabels.allergen(c, l10n)),
        ...diets.map((c) => TripRestaurantFoodLabels.diet(c, l10n)),
      ].join(', '),
      children: [
        Text(l10n.restaurantAllergensHint),
        const SizedBox(height: 8),
        _chips(
          'restaurant-allergen',
          TripRestaurantFood.allergens,
          allergens,
          (c) => TripRestaurantFoodLabels.allergen(c, l10n),
        ),
        TextField(
          key: const Key('restaurant-allergen-notes'),
          controller: notes,
          maxLength: TripRestaurantFood.notesMax,
          decoration: InputDecoration(labelText: l10n.restaurantAllergenNotes),
        ),
        Text(l10n.restaurantDiets),
        const SizedBox(height: 8),
        _chips(
          'restaurant-diet',
          TripRestaurantFood.diets,
          diets,
          (c) => TripRestaurantFoodLabels.diet(c, l10n),
        ),
      ],
    );
  }
}

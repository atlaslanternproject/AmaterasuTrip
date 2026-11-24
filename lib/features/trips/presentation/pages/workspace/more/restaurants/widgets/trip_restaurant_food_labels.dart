// Nomi degli allergeni UE e delle diete dei ristoranti nella lingua
// dell'app, dai codici salvati in TripRestaurantFood.

import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripRestaurantFoodLabels {
  static String allergen(String code, AppLocalizations l10n) => switch (code) {
    'gluten' => l10n.allergenGluten,
    'crustaceans' => l10n.allergenCrustaceans,
    'eggs' => l10n.allergenEggs,
    'fish' => l10n.allergenFish,
    'peanuts' => l10n.allergenPeanuts,
    'soy' => l10n.allergenSoy,
    'milk' => l10n.allergenMilk,
    'nuts' => l10n.allergenNuts,
    'celery' => l10n.allergenCelery,
    'mustard' => l10n.allergenMustard,
    'sesame' => l10n.allergenSesame,
    'sulphites' => l10n.allergenSulphites,
    'lupin' => l10n.allergenLupin,
    'molluscs' => l10n.allergenMolluscs,
    _ => code,
  };

  static String diet(String code, AppLocalizations l10n) => switch (code) {
    'vegetarian' => l10n.dietVegetarian,
    'vegan' => l10n.dietVegan,
    'halal' => l10n.dietHalal,
    'kosher' => l10n.dietKosher,
    'glutenFree' => l10n.dietGlutenFree,
    _ => code,
  };
}

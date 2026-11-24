// Allergeni e diete dei ristoranti: i 14 allergeni del regolamento UE
// 1169/2011 da segnalare al ristorante e le etichette di dieta. Sono del
// ristorante, mai delle singole persone. I codici sono quelli salvati.

abstract final class TripRestaurantFood {
  static const allergens = [
    'gluten',
    'crustaceans',
    'eggs',
    'fish',
    'peanuts',
    'soy',
    'milk',
    'nuts',
    'celery',
    'mustard',
    'sesame',
    'sulphites',
    'lupin',
    'molluscs',
  ];

  static const diets = ['vegetarian', 'vegan', 'halal', 'kosher', 'glutenFree'];

  static const notesMax = 500;

  /// Known codes from a saved list, in the fixed order, without repeats.
  static List<String> read(Object? raw, List<String> known) {
    if (raw is! List) return const [];
    final found = raw.whereType<String>().toSet();
    return [
      for (final code in known)
        if (found.contains(code)) code,
    ];
  }
}

// Categorie personalizzate delle sezioni (Extra D), con lo stesso
// meccanismo della bucket list: etichette scritte a mano e suggerite da
// quelle già usate nel viaggio. Selezione multipla: fino a 5 per elemento,
// salvate nel campo customCategories; controllate anche da firestore.rules.

abstract final class TripSectionCategories {
  static const key = 'customCategories';
  static const max = 5;
  static const labelMax = 60;

  /// Trimmed label without the "|" used by the rules check.
  static String clean(String label) =>
      label.replaceAll('|', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Document id of a label in trips/{tripId}/sectionCategories.
  static String idOf(String label) {
    final slug = clean(label)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safe = slug.isEmpty ? 'c' : slug;
    return safe.length > 80 ? safe.substring(0, 80) : safe;
  }

  static Map<String, dynamic> toMap(List<String> labels) {
    final saved = [
      for (final l in labels)
        if (clean(l).isNotEmpty) clean(l),
    ];
    return saved.isEmpty ? const {} : {key: saved};
  }

  static List<String> read(Map<String, dynamic> data) => [
    if (data[key] is List)
      for (final l in data[key] as List)
        if (l is String && l.trim().isNotEmpty) l,
  ];

  static bool invalid(List<String> labels) =>
      labels.length > max ||
      labels.any((l) => clean(l).isEmpty || clean(l).length > labelMax);
}

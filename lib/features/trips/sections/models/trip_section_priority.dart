// Priorità delle sezioni con gli stessi livelli della bucket list (SS, S,
// A, B): un solo modulo per luoghi salvati, shopping e le prossime sezioni,
// con l'ordine dal più al meno importante.

abstract final class TripSectionPriority {
  static const levels = ['SS', 'S', 'A', 'B'];

  /// 0 for SS ... 3 for B; items without priority go last.
  static int rank(String? priority) {
    final index = levels.indexOf(priority ?? '');
    return index < 0 ? levels.length : index;
  }
}

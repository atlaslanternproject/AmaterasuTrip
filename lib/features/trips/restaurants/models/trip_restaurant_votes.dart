// Voti dei viaggiatori su un ristorante, con la stessa idea della bucket
// list: ogni membro sceglie una priorità SS, S, A o B (o nessuna). Qui il
// conteggio per livello e la media per ordinare.

abstract final class TripRestaurantVotes {
  /// From the most to the least wanted.
  static const levels = ['SS', 'S', 'A', 'B'];

  static int score(String level) => switch (level) {
    'SS' => 4,
    'S' => 3,
    'A' => 2,
    'B' => 1,
    _ => 0,
  };

  /// Votes for each level, in [levels] order.
  static Map<String, int> counts(Map<String, String> votes) => {
    for (final level in levels)
      level: votes.values.where((v) => v == level).length,
  };

  /// Average score (0 without votes), used to sort by votes.
  static double average(Map<String, String> votes) {
    final scores = votes.values.map(score).where((s) => s > 0).toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Saved votes from a document: only known levels and string keys.
  static Map<String, String> read(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && levels.contains(entry.value))
          entry.key as String: entry.value as String,
    };
  }
}

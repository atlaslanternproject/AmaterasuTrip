/// B8.6: traveler names in financial records.
///
/// Order: current trip member name, then the name recorded inside the
/// expense when the traveler took part (`participantNames`, written by
/// the Cloud Functions), then [fallback]. An internal ID is never shown.
abstract final class BudgetPeople {
  /// Names recorded inside one expense document.
  static Map<String, String> recorded(Map<String, dynamic>? expense) {
    final raw = expense?['participantNames'];
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String &&
            entry.value is String &&
            (entry.value as String).trim().isNotEmpty)
          entry.key as String: (entry.value as String).trim(),
    };
  }

  /// Names recorded across several expense documents.
  static Map<String, String> recordedAll(
    Iterable<Map<String, dynamic>> expenses,
  ) => {for (final expense in expenses) ...recorded(expense)};

  static String name(
    String uid, {
    required Map<String, String> live,
    Map<String, dynamic>? expense,
    Map<String, String> recordedNames = const {},
    required String fallback,
  }) {
    final current = live[uid]?.trim();
    if (current != null && current.isNotEmpty) return current;
    final stored = recorded(expense)[uid] ?? recordedNames[uid];
    if (stored != null && stored.isNotEmpty) return stored;
    return fallback;
  }

  /// A traveler who appears in the expense but is no longer a member.
  static bool isFormer(String uid, Set<String> activeUids) =>
      !activeUids.contains(uid);
}

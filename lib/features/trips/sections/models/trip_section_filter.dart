// Filtro comune delle sezioni: stato, categoria (o tipo), categoria
// personalizzata, prossimi o passati rispetto a oggi e ordine per data,
// dal primo o dall'ultimo.
// "all" = nessun filtro; gli elementi senza data vanno in fondo.

class TripSectionFilter {
  const TripSectionFilter({
    this.status = 'all',
    this.kind = 'all',
    this.when = 'all',
    this.latestFirst = false,
    this.custom = 'all',
  });

  final String status;
  final String kind;

  /// 'all', 'upcoming' or 'past'.
  final String when;
  final bool latestFirst;

  /// Custom category label (Extra D), or 'all'.
  final String custom;

  TripSectionFilter copyWith({
    String? status,
    String? kind,
    String? when,
    bool? latestFirst,
    String? custom,
  }) => TripSectionFilter(
    status: status ?? this.status,
    kind: kind ?? this.kind,
    when: when ?? this.when,
    latestFirst: latestFirst ?? this.latestFirst,
    custom: custom ?? this.custom,
  );

  /// No filters, same order.
  TripSectionFilter cleared() => TripSectionFilter(latestFirst: latestFirst);

  List<T> apply<T>(
    List<T> items, {
    required DateTime today,
    required DateTime? Function(T item) dayOf,
    String? Function(T item)? timeOf,
    String Function(T item)? statusOf,
    String Function(T item)? kindOf,
    List<String> Function(T item)? categoriesOf,
  }) {
    final start = DateTime(today.year, today.month, today.day);
    bool matches(T item) {
      final day = dayOf(item);
      final past = day != null && day.isBefore(start);
      return (status == 'all' || statusOf?.call(item) == status) &&
          (kind == 'all' || kindOf?.call(item) == kind) &&
          (when == 'all' || (when == 'past') == past) &&
          (custom == 'all' ||
              (categoriesOf?.call(item).contains(custom) ?? false));
    }

    int compare(T a, T b) {
      final dayA = dayOf(a);
      final dayB = dayOf(b);
      if (dayA == null || dayB == null) {
        return dayA == null ? (dayB == null ? 0 : 1) : -1;
      }
      final byDay = latestFirst ? dayB.compareTo(dayA) : dayA.compareTo(dayB);
      if (byDay != 0) return byDay;
      final timeA = timeOf?.call(a) ?? '';
      final timeB = timeOf?.call(b) ?? '';
      return latestFirst ? timeB.compareTo(timeA) : timeA.compareTo(timeB);
    }

    return items.where(matches).toList()..sort(compare);
  }
}

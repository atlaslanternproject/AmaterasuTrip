// Filtri e ordine dei trasporti: stato, tipo, prossimi o passati (rispetto
// a oggi, per giorno di partenza) e ordine per partenza, dal primo o
// dall'ultimo. "all" = nessun filtro.

import 'trip_transport.dart';

class TripTransportsFilter {
  const TripTransportsFilter({
    this.status = 'all',
    this.type = 'all',
    this.when = 'all',
    this.latestFirst = false,
  });

  final String status;
  final String type;

  /// 'all', 'upcoming' or 'past'.
  final String when;
  final bool latestFirst;

  TripTransportsFilter copyWith({
    String? status,
    String? type,
    String? when,
    bool? latestFirst,
  }) => TripTransportsFilter(
    status: status ?? this.status,
    type: type ?? this.type,
    when: when ?? this.when,
    latestFirst: latestFirst ?? this.latestFirst,
  );

  bool matches(TripTransport item, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final last = item.arrivalDate ?? item.departureDate;
    return (status == 'all' || item.status.code == status) &&
        (type == 'all' || item.type.code == type) &&
        (when == 'all' ||
            (when == 'upcoming' && !last.isBefore(day)) ||
            (when == 'past' && last.isBefore(day)));
  }

  List<TripTransport> apply(List<TripTransport> items, DateTime today) {
    final shown = items.where((item) => matches(item, today)).toList()
      ..sort((a, b) {
        final byDay = a.departureDate.compareTo(b.departureDate);
        if (byDay != 0) return byDay;
        return (a.departureTime ?? '').compareTo(b.departureTime ?? '');
      });
    return latestFirst ? shown.reversed.toList() : shown;
  }
}

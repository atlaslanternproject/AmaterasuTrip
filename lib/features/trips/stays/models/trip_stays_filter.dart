// Filtri e ordinamento dell'elenco degli alloggi: per stato, per tipo di
// alloggio, prossimi o passati, e data di check-in crescente o
// decrescente. Logica pura, senza grafica, facile da provare.

import 'trip_stay.dart';
import 'trip_stay_status.dart';
import 'trip_stay_type.dart';

enum TripStaysWhen { all, upcoming, past }

enum TripStaysSort { checkInAsc, checkInDesc }

class TripStaysFilter {
  const TripStaysFilter({
    this.statuses = const {},
    this.types = const {},
    this.when = TripStaysWhen.all,
    this.sort = TripStaysSort.checkInAsc,
  });

  /// Empty = every status.
  final Set<TripStayStatus> statuses;

  /// Empty = every type (also stays without a type).
  final Set<TripStayType> types;
  final TripStaysWhen when;
  final TripStaysSort sort;

  /// How many filters are on (the order is not a filter).
  int get activeCount =>
      (statuses.isEmpty ? 0 : 1) +
      (types.isEmpty ? 0 : 1) +
      (when == TripStaysWhen.all ? 0 : 1);

  bool get isActive => activeCount > 0;

  /// Same order, no filters.
  TripStaysFilter cleared() => TripStaysFilter(sort: sort);

  TripStaysFilter copyWith({
    Set<TripStayStatus>? statuses,
    Set<TripStayType>? types,
    TripStaysWhen? when,
    TripStaysSort? sort,
  }) => TripStaysFilter(
    statuses: statuses ?? this.statuses,
    types: types ?? this.types,
    when: when ?? this.when,
    sort: sort ?? this.sort,
  );

  /// A stay is "upcoming" until its check-out day (today included), then
  /// "past". [today] is a calendar day.
  bool matches(TripStay stay, DateTime today) {
    if (statuses.isNotEmpty && !statuses.contains(stay.status)) return false;
    final type = stay.type;
    if (types.isNotEmpty && (type == null || !types.contains(type))) {
      return false;
    }
    final past = stay.checkOutDate.isBefore(today);
    return switch (when) {
      TripStaysWhen.all => true,
      TripStaysWhen.upcoming => !past,
      TripStaysWhen.past => past,
    };
  }

  /// The stays to show, filtered and sorted (same day: by name).
  List<TripStay> apply(List<TripStay> stays, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final shown = stays.where((stay) => matches(stay, day)).toList()
      ..sort((a, b) {
        final byDay = a.checkInDate.compareTo(b.checkInDate);
        if (byDay == 0) return a.name.compareTo(b.name);
        return sort == TripStaysSort.checkInAsc ? byDay : -byDay;
      });
    return shown;
  }
}

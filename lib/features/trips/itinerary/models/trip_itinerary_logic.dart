// Calcoli dell'Itinerario (solo funzioni pure): giorni del viaggio, voci
// di un giorno in ordine (ora, poi ordine a mano), gruppi per zona in
// ordine di orario della prima voce, sovrapposizioni, giorni senza voci e
// distanza in linea d'aria tra due tappe (formula dell'emisenoverso).

import 'dart:math' as math;

import 'trip_itinerary_item.dart';

abstract final class TripItineraryLogic {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Every day from [start] to [end] included.
  static List<DateTime> days(DateTime start, DateTime end) {
    final out = <DateTime>[];
    for (var d = dateOnly(start); !d.isAfter(dateOnly(end));) {
      out.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }

  static int _minutes(String? hhmm) {
    if (hhmm == null || hhmm.length < 5) return 24 * 60;
    return int.parse(hhmm.substring(0, 2)) * 60 +
        int.parse(hhmm.substring(3, 5));
  }

  static int compare(TripItineraryItem a, TripItineraryItem b) {
    final byTime = _minutes(a.time).compareTo(_minutes(b.time));
    return byTime != 0 ? byTime : a.order.compareTo(b.order);
  }

  /// Items of [day] in order (free days first).
  static List<TripItineraryItem> ofDay(
    List<TripItineraryItem> items,
    DateTime day,
  ) {
    final d = dateOnly(day);
    return items.where((i) => dateOnly(i.day) == d).toList()..sort((a, b) {
      final free =
          (b.kind == TripItineraryKind.freeDay ? 1 : 0) -
          (a.kind == TripItineraryKind.freeDay ? 1 : 0);
      return free != 0 ? free : compare(a, b);
    });
  }

  /// Zone groups of one day, by the time of their first item; items
  /// without a zone form the group with a null key.
  static List<(String?, List<TripItineraryItem>)> zones(
    List<TripItineraryItem> dayItems,
  ) {
    final groups = <String?, List<TripItineraryItem>>{};
    for (final item in dayItems) {
      groups.putIfAbsent(item.zone, () => []).add(item);
    }
    final list = groups.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => compare(a.$2.first, b.$2.first));
    return list;
  }

  /// Pairs of timed items of the same day whose times are equal or that
  /// start less than an hour apart (no end times in the draft).
  static List<(TripItineraryItem, TripItineraryItem)> overlaps(
    List<TripItineraryItem> dayItems,
  ) {
    final timed = dayItems.where((i) => i.time != null).toList()..sort(compare);
    return [
      for (var i = 0; i + 1 < timed.length; i++)
        if (_minutes(timed[i + 1].time) - _minutes(timed[i].time) < 60)
          (timed[i], timed[i + 1]),
    ];
  }

  /// Trip days without any item.
  static List<DateTime> emptyDays(
    List<TripItineraryItem> items,
    List<DateTime> tripDays,
  ) => [
    for (final d in tripDays)
      if (ofDay(items, d).isEmpty) d,
  ];

  /// Straight-line distance in km between two places with a position.
  static double? distanceKm(TripItineraryPlace? a, TripItineraryPlace? b) {
    if (a == null || b == null || !a.hasPosition || !b.hasPosition) {
      return null;
    }
    double rad(double v) => v * math.pi / 180;
    final dLat = rad(b.latitude! - a.latitude!);
    final dLng = rad(b.longitude! - a.longitude!);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude!)) *
            math.cos(rad(b.latitude!)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * 6371 * math.asin(math.sqrt(h));
  }

  /// "1.2 km" or "0.7 mi" with the unit chosen in Aspetto.
  static String distanceLabel(double km, String units) {
    final value = units == 'mi' ? km / 1.609344 : km;
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units == 'mi' ? 'mi' : 'km'}';
  }
}

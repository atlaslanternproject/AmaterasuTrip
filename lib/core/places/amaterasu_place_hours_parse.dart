// Modulo Luogo condiviso: legge orari, livello e fascia di prezzo dalla
// risposta JSON di web/amaterasu_place_info.js. Separato dal caricatore
// web così i test lo provano senza browser.

import 'amaterasu_place_hours.dart';

int? _minute(Object? t) {
  if (t is! Map) return null;
  final day = t['day'];
  final hour = t['hour'];
  final minute = t['minute'];
  if (day is! num || hour is! num) return null;
  return day.toInt() * 1440 +
      hour.toInt() * 60 +
      (minute is num ? minute.toInt() : 0);
}

AmaterasuPlaceHours parsePlaceHours(Object? raw) {
  if (raw is! Map) return const AmaterasuPlaceHours();
  final text = raw['text'];
  final periods = <AmaterasuOpenPeriod>[];
  for (final p in raw['periods'] is List ? raw['periods'] as List : []) {
    if (p is! Map) continue;
    final start = _minute(p['open']);
    if (start == null) continue;
    periods.add(AmaterasuOpenPeriod(start, _minute(p['close'])));
  }
  return AmaterasuPlaceHours(
    weekdayText: [
      if (text is List)
        for (final line in text)
          if (line is String && line.trim().isNotEmpty) line.trim(),
    ],
    periods: periods,
  );
}

/// Google's PriceLevel names to 0 (free) .. 4 (very expensive).
int? parsePriceLevel(Object? raw) => switch (raw) {
  'FREE' => 0,
  'INEXPENSIVE' => 1,
  'MODERATE' => 2,
  'EXPENSIVE' => 3,
  'VERY_EXPENSIVE' => 4,
  _ => null,
};

AmaterasuPriceRange? parsePriceRange(Object? raw) {
  if (raw is! Map) return null;
  final start = raw['start'];
  final end = raw['end'];
  String? currency;
  int? units(Object? m) {
    if (m is! Map) return null;
    final c = m['currency'];
    if (c is String && RegExp(r'^[A-Z]{3}$').hasMatch(c)) currency ??= c;
    final u = m['units'];
    return u is num && u.isFinite ? u.toInt() : null;
  }

  final from = units(start);
  final to = units(end);
  final code = currency;
  if (code == null || (from == null && to == null)) return null;
  return AmaterasuPriceRange(currency: code, start: from, end: to);
}

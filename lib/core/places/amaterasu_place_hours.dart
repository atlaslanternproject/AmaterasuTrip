// Modulo Luogo condiviso: orari di apertura e fascia di prezzo di un luogo
// Google (letti al momento, mai salvati) e il controllo "è chiuso quel
// giorno / a quell'ora?" usato per l'avviso dei ristoranti.

/// One opening period in minutes from Sunday 00:00 (Google's week).
class AmaterasuOpenPeriod {
  const AmaterasuOpenPeriod(this.start, this.end);

  final int start;

  /// Null when the place never closes (open 24/7).
  final int? end;
}

class AmaterasuPlaceHours {
  const AmaterasuPlaceHours({
    this.weekdayText = const [],
    this.periods = const [],
  });

  static const _week = 7 * 1440;

  /// Lines written by Google in the user's language ("lunedì: 12–15").
  final List<String> weekdayText;
  final List<AmaterasuOpenPeriod> periods;

  bool get isEmpty => weekdayText.isEmpty && periods.isEmpty;

  /// (start, end) ranges in week minutes; a range over Saturday night is
  /// also repeated one week earlier so that Sunday morning matches it.
  Iterable<(int, int)> get _ranges sync* {
    for (final p in periods) {
      final end = p.end;
      if (end == null) {
        yield (0, _week);
        continue;
      }
      final fixedEnd = end <= p.start ? end + _week : end;
      yield (p.start, fixedEnd);
      if (fixedEnd > _week) yield (p.start - _week, fixedEnd - _week);
    }
  }

  static int _dayStart(DateTime day) => (day.weekday % 7) * 1440;

  /// True when the place has no opening at all on [day]; null when the
  /// hours are unknown.
  bool? closedOn(DateTime day) {
    if (periods.isEmpty) return null;
    final from = _dayStart(day);
    final to = from + 1440;
    return !_ranges.any((r) => r.$1 < to && r.$2 > from);
  }

  /// True when the place is closed on [day] at [time] ("HH:mm"); null when
  /// the hours or the time are unknown.
  bool? closedAt(DateTime day, String? time) {
    if (periods.isEmpty || time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final t = _dayStart(day) + h * 60 + m;
    return !_ranges.any((r) => r.$1 <= t && t < r.$2);
  }
}

/// Google price range of a place (e.g. 20–30 JPY), in whole units.
class AmaterasuPriceRange {
  const AmaterasuPriceRange({required this.currency, this.start, this.end});

  final String currency;
  final int? start;
  final int? end;
}

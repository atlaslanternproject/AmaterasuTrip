// Dati del Meteo (nuova tappa 1b) come arrivano dalla funzione
// getTripWeather: giorni e ore della previsione, aria e pollini, clima
// tipico del periodo. Orari già nel fuso della destinazione. Solo lettura.

double? _num(Object? v) => v is num ? v.toDouble() : null;
String? _text(Object? v) => v is String ? v : null;
List<Map<Object?, Object?>> _maps(Object? v) =>
    v is List ? v.whereType<Map<Object?, Object?>>().toList() : const [];
Map<Object?, Object?> _map(Object? v) =>
    v is Map<Object?, Object?> ? v : const {};

class TripWeatherDay {
  const TripWeatherDay({
    required this.date,
    this.code,
    this.max,
    this.min,
    this.rain,
    this.precip,
    this.sunrise,
    this.sunset,
    this.uv,
    this.wind,
  });

  factory TripWeatherDay.fromMap(Map<Object?, Object?> m) => TripWeatherDay(
    date: _text(m['date']) ?? '',
    code: _num(m['code'])?.round(),
    max: _num(m['max']),
    min: _num(m['min']),
    rain: _num(m['rain']),
    precip: _num(m['precip']),
    sunrise: _text(m['sunrise']),
    sunset: _text(m['sunset']),
    uv: _num(m['uv']),
    wind: _num(m['wind']),
  );

  /// "YYYY-MM-DD", local day of the destination.
  final String date;
  final int? code;
  final double? max, min, rain, precip, uv, wind;

  /// "YYYY-MM-DDTHH:MM", local time of the destination.
  final String? sunrise, sunset;
}

class TripWeatherHour {
  const TripWeatherHour({
    required this.time,
    this.temp,
    this.rain,
    this.code,
    this.wind,
  });

  factory TripWeatherHour.fromMap(Map<Object?, Object?> m) => TripWeatherHour(
    time: _text(m['time']) ?? '',
    temp: _num(m['temp']),
    rain: _num(m['rain']),
    code: _num(m['code'])?.round(),
    wind: _num(m['wind']),
  );

  final String time;
  final double? temp, rain, wind;
  final int? code;
}

class TripWeatherAirDay {
  const TripWeatherAirDay({
    required this.date,
    this.aqi,
    this.pollen = const {},
  });

  factory TripWeatherAirDay.fromMap(Map<Object?, Object?> m) =>
      TripWeatherAirDay(
        date: _text(m['date']) ?? '',
        aqi: _num(m['aqi']),
        pollen: {
          for (final e in _map(m['pollen']).entries)
            if (e.key is String && e.value is num)
              e.key! as String: (e.value! as num).toDouble(),
        },
      );

  final String date;

  /// European air quality index (0-20 good ... over 100 very poor).
  final double? aqi;

  /// Grains/m³ by kind (alder, birch, grass, mugwort, olive, ragweed).
  final Map<String, double> pollen;
}

class TripWeatherClimate {
  const TripWeatherClimate({
    this.years = const [],
    this.max,
    this.min,
    this.precip,
    this.rainyDays,
  });

  final List<int> years;
  final double? max, min, precip, rainyDays;
}

class TripWeather {
  const TripWeather({
    this.placeName,
    this.countryCode,
    this.tripStart,
    this.tripEnd,
    this.days = const [],
    this.hours = const [],
    this.air = const [],
    this.climate,
    this.fetchedAt,
    this.stale = false,
  });

  factory TripWeather.fromMap(Map<Object?, Object?> m) {
    final place = _map(m['place']);
    final forecast = _map(m['forecast']);
    final air = _map(m['air']);
    final climate = m['climate'] is Map ? _map(m['climate']) : null;
    final fetched = _num(forecast['fetchedAt']);
    return TripWeather(
      placeName: _text(place['name']),
      countryCode: _text(place['countryCode']),
      tripStart: _text(m['tripStart']),
      tripEnd: _text(m['tripEnd']),
      days: _maps(forecast['days']).map(TripWeatherDay.fromMap).toList(),
      hours: _maps(forecast['hours']).map(TripWeatherHour.fromMap).toList(),
      air: _maps(air['days']).map(TripWeatherAirDay.fromMap).toList(),
      climate: climate == null || _num(climate['max']) == null
          ? null
          : TripWeatherClimate(
              years: [
                for (final y in (climate['years'] as List?) ?? const [])
                  if (y is num) y.toInt(),
              ],
              max: _num(climate['max']),
              min: _num(climate['min']),
              precip: _num(climate['precip']),
              rainyDays: _num(climate['rainyDays']),
            ),
      fetchedAt: fetched == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(fetched.toInt()),
      stale: m['stale'] == true,
    );
  }

  final String? placeName, countryCode, tripStart, tripEnd;
  final List<TripWeatherDay> days;
  final List<TripWeatherHour> hours;
  final List<TripWeatherAirDay> air;
  final TripWeatherClimate? climate;
  final DateTime? fetchedAt;
  final bool stale;

  /// Whether [date] (YYYY-MM-DD) falls inside the trip.
  bool inTrip(String date) =>
      tripStart != null &&
      tripEnd != null &&
      date.compareTo(tripStart!) >= 0 &&
      date.compareTo(tripEnd!) <= 0;

  List<TripWeatherHour> hoursOf(String date) =>
      hours.where((h) => h.time.startsWith(date)).toList();

  TripWeatherAirDay? airOf(String date) {
    for (final a in air) {
      if (a.date == date) return a;
    }
    return null;
  }
}

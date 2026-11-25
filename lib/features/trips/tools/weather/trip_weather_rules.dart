// Regole fisse del Meteo (senza AI): gruppi dei codici meteo WMO, cosa
// mettere in valigia per il giorno (temperatura, pioggia, neve, vento,
// raggi UV), livelli della qualità dell'aria europea e dei pollini.

enum TripWeatherSky { clear, partly, cloudy, fog, drizzle, rain, snow, storm }

/// WMO weather code (Open-Meteo) to a group with its own icon and label.
TripWeatherSky? tripWeatherSkyOf(int? code) => switch (code) {
  null => null,
  0 => TripWeatherSky.clear,
  1 || 2 => TripWeatherSky.partly,
  3 => TripWeatherSky.cloudy,
  45 || 48 => TripWeatherSky.fog,
  >= 51 && <= 57 => TripWeatherSky.drizzle,
  >= 61 && <= 67 || >= 80 && <= 82 => TripWeatherSky.rain,
  >= 71 && <= 77 || 85 || 86 => TripWeatherSky.snow,
  >= 95 && <= 99 => TripWeatherSky.storm,
  _ => null,
};

enum TripWeatherWear {
  light,
  sunHat,
  tshirt,
  lightLayer,
  sweater,
  warmCoat,
  heavyCoat,
  hatGloves,
  umbrella,
  boots,
  windproof,
  sunscreen,
}

/// Fixed clothing advice for a day: one rule for the warmth, then rain,
/// snow, wind and sun. Empty when the day has no temperatures.
List<TripWeatherWear> tripWeatherWearOf({
  double? max,
  double? min,
  double? rain,
  double? precip,
  double? wind,
  double? uv,
  int? code,
}) {
  if (max == null) return const [];
  final low = min ?? max;
  final out = <TripWeatherWear>[
    if (max >= 28) ...[TripWeatherWear.light, TripWeatherWear.sunHat],
    if (max >= 20 && max < 28) TripWeatherWear.tshirt,
    if (max >= 20 && max < 28 && low < 15) TripWeatherWear.lightLayer,
    if (max >= 12 && max < 20) TripWeatherWear.sweater,
    if (max >= 5 && max < 12) TripWeatherWear.warmCoat,
    if (max < 5) ...[TripWeatherWear.heavyCoat, TripWeatherWear.hatGloves],
  ];
  final sky = tripWeatherSkyOf(code);
  if ((rain ?? 0) >= 50 ||
      (precip ?? 0) >= 2 ||
      sky == TripWeatherSky.rain ||
      sky == TripWeatherSky.storm) {
    out.add(TripWeatherWear.umbrella);
  }
  if (sky == TripWeatherSky.snow) out.add(TripWeatherWear.boots);
  if ((wind ?? 0) >= 40) out.add(TripWeatherWear.windproof);
  if ((uv ?? 0) >= 6 && !out.contains(TripWeatherWear.sunHat)) {
    out.add(TripWeatherWear.sunscreen);
  }
  return out;
}

enum TripWeatherLevel { good, fair, moderate, poor, veryPoor }

/// European air quality index bands (EEA): 0-20 good ... over 80 very poor.
TripWeatherLevel tripWeatherAirLevel(double aqi) => aqi <= 20
    ? TripWeatherLevel.good
    : aqi <= 40
    ? TripWeatherLevel.fair
    : aqi <= 60
    ? TripWeatherLevel.moderate
    : aqi <= 80
    ? TripWeatherLevel.poor
    : TripWeatherLevel.veryPoor;

/// Simple pollen bands (grains/m³): under 10 low, up to 50 moderate.
TripWeatherLevel tripWeatherPollenLevel(double grains) => grains < 10
    ? TripWeatherLevel.good
    : grains <= 50
    ? TripWeatherLevel.moderate
    : TripWeatherLevel.poor;

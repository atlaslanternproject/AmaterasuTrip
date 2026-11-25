// Testi e icone del Meteo: cielo (codici WMO), consigli su cosa mettere,
// livelli di aria e pollini, nomi dei pollini e link a 3B Meteo (pagina
// della città per l'Italia, home con la ricerca per l'estero: nessun dato).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_weather_rules.dart';

IconData tripWeatherSkyIcon(TripWeatherSky? sky) => switch (sky) {
  TripWeatherSky.clear => Icons.wb_sunny_outlined,
  TripWeatherSky.partly => Icons.wb_cloudy_outlined,
  TripWeatherSky.cloudy => Icons.cloud_outlined,
  TripWeatherSky.fog => Icons.foggy,
  TripWeatherSky.drizzle => Icons.grain,
  TripWeatherSky.rain => Icons.umbrella_outlined,
  TripWeatherSky.snow => Icons.ac_unit,
  TripWeatherSky.storm => Icons.thunderstorm_outlined,
  null => Icons.help_outline,
};

String tripWeatherSkyLabel(AppLocalizations l10n, TripWeatherSky? sky) =>
    switch (sky) {
      TripWeatherSky.clear => l10n.weatherSkyClear,
      TripWeatherSky.partly => l10n.weatherSkyPartly,
      TripWeatherSky.cloudy => l10n.weatherSkyCloudy,
      TripWeatherSky.fog => l10n.weatherSkyFog,
      TripWeatherSky.drizzle => l10n.weatherSkyDrizzle,
      TripWeatherSky.rain => l10n.weatherSkyRain,
      TripWeatherSky.snow => l10n.weatherSkySnow,
      TripWeatherSky.storm => l10n.weatherSkyStorm,
      null => '-',
    };

String tripWeatherWearLabel(AppLocalizations l10n, TripWeatherWear w) =>
    switch (w) {
      TripWeatherWear.light => l10n.weatherWearLight,
      TripWeatherWear.sunHat => l10n.weatherWearSunHat,
      TripWeatherWear.tshirt => l10n.weatherWearTshirt,
      TripWeatherWear.lightLayer => l10n.weatherWearLightLayer,
      TripWeatherWear.sweater => l10n.weatherWearSweater,
      TripWeatherWear.warmCoat => l10n.weatherWearWarmCoat,
      TripWeatherWear.heavyCoat => l10n.weatherWearHeavyCoat,
      TripWeatherWear.hatGloves => l10n.weatherWearHatGloves,
      TripWeatherWear.umbrella => l10n.weatherWearUmbrella,
      TripWeatherWear.boots => l10n.weatherWearBoots,
      TripWeatherWear.windproof => l10n.weatherWearWindproof,
      TripWeatherWear.sunscreen => l10n.weatherWearSunscreen,
    };

String tripWeatherAirLabel(AppLocalizations l10n, TripWeatherLevel l) =>
    switch (l) {
      TripWeatherLevel.good => l10n.weatherAirGood,
      TripWeatherLevel.fair => l10n.weatherAirFair,
      TripWeatherLevel.moderate => l10n.weatherAirModerate,
      TripWeatherLevel.poor => l10n.weatherAirPoor,
      TripWeatherLevel.veryPoor => l10n.weatherAirVeryPoor,
    };

String tripWeatherPollenLabel(AppLocalizations l10n, TripWeatherLevel l) =>
    switch (l) {
      TripWeatherLevel.good || TripWeatherLevel.fair => l10n.weatherPollenLow,
      TripWeatherLevel.moderate => l10n.weatherPollenMedium,
      _ => l10n.weatherPollenHigh,
    };

String tripWeatherPollenKind(AppLocalizations l10n, String kind) =>
    switch (kind) {
      'alder' => l10n.weatherPollenAlder,
      'birch' => l10n.weatherPollenBirch,
      'grass' => l10n.weatherPollenGrass,
      'mugwort' => l10n.weatherPollenMugwort,
      'olive' => l10n.weatherPollenOlive,
      'ragweed' => l10n.weatherPollenRagweed,
      _ => kind,
    };

const _accents = {
  'à': 'a',
  'á': 'a',
  'è': 'e',
  'é': 'e',
  'ì': 'i',
  'í': 'i',
  'ò': 'o',
  'ó': 'o',
  'ù': 'u',
  'ú': 'u',
  "'": '+',
};

/// 3B Meteo page: "/meteo/roma" for an Italian city; abroad the site needs
/// its own city number, so the home page (with its search) is opened.
String tripWeather3bLink(String? city, String? countryCode) {
  const site = 'https://www.3bmeteo.com';
  final name = (city ?? '').trim().toLowerCase();
  if (countryCode?.toUpperCase() != 'IT') return '$site/';
  if (name.isEmpty) return '$site/meteo/italia';
  final slug = name
      .split('')
      .map((c) => _accents[c] ?? c)
      .join()
      .replaceAll(RegExp(r'\s+'), '+');
  return '$site/meteo/${Uri.encodeComponent(slug).replaceAll('%2B', '+')}';
}

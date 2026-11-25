// Blocchi informativi del Meteo: "Cosa mettere" (regole fisse del giorno
// scelto), "Aria e pollini" (indice europeo e pollini presenti, solo in
// Europa) e "Clima tipico del periodo" (media degli anni passati).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_weather_data.dart';
import 'trip_weather_labels.dart';
import 'trip_weather_rules.dart';

const _text = TextStyle(color: AmaterasuColors.textPrimary);
const _muted = TextStyle(color: AmaterasuColors.textMuted, fontSize: 12);
String _n(double? v) => v == null ? '-' : '${v.round()}';

class TripWeatherWearBlock extends StatelessWidget {
  const TripWeatherWearBlock({super.key, required this.day});

  final TripWeatherDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wear = tripWeatherWearOf(
      max: day.max,
      min: day.min,
      rain: day.rain,
      precip: day.precip,
      wind: day.wind,
      uv: day.uv,
      code: day.code,
    );
    return TripSectionBlock(
      title: l10n.weatherWear,
      icon: Icons.checkroom_outlined,
      children: [
        for (final w in wear)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${tripWeatherWearLabel(l10n, w)}',
              key: Key('weather-wear-${w.name}'),
              style: _text,
            ),
          ),
        const SizedBox(height: 4),
        Text(l10n.weatherWearNote, style: _muted),
      ],
    );
  }
}

class TripWeatherAirBlock extends StatelessWidget {
  const TripWeatherAirBlock({super.key, required this.air});

  final TripWeatherAirDay? air;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aqi = air?.aqi;
    final pollen = (air?.pollen.entries ?? const <MapEntry<String, double>>[])
        .where((e) => e.value > 0)
        .toList();
    return TripSectionBlock(
      title: l10n.weatherAir,
      icon: Icons.air_outlined,
      initiallyOpen: false,
      children: [
        Text(
          aqi == null
              ? l10n.weatherAirNone
              : l10n.weatherAirIndex(
                  tripWeatherAirLabel(l10n, tripWeatherAirLevel(aqi)),
                  _n(aqi),
                ),
          key: const Key('weather-air'),
          style: _text,
        ),
        const SizedBox(height: 4),
        if (pollen.isEmpty)
          Text(l10n.weatherPollenNone, style: _muted)
        else
          for (final e in pollen)
            Text(
              l10n.weatherPollenLine(
                tripWeatherPollenKind(l10n, e.key),
                tripWeatherPollenLabel(l10n, tripWeatherPollenLevel(e.value)),
              ),
              key: Key('weather-pollen-${e.key}'),
              style: _text,
            ),
      ],
    );
  }
}

class TripWeatherClimateBlock extends StatelessWidget {
  const TripWeatherClimateBlock({super.key, required this.climate});

  final TripWeatherClimate? climate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = climate;
    return TripSectionBlock(
      title: l10n.weatherClimate,
      icon: Icons.thermostat_outlined,
      children: [
        Text(
          c == null
              ? l10n.weatherClimateNone
              : l10n.weatherClimateBody(
                  c.years.join(', '),
                  _n(c.max),
                  _n(c.min),
                  c.precip?.toStringAsFixed(1) ?? '-',
                  _n(c.rainyDays),
                ),
          key: const Key('weather-climate'),
          style: _text,
        ),
      ],
    );
  }
}

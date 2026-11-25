// Righe del Meteo: un giorno della previsione (cielo, massima e minima,
// pioggia, scritta "Viaggio"; si tocca per sceglierlo) e il blocco "Ora per
// ora" del giorno scelto, con alba, tramonto, vento e raggi UV.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_weather_data.dart';
import 'trip_weather_labels.dart';
import 'trip_weather_rules.dart';

String tripWeatherDeg(double? v) => v == null ? '-' : '${v.round()}°';
String _n(double? v) => v == null ? '-' : '${v.round()}';
String _clock(BuildContext context, String? iso) =>
    iso == null || iso.length < 16
    ? '-'
    : AmaterasuDates.time(context, iso.substring(11, 16));
DateTime? _date(String ymd) => DateTime.tryParse(ymd);

String tripWeatherDayLabel(BuildContext context, String ymd) {
  final d = _date(ymd);
  return d == null ? ymd : AmaterasuDates.day(context, d);
}

class TripWeatherDayTile extends StatelessWidget {
  const TripWeatherDayTile({
    super.key,
    required this.day,
    required this.inTrip,
    required this.selected,
    required this.onTap,
  });

  final TripWeatherDay day;
  final bool inTrip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sky = tripWeatherSkyOf(day.code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AmaterasuColors.surfaceRaised : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? AmaterasuColors.primary
                : AmaterasuColors.borderWarm,
          ),
        ),
        child: InkWell(
          key: Key('weather-day-${day.date}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  tripWeatherSkyIcon(sky),
                  color: AmaterasuColors.accentGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tripWeatherDayLabel(context, day.date),
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        tripWeatherSkyLabel(l10n, sky),
                        style: const TextStyle(
                          color: AmaterasuColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (inTrip)
                        Text(
                          l10n.weatherTripDay,
                          key: Key('weather-trip-${day.date}'),
                          style: const TextStyle(
                            color: AmaterasuColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tripWeatherDeg(day.max)} / ${tripWeatherDeg(day.min)}',
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                      ),
                    ),
                    if (day.rain != null)
                      Text(
                        l10n.weatherRainChance(_n(day.rain)),
                        style: const TextStyle(
                          color: AmaterasuColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TripWeatherHoursBlock extends StatelessWidget {
  const TripWeatherHoursBlock({
    super.key,
    required this.day,
    required this.hours,
  });

  final TripWeatherDay day;
  final List<TripWeatherHour> hours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const small = TextStyle(color: AmaterasuColors.textSecondary, fontSize: 12);
    return TripSectionBlock(
      title: l10n.weatherHours(tripWeatherDayLabel(context, day.date)),
      icon: Icons.schedule_outlined,
      children: [
        Text(
          l10n.weatherSun(
            _clock(context, day.sunrise),
            _clock(context, day.sunset),
          ),
          key: const Key('weather-sun'),
          style: const TextStyle(color: AmaterasuColors.textPrimary),
        ),
        Text(l10n.weatherWindUv(_n(day.wind), _n(day.uv)), style: small),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(96),
          child: ListView(
            key: const Key('weather-hours'),
            scrollDirection: Axis.horizontal,
            children: [
              for (final h in hours)
                Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AmaterasuColors.borderWarm),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(_clock(context, h.time), style: small),
                      Icon(
                        tripWeatherSkyIcon(tripWeatherSkyOf(h.code)),
                        size: 18,
                        color: AmaterasuColors.accentGold,
                      ),
                      Text(
                        tripWeatherDeg(h.temp),
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                        ),
                      ),
                      Text(
                        h.rain == null ? '' : '${_n(h.rain)}%',
                        style: small,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

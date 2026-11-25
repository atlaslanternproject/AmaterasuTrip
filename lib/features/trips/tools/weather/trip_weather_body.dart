// Corpo della pagina Meteo: luogo, ora dell'aggiornamento, "Apri su 3B
// Meteo", giorni della previsione (si sceglie un giorno), ore, cosa
// mettere, aria e pollini del giorno scelto, clima tipico e fonte.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_weather_data.dart';
import 'trip_weather_info_blocks.dart';
import 'trip_weather_labels.dart';
import 'trip_weather_tiles.dart';

class TripWeatherBody extends StatefulWidget {
  const TripWeatherBody({super.key, required this.weather});

  final TripWeather weather;

  @override
  State<TripWeatherBody> createState() => _TripWeatherBodyState();
}

class _TripWeatherBodyState extends State<TripWeatherBody> {
  String? _selected;

  TripWeather get _w => widget.weather;

  /// First trip day inside the forecast, otherwise the first day.
  String? get _defaultDay {
    for (final d in _w.days) {
      if (_w.inTrip(d.date)) return d.date;
    }
    return _w.days.isEmpty ? null : _w.days.first.date;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected ?? _defaultDay;
    final day = _w.days.where((d) => d.date == selected).firstOrNull;
    final tripInForecast = _w.days.any((d) => _w.inTrip(d.date));
    const muted = TextStyle(color: AmaterasuColors.textMuted, fontSize: 12);
    final fetched = _w.fetchedAt;
    return ListView(
      key: const Key('weather-page'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (fetched != null)
          Text(
            l10n.weatherUpdated(
              AmaterasuDates.day(context, fetched),
              AmaterasuDates.time(
                context,
                '${fetched.hour.toString().padLeft(2, '0')}:'
                '${fetched.minute.toString().padLeft(2, '0')}',
              ),
            ),
            style: muted,
          ),
        if (_w.stale)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.weatherStale,
              key: const Key('weather-stale'),
              style: const TextStyle(color: AmaterasuColors.accentGold),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AmaterasuLinkChip(
              key: const Key('weather-3b'),
              link: tripWeather3bLink(_w.placeName, _w.countryCode),
              label: l10n.weatherOpen3b,
            ),
          ),
        ),
        TripSectionBlock(
          title: l10n.weatherForecast,
          icon: Icons.calendar_view_week_outlined,
          children: [
            Text(
              tripInForecast || _w.tripStart == null
                  ? l10n.weatherForecastNote(_w.placeName ?? '-')
                  : l10n.weatherTripFar,
              key: const Key('weather-note'),
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final d in _w.days)
              TripWeatherDayTile(
                day: d,
                inTrip: _w.inTrip(d.date),
                selected: d.date == selected,
                onTap: () => setState(() => _selected = d.date),
              ),
          ],
        ),
        if (day != null) ...[
          TripWeatherHoursBlock(day: day, hours: _w.hoursOf(day.date)),
          TripWeatherWearBlock(day: day),
          TripWeatherAirBlock(air: _w.airOf(day.date)),
        ],
        TripWeatherClimateBlock(climate: _w.climate),
        const SizedBox(height: 12),
        Text(
          l10n.weatherSource,
          key: const Key('weather-source'),
          style: muted,
        ),
      ],
    );
  }
}

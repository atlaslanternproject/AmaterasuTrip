// Pagina "Meteo" di Altro (nuova tappa 1b): previsioni della destinazione
// dalla funzione getTripWeather (cache condivisa per viaggio), con stati
// di caricamento ed errore ("Riprova"). Nessun dato salvato dall'app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_weather_body.dart';
import 'trip_weather_provider.dart';

class TripWeatherPage extends ConsumerWidget {
  const TripWeatherPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final weather = ref.watch(tripWeatherProvider(tripId));
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: tripId, title: l10n.weatherTitle),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: weather.when(
                    data: (w) => TripWeatherBody(weather: w),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AmaterasuColors.primary,
                      ),
                    ),
                    error: (error, _) => _TripWeatherError(
                      error: tripWeatherErrorOf(error),
                      onRetry: () =>
                          ref.invalidate(tripWeatherProvider(tripId)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripWeatherError extends StatelessWidget {
  const _TripWeatherError({required this.error, required this.onRetry});

  final TripWeatherError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noPlace = error == TripWeatherError.noDestination;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noPlace ? Icons.location_off_outlined : Icons.cloud_off_outlined,
              color: AmaterasuColors.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              noPlace ? l10n.weatherNoDestination : l10n.weatherUnavailable,
              key: const Key('weather-error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            if (!noPlace) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('weather-retry'),
                onPressed: onRetry,
                child: Text(l10n.weatherRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

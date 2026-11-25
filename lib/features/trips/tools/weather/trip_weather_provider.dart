// Caricamento del Meteo: chiama la funzione getTripWeather una volta per
// viaggio e per sessione (il server tiene la cache condivisa). Nei test si
// sostituisce [tripWeatherLoaderProvider] con dati finti.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trip_weather_data.dart';

typedef TripWeatherLoader =
    Future<Map<Object?, Object?>> Function(String tripId);

Future<Map<Object?, Object?>> _callServer(String tripId) async {
  final result = await FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).httpsCallable('getTripWeather').call<Object?>({'tripId': tripId});
  final data = result.data;
  return data is Map<Object?, Object?> ? data : const {};
}

final tripWeatherLoaderProvider = Provider<TripWeatherLoader>(
  (ref) => _callServer,
);

/// Kept for the whole session: reopening the page makes no new call.
final tripWeatherProvider = FutureProvider.family<TripWeather, String>((
  ref,
  tripId,
) async {
  final load = ref.watch(tripWeatherLoaderProvider);
  return TripWeather.fromMap(await load(tripId));
});

/// Reason of a failed load, for the message on the page.
enum TripWeatherError { noDestination, unavailable }

TripWeatherError tripWeatherErrorOf(Object error) =>
    error is FirebaseFunctionsException && error.message == 'no-destination'
    ? TripWeatherError.noDestination
    : TripWeatherError.unavailable;

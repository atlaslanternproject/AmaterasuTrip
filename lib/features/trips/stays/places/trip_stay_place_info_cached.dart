// Servizio dei dati Google degli alloggi con cache in memoria per tutta la
// sessione: ogni luogo viene chiesto a Google una volta sola (contatti e
// foto separati). Se la richiesta fallisce si riprova solo alla prossima
// apertura della card, non in ciclo.

import 'trip_stay_place_info.dart';
import 'trip_stay_place_loader.dart' as loader;

typedef TripStayContactsLoader =
    Future<TripStayPlaceContacts?> Function(String placeId, String language);
typedef TripStayPhotosLoader =
    Future<List<TripStayPlacePhoto>> Function(String placeId, String language);

class CachedTripStayPlaceInfo implements TripStayPlaceInfoService {
  CachedTripStayPlaceInfo({
    TripStayContactsLoader? loadContacts,
    TripStayPhotosLoader? loadPhotos,
  }) : _loadContacts = loadContacts ?? loader.loadTripStayContacts,
       _loadPhotos = loadPhotos ?? loader.loadTripStayPhotos;

  final TripStayContactsLoader _loadContacts;
  final TripStayPhotosLoader _loadPhotos;
  final _contacts = <String, Future<TripStayPlaceContacts?>>{};
  final _photos = <String, Future<List<TripStayPlacePhoto>>>{};

  Future<T> _cached<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() load,
  ) {
    final existing = cache[key];
    if (existing != null) return existing;
    final future = load();
    cache[key] = future;
    future.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        cache.remove(key);
      },
    );
    return future;
  }

  @override
  Future<TripStayPlaceContacts?> contacts(
    String placeId, {
    required String languageCode,
  }) => _cached(
    _contacts,
    '$placeId|$languageCode',
    () => _loadContacts(placeId, languageCode),
  );

  @override
  Future<List<TripStayPlacePhoto>> photos(
    String placeId, {
    required String languageCode,
  }) => _cached(
    _photos,
    '$placeId|$languageCode',
    () => _loadPhotos(placeId, languageCode),
  );
}

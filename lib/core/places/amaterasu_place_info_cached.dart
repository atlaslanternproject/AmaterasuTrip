// Servizio dei dati Google dei luoghi (alloggi e altre sezioni) con cache in memoria per tutta la
// sessione: ogni luogo viene chiesto a Google una volta sola (contatti e
// foto separati). Se la richiesta fallisce si riprova solo alla prossima
// apertura della card, non in ciclo.

import 'amaterasu_place_info.dart';
import 'amaterasu_place_loader.dart' as loader;

typedef AmaterasuContactsLoader =
    Future<AmaterasuPlaceContacts?> Function(String placeId, String language);
typedef AmaterasuPhotosLoader =
    Future<List<AmaterasuPlacePhoto>> Function(String placeId, String language);

class CachedAmaterasuPlaceInfo implements AmaterasuPlaceInfoService {
  CachedAmaterasuPlaceInfo({
    AmaterasuContactsLoader? loadContacts,
    AmaterasuPhotosLoader? loadPhotos,
  }) : _loadContacts = loadContacts ?? loader.loadPlaceContacts,
       _loadPhotos = loadPhotos ?? loader.loadPlacePhotos;

  final AmaterasuContactsLoader _loadContacts;
  final AmaterasuPhotosLoader _loadPhotos;
  final _contacts = <String, Future<AmaterasuPlaceContacts?>>{};
  final _photos = <String, Future<List<AmaterasuPlacePhoto>>>{};

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
  Future<AmaterasuPlaceContacts?> contacts(
    String placeId, {
    required String languageCode,
  }) => _cached(
    _contacts,
    '$placeId|$languageCode',
    () => _loadContacts(placeId, languageCode),
  );

  @override
  Future<List<AmaterasuPlacePhoto>> photos(
    String placeId, {
    required String languageCode,
  }) => _cached(
    _photos,
    '$placeId|$languageCode',
    () => _loadPhotos(placeId, languageCode),
  );
}

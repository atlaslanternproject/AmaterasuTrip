// Caricatore dei dati Google degli alloggi per il Web, tramite le funzioni
// JavaScript di web/amaterasu_stay_places.js. Accetta solo link https.

import 'dart:convert';
import 'dart:js_interop';

import 'trip_stay_place_info.dart';

@JS('amaterasuStayPlaceContacts')
external JSPromise<JSString> _contacts(JSString placeId, JSString language);

@JS('amaterasuStayPlacePhotos')
external JSPromise<JSString> _photos(
  JSString placeId,
  JSString language,
  JSNumber max,
);

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

Future<TripStayPlaceContacts?> loadTripStayContacts(
  String placeId,
  String languageCode,
) async {
  final result = await _contacts(placeId.toJS, languageCode.toJS).toDart;
  final decoded = jsonDecode(result.toDart);
  if (decoded is! Map) return null;
  final website = _text(decoded['website']);
  return TripStayPlaceContacts(
    phone: _text(decoded['phone']),
    website: website != null && website.startsWith('http') ? website : null,
  );
}

Future<List<TripStayPlacePhoto>> loadTripStayPhotos(
  String placeId,
  String languageCode,
) async {
  final result = await _photos(
    placeId.toJS,
    languageCode.toJS,
    TripStayPlaceInfoService.maxPhotos.toJS,
  ).toDart;
  final decoded = jsonDecode(result.toDart);
  if (decoded is! List) return const [];
  final photos = <TripStayPlacePhoto>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final url = item['url'];
    if (url is! String || !url.startsWith('https://')) continue;
    final authors = <TripStayPhotoAuthor>[];
    for (final author
        in item['authors'] is List ? item['authors'] as List : []) {
      if (author is! Map) continue;
      final name = _text(author['name']);
      final uri = author['uri'];
      if (name == null) continue;
      authors.add(
        TripStayPhotoAuthor(
          name: name,
          uri: uri is String ? Uri.tryParse(uri) : null,
        ),
      );
    }
    photos.add(TripStayPlacePhoto(url: url, authors: authors));
  }
  return photos;
}

// Caricatore dei dati Google dei luoghi per il Web, tramite le funzioni
// JavaScript di web/amaterasu_place_info.js. Accetta solo link https.

import 'dart:convert';
import 'dart:js_interop';

import 'amaterasu_place_info.dart';

@JS('amaterasuPlaceInfoContacts')
external JSPromise<JSString> _contacts(JSString placeId, JSString language);

@JS('amaterasuPlaceInfoPhotos')
external JSPromise<JSString> _photos(
  JSString placeId,
  JSString language,
  JSNumber max,
);

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

Future<AmaterasuPlaceContacts?> loadPlaceContacts(
  String placeId,
  String languageCode,
) async {
  final result = await _contacts(placeId.toJS, languageCode.toJS).toDart;
  final decoded = jsonDecode(result.toDart);
  if (decoded is! Map) return null;
  final website = _text(decoded['website']);
  return AmaterasuPlaceContacts(
    phone: _text(decoded['phone']),
    website: website != null && website.startsWith('http') ? website : null,
  );
}

Future<List<AmaterasuPlacePhoto>> loadPlacePhotos(
  String placeId,
  String languageCode,
) async {
  final result = await _photos(
    placeId.toJS,
    languageCode.toJS,
    AmaterasuPlaceInfoService.maxPhotos.toJS,
  ).toDart;
  final decoded = jsonDecode(result.toDart);
  if (decoded is! List) return const [];
  final photos = <AmaterasuPlacePhoto>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final url = item['url'];
    if (url is! String || !url.startsWith('https://')) continue;
    final authors = <AmaterasuPhotoAuthor>[];
    for (final author
        in item['authors'] is List ? item['authors'] as List : []) {
      if (author is! Map) continue;
      final name = _text(author['name']);
      final uri = author['uri'];
      if (name == null) continue;
      authors.add(
        AmaterasuPhotoAuthor(
          name: name,
          uri: uri is String ? Uri.tryParse(uri) : null,
        ),
      );
    }
    photos.add(AmaterasuPlacePhoto(url: url, authors: authors));
  }
  return photos;
}

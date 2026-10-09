import 'dart:convert';
import 'dart:js_interop';

@JS('amaterasuPlacesSearch')
external JSPromise<JSString> _placesSearch(
  JSString query,
  JSString languageCode,
);

@JS('amaterasuPlaceDetails')
external JSPromise<JSString> _placeDetails(
  JSString placeId,
  JSString languageCode,
);

@JS('amaterasuReverseGeocode')
external JSPromise<JSString> _reverseGeocode(
  JSNumber latitude,
  JSNumber longitude,
  JSString languageCode,
);

@JS('amaterasuGetCurrencies')
external JSPromise<JSString> _getCurrencies(JSString languageCode);

Future<List<Map<Object?, Object?>>> search(
  String query, {
  required String languageCode,
}) async {
  final response = await _placesSearch(query.toJS, languageCode.toJS).toDart;

  return _decodeList(response.toDart);
}

Future<Map<Object?, Object?>> getDetails(
  String placeId, {
  required String languageCode,
}) async {
  final response = await _placeDetails(placeId.toJS, languageCode.toJS).toDart;

  return _decodeMap(response.toDart);
}

Future<Map<Object?, Object?>> reverseGeocode({
  required double latitude,
  required double longitude,
  required String languageCode,
}) async {
  final response = await _reverseGeocode(
    latitude.toJS,
    longitude.toJS,
    languageCode.toJS,
  ).toDart;

  return _decodeMap(response.toDart);
}

Future<List<Map<Object?, Object?>>> getCurrencies({
  required String languageCode,
}) async {
  final response = await _getCurrencies(languageCode.toJS).toDart;

  return _decodeList(response.toDart);
}

List<Map<Object?, Object?>> _decodeList(String source) {
  final decoded = jsonDecode(source);

  if (decoded is! List) {
    throw StateError('Invalid Web Places list response.');
  }

  return decoded
      .whereType<Map>()
      .map((item) => Map<Object?, Object?>.from(item))
      .toList(growable: false);
}

Map<Object?, Object?> _decodeMap(String source) {
  final decoded = jsonDecode(source);

  if (decoded is! Map) {
    throw StateError('Invalid Web Places response.');
  }

  return Map<Object?, Object?>.from(decoded);
}

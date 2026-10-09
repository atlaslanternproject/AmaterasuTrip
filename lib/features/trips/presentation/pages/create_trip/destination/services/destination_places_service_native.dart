import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.amaterasutrip/places');

Future<List<Map<Object?, Object?>>> search(
  String query, {
  required String languageCode,
}) async {
  final result = await _channel.invokeMethod<List<Object?>>(
    'searchDestinations',
    <String, Object?>{'query': query, 'languageCode': languageCode},
  );

  if (result == null) {
    return const [];
  }

  return result.whereType<Map<Object?, Object?>>().toList(growable: false);
}

Future<Map<Object?, Object?>> getDetails(
  String placeId, {
  required String languageCode,
}) async {
  final result = await _channel.invokeMethod<Map<Object?, Object?>>(
    'getDestinationDetails',
    <String, Object?>{'placeId': placeId, 'languageCode': languageCode},
  );

  if (result == null) {
    throw StateError('Destination details unavailable.');
  }

  return result;
}

Future<Map<Object?, Object?>> reverseGeocode({
  required double latitude,
  required double longitude,
  required String languageCode,
}) async {
  final result = await _channel.invokeMethod<Map<Object?, Object?>>(
    'reverseGeocodeDestination',
    <String, Object?>{
      'latitude': latitude,
      'longitude': longitude,
      'languageCode': languageCode,
    },
  );

  if (result == null) {
    throw StateError('Destination unavailable.');
  }

  return result;
}

Future<List<Map<Object?, Object?>>> getCurrencies({
  required String languageCode,
}) async {
  final result = await _channel.invokeMethod<List<Object?>>(
    'getCurrencies',
    <String, Object?>{'languageCode': languageCode},
  );

  if (result == null) {
    return const [];
  }

  return result.whereType<Map<Object?, Object?>>().toList(growable: false);
}

import 'package:flutter/services.dart';

import '../models/trip_destination.dart';

class DestinationPlacesService {
  const DestinationPlacesService();

  static const MethodChannel _channel = MethodChannel(
    'com.amaterasutrip/places',
  );

  Future<List<DestinationPrediction>> search(
    String query, {
    required String languageCode,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < 2) {
      return const [];
    }

    final result = await _channel.invokeMethod<List<Object?>>(
      'searchDestinations',
      <String, Object?>{'query': normalizedQuery, 'languageCode': languageCode},
    );

    if (result == null) {
      return const [];
    }

    return result
        .whereType<Map<Object?, Object?>>()
        .map(DestinationPrediction.fromMap)
        .toList(growable: false);
  }

  Future<TripDestination> getDetails(
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

    return TripDestination.fromMap(result);
  }

  Future<TripDestination> reverseGeocode({
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

    return TripDestination.fromMap(result);
  }

  Future<List<TripCurrency>> getCurrencies({
    required String languageCode,
  }) async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'getCurrencies',
      <String, Object?>{'languageCode': languageCode},
    );

    if (result == null) {
      return const [];
    }

    return result
        .whereType<Map<Object?, Object?>>()
        .map(TripCurrency.fromMap)
        .toList(growable: false);
  }
}

class TripCurrency {
  const TripCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  String get label {
    if (name.trim().isEmpty || name.trim() == code) {
      return code;
    }

    return '$code · $name';
  }

  factory TripCurrency.fromMap(Map<Object?, Object?> map) {
    return TripCurrency(
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      symbol: map['symbol'] as String? ?? '',
    );
  }
}

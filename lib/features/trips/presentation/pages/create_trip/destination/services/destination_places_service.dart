import '../models/trip_destination.dart';
import 'destination_places_service_native.dart'
    if (dart.library.js_interop) 'destination_places_service_web.dart'
    as platform;

class DestinationPlacesService {
  const DestinationPlacesService();

  Future<List<DestinationPrediction>> search(
    String query, {
    required String languageCode,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < 2) {
      return const [];
    }

    final result = await platform.search(
      normalizedQuery,
      languageCode: languageCode,
    );

    return result.map(DestinationPrediction.fromMap).toList(growable: false);
  }

  Future<TripDestination> getDetails(
    String placeId, {
    required String languageCode,
  }) async {
    final result = await platform.getDetails(
      placeId,
      languageCode: languageCode,
    );

    return TripDestination.fromMap(result);
  }

  Future<TripDestination> reverseGeocode({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    final result = await platform.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
      languageCode: languageCode,
    );

    return TripDestination.fromMap(result);
  }

  Future<List<TripCurrency>> getCurrencies({
    required String languageCode,
  }) async {
    final result = await platform.getCurrencies(languageCode: languageCode);

    return result.map(TripCurrency.fromMap).toList(growable: false);
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

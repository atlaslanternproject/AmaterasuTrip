// Ricerca Google finta per i test dell'editor degli alloggi: un solo
// risultato (Hotel Granvia, Kyoto) con i suoi dettagli.

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';

class FakePlaces implements DestinationPlacesService {
  @override
  Future<List<DestinationPrediction>> search(
    String query, {
    required String languageCode,
  }) async => [
    DestinationPrediction.fromMap({
      'placeId': 'ChIJ-kyoto',
      'primaryText': 'Hotel Granvia',
      'secondaryText': 'Kyoto, Giappone',
      'fullText': 'Hotel Granvia, Kyoto',
    }),
  ];

  @override
  Future<TripDestination> getDetails(
    String placeId, {
    required String languageCode,
  }) async => const TripDestination(
    placeId: 'ChIJ-kyoto',
    displayName: 'Hotel Granvia Kyoto',
    formattedAddress: 'Karasuma 901, Kyoto',
    latitude: 34.98,
    longitude: 135.75,
    country: 'Giappone',
    locality: 'Kyoto',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

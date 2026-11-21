// Caricatore dei dati Google degli alloggi per le piattaforme non Web:
// nessun contatto e nessuna foto (la card mostra il segnaposto).

import 'trip_stay_place_info.dart';

Future<TripStayPlaceContacts?> loadTripStayContacts(
  String placeId,
  String languageCode,
) async => null;

Future<List<TripStayPlacePhoto>> loadTripStayPhotos(
  String placeId,
  String languageCode,
) async => const [];

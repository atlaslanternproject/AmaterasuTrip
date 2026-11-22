// Caricatore dei dati Google dei luoghi per le piattaforme non Web:
// nessun contatto e nessuna foto (la card mostra il segnaposto).

import 'amaterasu_place_info.dart';

Future<AmaterasuPlaceContacts?> loadPlaceContacts(
  String placeId,
  String languageCode,
) async => null;

Future<List<AmaterasuPlacePhoto>> loadPlacePhotos(
  String placeId,
  String languageCode,
) async => const [];

// Modulo Luogo condiviso: dati Google di un luogo letti al momento (mai salvati su Firestore):
// contatti (telefono, sito, orari, fascia di prezzo) e foto con i loro
// autori. Il servizio è
// un'interfaccia così i test possono usare una versione finta.

import 'amaterasu_place_hours.dart';

export 'amaterasu_place_hours.dart';

class AmaterasuPlaceContacts {
  const AmaterasuPlaceContacts({
    this.phone,
    this.website,
    this.hours = const AmaterasuPlaceHours(),
    this.priceLevel,
    this.priceRange,
  });

  final String? phone;
  final String? website;

  /// Opening hours and price come with the same Google request.
  final AmaterasuPlaceHours hours;

  /// 1 (cheap) to 4 (very expensive); 0 when free.
  final int? priceLevel;
  final AmaterasuPriceRange? priceRange;
}

class AmaterasuPhotoAuthor {
  const AmaterasuPhotoAuthor({required this.name, this.uri});

  final String name;
  final Uri? uri;
}

class AmaterasuPlacePhoto {
  const AmaterasuPlacePhoto({required this.url, this.authors = const []});

  final String url;
  final List<AmaterasuPhotoAuthor> authors;
}

abstract interface class AmaterasuPlaceInfoService {
  /// Phone and website from Google, or null when unknown.
  Future<AmaterasuPlaceContacts?> contacts(
    String placeId, {
    required String languageCode,
  });

  /// Up to [AmaterasuPlaceInfoService.maxPhotos] photos of the place.
  Future<List<AmaterasuPlacePhoto>> photos(
    String placeId, {
    required String languageCode,
  });

  static const maxPhotos = 5;
}

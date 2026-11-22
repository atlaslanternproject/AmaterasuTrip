// Modulo Luogo condiviso: dati Google di un luogo letti al momento (mai salvati su Firestore):
// contatti (telefono, sito) e foto con i loro autori. Il servizio è
// un'interfaccia così i test possono usare una versione finta.

class AmaterasuPlaceContacts {
  const AmaterasuPlaceContacts({this.phone, this.website});

  final String? phone;
  final String? website;
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

// Dati Google di un alloggio letti al momento (mai salvati su Firestore):
// contatti (telefono, sito) e foto con i loro autori. Il servizio è
// un'interfaccia così i test possono usare una versione finta.

class TripStayPlaceContacts {
  const TripStayPlaceContacts({this.phone, this.website});

  final String? phone;
  final String? website;
}

class TripStayPhotoAuthor {
  const TripStayPhotoAuthor({required this.name, this.uri});

  final String name;
  final Uri? uri;
}

class TripStayPlacePhoto {
  const TripStayPlacePhoto({required this.url, this.authors = const []});

  final String url;
  final List<TripStayPhotoAuthor> authors;
}

abstract interface class TripStayPlaceInfoService {
  /// Phone and website from Google, or null when unknown.
  Future<TripStayPlaceContacts?> contacts(
    String placeId, {
    required String languageCode,
  });

  /// Up to [TripStayPlaceInfoService.maxPhotos] photos of the place.
  Future<List<TripStayPlacePhoto>> photos(
    String placeId, {
    required String languageCode,
  });

  static const maxPhotos = 5;
}

// Luogo di un elemento di una sezione (partenza/arrivo di un trasporto,
// ristorante, prenotazione…): nome, indirizzo, luogo Google e coordinate.
// Si salva con un prefisso, es. fromName, fromPlaceId (vedi firestore.rules).

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'trip_section_fields.dart';

class TripSectionPlace {
  const TripSectionPlace({
    this.name,
    this.address,
    this.placeId,
    this.latitude,
    this.longitude,
  });

  static const nameMax = 200;
  static const addressMax = 300;

  final String? name;
  final String? address;
  final String? placeId;
  final double? latitude;
  final double? longitude;

  /// Same place with [newName] when given (e.g. the restaurant name).
  TripSectionPlace withName(String? newName) => TripSectionPlace(
    name: newName ?? name,
    address: address,
    placeId: placeId,
    latitude: latitude,
    longitude: longitude,
  );

  bool get isEmpty => name == null && address == null && placeId == null;

  /// Google Maps link, when there is a Google place or coordinates.
  Uri? get maps => AmaterasuWebLink.googleMaps(
    name: name ?? address ?? '',
    placeId: placeId,
    latitude: latitude,
    longitude: longitude,
  );

  Map<String, dynamic> toMap(String prefix) => {
    '${prefix}Name': ?TripSectionFields.clean(name),
    '${prefix}Address': ?TripSectionFields.clean(address),
    '${prefix}PlaceId': ?TripSectionFields.clean(placeId),
    '${prefix}Latitude': ?latitude,
    '${prefix}Longitude': ?longitude,
  };

  static List<String> keys(String prefix) => [
    '${prefix}Name',
    '${prefix}Address',
    '${prefix}PlaceId',
    '${prefix}Latitude',
    '${prefix}Longitude',
  ];

  static TripSectionPlace fromMap(Map<String, dynamic> data, String prefix) =>
      TripSectionPlace(
        name: TripSectionFields.readText(data, '${prefix}Name'),
        address: TripSectionFields.readText(data, '${prefix}Address'),
        placeId: TripSectionFields.readText(data, '${prefix}PlaceId'),
        latitude: TripSectionFields.readNumber(data, '${prefix}Latitude'),
        longitude: TripSectionFields.readNumber(data, '${prefix}Longitude'),
      );

  /// True when a field is beyond the firestore.rules limits.
  bool get invalid =>
      TripSectionFields.longer(name, nameMax) ||
      TripSectionFields.longer(address, addressMax) ||
      TripSectionFields.longer(placeId, addressMax) ||
      (latitude != null && (latitude! < -90 || latitude! > 90)) ||
      (longitude != null && (longitude! < -180 || longitude! > 180));
}

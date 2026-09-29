import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';

enum TripStatus { active, closed }

class TripDestinationData {
  const TripDestinationData({
    required this.placeId,
    required this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.country,
    this.countryCode,
    this.administrativeArea,
    this.locality,
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? country;
  final String? countryCode;
  final String? administrativeArea;
  final String? locality;

  factory TripDestinationData.fromMap(Map<String, dynamic> data) {
    return TripDestinationData(
      placeId: data['placeId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      formattedAddress: data['formattedAddress'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      country: data['country'] as String?,
      countryCode: data['countryCode'] as String?,
      administrativeArea: data['administrativeArea'] as String?,
      locality: data['locality'] as String?,
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.ownerUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.destinationData,
    this.coverUrl,
    this.coverPath,
    this.cloudArchive,
  });

  final String id;
  final String name;

  /// Etichetta leggibile della destinazione.
  ///
  /// Rimane separata dai dati strutturati per compatibilità con i viaggi
  /// creati prima dell'introduzione di destinationData.
  final String destination;

  /// Informazioni geografiche strutturate della destinazione.
  ///
  /// È nullable per mantenere compatibilità con i viaggi esistenti che
  /// possiedono soltanto il campo destination.
  final TripDestinationData? destinationData;

  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final String ownerUid;
  final TripStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// URL pubblico della copertina scelta dall'utente.
  ///
  /// È nullable perché un viaggio può esistere senza una copertina
  /// personalizzata. In quel caso la UI utilizzerà il fallback Amaterasu.
  final String? coverUrl;

  /// Percorso del file in Firebase Storage.
  ///
  /// Viene conservato separatamente dall'URL per permettere la sostituzione
  /// o la rimozione sicura della vecchia copertina.
  final String? coverPath;

  /// Archivio cloud definitivo associato al viaggio.
  ///
  /// È nullable perché la configurazione dell'archivio non è obbligatoria
  /// e per mantenere compatibilità con i viaggi già esistenti.
  final TripCloudArchive? cloudArchive;

  factory Trip.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final startDate = data['startDate'] as Timestamp?;
    final endDate = data['endDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final updatedAt = data['updatedAt'] as Timestamp?;

    final rawDestinationData = data['destinationData'];
    final rawCloudArchive = data['cloudArchive'];

    TripDestinationData? destinationData;
    TripCloudArchive? cloudArchive;

    if (rawDestinationData is Map) {
      destinationData = TripDestinationData.fromMap(
        Map<String, dynamic>.from(rawDestinationData),
      );
    }

    if (rawCloudArchive is Map) {
      cloudArchive = TripCloudArchive.fromMap(
        Map<String, dynamic>.from(rawCloudArchive),
      );
    }

    return Trip(
      id: id,
      name: data['name'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      destinationData: destinationData,
      startDate: startDate?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      endDate: endDate?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      currency: data['currency'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      status: _tripStatusFromString(data['status'] as String?),
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
      coverUrl: data['coverUrl'] as String?,
      coverPath: data['coverPath'] as String?,
      cloudArchive: cloudArchive,
    );
  }
}

TripStatus _tripStatusFromString(String? value) {
  switch (value) {
    case 'closed':
      return TripStatus.closed;
    case 'active':
    default:
      return TripStatus.active;
  }
}

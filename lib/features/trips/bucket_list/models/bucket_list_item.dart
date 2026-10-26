import 'bucket_item_type.dart';

class BucketListItem {
  const BucketListItem({
    required this.id,
    required this.tripId,
    required this.name,
    required this.city,
    required this.country,
    required this.type,
    required this.createdByUid,
    required this.createdAt,
    required this.updatedAt,
    this.durationMinutes,
    this.notes = '',
    this.usefulLinks = const [],
    this.googlePlaceId,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String tripId;
  final String name;
  final String city;
  final String country;
  final BucketItemType type;
  final String createdByUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Null means unspecified. Travel time is not included.
  final int? durationMinutes;

  final String notes;
  final List<String> usefulLinks;

  // Stable Places identifier, not a temporary photo URL.
  final String? googlePlaceId;

  // Photo resource reference. Retrieval is handled by a separate service.

  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasDuration => durationMinutes != null;
  bool get hasGooglePlace => googlePlaceId?.isNotEmpty ?? false;
  bool get hasCoordinates => latitude != null && longitude != null;

  void validate() {
    if (id.trim().isEmpty ||
        tripId.trim().isEmpty ||
        name.trim().isEmpty ||
        city.trim().isEmpty ||
        country.trim().isEmpty ||
        createdByUid.trim().isEmpty) {
      throw ArgumentError('Required Bucket List field is empty.');
    }

    if (name.length > 200) {
      throw ArgumentError.value(name, 'name', 'Maximum 200 characters.');
    }

    if (city.length > 150 || country.length > 150) {
      throw ArgumentError('City and country must not exceed 150 characters.');
    }

    if (notes.length > 10000) {
      throw ArgumentError.value(
        notes.length,
        'notes',
        'Maximum 10000 characters.',
      );
    }

    if (usefulLinks.length > 20) {
      throw ArgumentError.value(
        usefulLinks.length,
        'usefulLinks',
        'Maximum 20 links.',
      );
    }

    if (durationMinutes != null && durationMinutes! > 10080) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'Maximum 10080 minutes.',
      );
    }
    if (durationMinutes != null && durationMinutes! <= 0) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'Must be positive.',
      );
    }

    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Coordinates must be supplied together.');
    }

    if (latitude != null &&
        (latitude! < -90 ||
            latitude! > 90 ||
            longitude! < -180 ||
            longitude! > 180)) {
      throw ArgumentError('Coordinates are outside valid bounds.');
    }

    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('Updated date precedes creation date.');
    }

    for (final link in usefulLinks) {
      if (link.length > 2048) {
        throw ArgumentError.value(
          link.length,
          'usefulLinks',
          'Maximum 2048 characters per link.',
        );
      }
      final uri = Uri.tryParse(link);
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        throw ArgumentError.value(link, 'usefulLinks', 'Invalid URL.');
      }
    }
  }

  BucketListItem copyWith({
    String? name,
    String? city,
    String? country,
    BucketItemType? type,
    int? durationMinutes,
    bool clearDurationMinutes = false,
    String? notes,
    List<String>? usefulLinks,
    DateTime? updatedAt,
    String? googlePlaceId,
    bool clearGooglePlaceId = false,
    String? address,
    bool clearAddress = false,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
  }) {
    if (clearCoordinates && (latitude != null || longitude != null)) {
      throw ArgumentError('Cannot set and clear coordinates together.');
    }

    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Coordinates must be supplied together.');
    }

    return BucketListItem(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      type: type ?? this.type,
      createdByUid: createdByUid,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      durationMinutes: clearDurationMinutes
          ? null
          : durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      usefulLinks: usefulLinks ?? this.usefulLinks,
      googlePlaceId: clearGooglePlaceId
          ? null
          : googlePlaceId ?? this.googlePlaceId,
      address: clearAddress ? null : address ?? this.address,
      latitude: clearCoordinates ? null : latitude ?? this.latitude,
      longitude: clearCoordinates ? null : longitude ?? this.longitude,
    );
  }
}

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
    this.googlePhotoName,
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
  final String? googlePhotoName;

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
    String? notes,
    List<String>? usefulLinks,
    DateTime? updatedAt,
  }) {
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
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      usefulLinks: usefulLinks ?? this.usefulLinks,
      googlePlaceId: googlePlaceId,
      googlePhotoName: googlePhotoName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

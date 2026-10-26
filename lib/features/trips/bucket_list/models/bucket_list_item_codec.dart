import 'bucket_item_type.dart';
import 'bucket_list_item.dart';

/// Converts Bucket List activities to and from Firestore-compatible maps.
///
/// Document IDs are supplied separately and are not duplicated in the map.
/// Dates are stored as Firestore timestamps.
abstract final class BucketListItemCodec {
  static Map<String, Object?> toMap(BucketListItem item) {
    item.validate();

    return {
      'tripId': item.tripId,
      'name': item.name,
      'city': item.city,
      'country': item.country,
      'type': item.type.name,
      'createdByUid': item.createdByUid,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      'durationMinutes': item.durationMinutes,
      'notes': item.notes,
      'usefulLinks': List<String>.from(item.usefulLinks),
      'googlePlaceId': item.googlePlaceId,
      'address': item.address,
      'latitude': item.latitude,
      'longitude': item.longitude,
    };
  }

  static BucketListItem fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final typeName = _requiredString(data, 'type');

    final type = BucketItemType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () =>
          throw FormatException('Unknown Bucket List item type: $typeName'),
    );

    final rawLinks = data['usefulLinks'];

    if (rawLinks != null && rawLinks is! List) {
      throw const FormatException('Invalid usefulLinks type.');
    }

    final links = <String>[];

    if (rawLinks is List) {
      for (final link in rawLinks) {
        if (link is! String) {
          throw const FormatException('Invalid useful link.');
        }

        links.add(link);
      }
    }

    final item = BucketListItem(
      id: id,
      tripId: _requiredString(data, 'tripId'),
      name: _requiredString(data, 'name'),
      city: _requiredString(data, 'city'),
      country: _requiredString(data, 'country'),
      type: type,
      createdByUid: _requiredString(data, 'createdByUid'),
      createdAt: _date(data, 'createdAt'),
      updatedAt: _date(data, 'updatedAt'),
      durationMinutes: _optionalInt(data, 'durationMinutes'),
      notes: _optionalString(data, 'notes') ?? '',
      usefulLinks: links,
      googlePlaceId: _optionalString(data, 'googlePlaceId'),
      address: _optionalString(data, 'address'),
      latitude: _optionalDouble(data, 'latitude'),
      longitude: _optionalDouble(data, 'longitude'),
    );

    item.validate();
    return item;
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid field: $key');
    }

    return value;
  }

  static String? _optionalString(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) return null;

    if (value is! String) {
      throw FormatException('Invalid string field: $key');
    }

    return value;
  }

  static int? _optionalInt(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) return null;

    if (value is! int) {
      throw FormatException('Invalid integer field: $key');
    }

    return value;
  }

  static double? _optionalDouble(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) return null;

    if (value is! num || !value.isFinite) {
      throw FormatException('Invalid numeric field: $key');
    }

    return value.toDouble();
  }

  static DateTime _date(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value is! String) {
      throw FormatException('Invalid date field: $key');
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      throw FormatException('Invalid date value: $key');
    }

    return date.toUtc();
  }
}

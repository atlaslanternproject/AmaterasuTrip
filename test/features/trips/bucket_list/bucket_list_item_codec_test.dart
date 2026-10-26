import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item_codec.dart';

void main() {
  final date = DateTime.utc(2026, 10, 26, 12, 30);

  BucketListItem makeItem() {
    return BucketListItem(
      id: 'kodokan',
      tripId: 'japan-2027',
      name: 'Kodokan',
      city: 'Tokyo',
      country: 'Japan',
      type: BucketItemType.attraction,
      createdByUid: 'uid-tommaso',
      createdAt: date,
      updatedAt: date,
      durationMinutes: 120,
      notes: 'Visitare il Kodokan',
      usefulLinks: const ['https://example.com/kodokan'],
      googlePlaceId: 'google-place-kodokan',
      address: 'Tokyo, Japan',
      latitude: 35.70,
      longitude: 139.75,
    );
  }

  test('Round trip preserves activity data', () {
    final original = makeItem();

    final encoded = BucketListItemCodec.toMap(original);

    final decoded = BucketListItemCodec.fromMap(id: original.id, data: encoded);

    expect(decoded.id, original.id);
    expect(decoded.tripId, original.tripId);
    expect(decoded.name, original.name);
    expect(decoded.city, original.city);
    expect(decoded.country, original.country);
    expect(decoded.type, original.type);
    expect(decoded.durationMinutes, 120);
    expect(decoded.notes, original.notes);
    expect(decoded.googlePlaceId, original.googlePlaceId);
    expect(decoded.latitude, original.latitude);
    expect(decoded.longitude, original.longitude);
    expect(decoded.createdAt, date);
    expect(decoded.updatedAt, date);
  });

  test('No photo URL or photo resource is persisted', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    expect(encoded.containsKey('googlePhotoName'), isFalse);
    expect(encoded.containsKey('photoUrl'), isFalse);
    expect(encoded.containsKey('photoReference'), isFalse);
    expect(encoded['googlePlaceId'], 'google-place-kodokan');
  });

  test('Document identity is not duplicated', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    expect(encoded.containsKey('id'), isFalse);
  });

  test('Type and duration survive serialization', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    expect(encoded['type'], 'attraction');
    expect(encoded['durationMinutes'], 120);
  });

  test('Missing optional data is supported', () {
    final original = makeItem();

    final encoded = BucketListItemCodec.toMap(original);

    encoded['durationMinutes'] = null;
    encoded['googlePlaceId'] = null;
    encoded['latitude'] = null;
    encoded['longitude'] = null;
    encoded['usefulLinks'] = <String>[];

    final decoded = BucketListItemCodec.fromMap(id: original.id, data: encoded);

    expect(decoded.durationMinutes, isNull);
    expect(decoded.googlePlaceId, isNull);
    expect(decoded.hasCoordinates, isFalse);
    expect(decoded.usefulLinks, isEmpty);
  });

  test('Unknown type is rejected', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    encoded['type'] = 'unknown';

    expect(
      () => BucketListItemCodec.fromMap(id: 'kodokan', data: encoded),
      throwsFormatException,
    );
  });

  test('Invalid stored links are rejected', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    encoded['usefulLinks'] = <Object>['https://example.com', 123];

    expect(
      () => BucketListItemCodec.fromMap(id: 'kodokan', data: encoded),
      throwsFormatException,
    );
  });

  test('Invalid stored dates are rejected', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    encoded['createdAt'] = 'not-a-date';

    expect(
      () => BucketListItemCodec.fromMap(id: 'kodokan', data: encoded),
      throwsFormatException,
    );
  });

  test('Invalid coordinates are rejected', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    encoded['latitude'] = 200.0;

    expect(
      () => BucketListItemCodec.fromMap(id: 'kodokan', data: encoded),
      throwsArgumentError,
    );
  });

  test('Votes are not embedded in activity documents', () {
    final encoded = BucketListItemCodec.toMap(makeItem());

    expect(encoded.containsKey('votes'), isFalse);
    expect(encoded.containsKey('votesByUid'), isFalse);
    expect(encoded.containsKey('groupPriority'), isFalse);
  });
}

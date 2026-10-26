import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';

void main() {
  final created = DateTime.utc(2026, 10, 26);

  BucketListItem sample() => BucketListItem(
    id: 'kodokan',
    tripId: 'japan',
    name: 'Kodokan',
    city: 'Tokyo',
    country: 'Japan',
    type: BucketItemType.attraction,
    createdByUid: 'owner',
    createdAt: created,
    updatedAt: created,
    durationMinutes: 120,
    googlePlaceId: 'place-id',
    address: 'Tokyo, Japan',
    latitude: 35.7,
    longitude: 139.7,
  );

  test('Can clear a previously entered duration', () {
    final updated = sample().copyWith(clearDurationMinutes: true);
    expect(updated.durationMinutes, isNull);
    expect(updated.id, 'kodokan');
    expect(updated.createdByUid, 'owner');
  });

  test('Can replace a duration', () {
    final updated = sample().copyWith(durationMinutes: 90);
    expect(updated.durationMinutes, 90);
  });

  test('Can clear Google Place ID and address', () {
    final updated = sample().copyWith(
      clearGooglePlaceId: true,
      clearAddress: true,
    );
    expect(updated.googlePlaceId, isNull);
    expect(updated.address, isNull);
  });

  test('Can change a Google Place ID and address', () {
    final updated = sample().copyWith(
      googlePlaceId: 'new-place',
      address: 'New address',
    );
    expect(updated.googlePlaceId, 'new-place');
    expect(updated.address, 'New address');
  });

  test('Can clear coordinates', () {
    final updated = sample().copyWith(clearCoordinates: true);
    expect(updated.latitude, isNull);
    expect(updated.longitude, isNull);
    expect(updated.hasCoordinates, isFalse);
  });

  test('Can replace coordinates together', () {
    final updated = sample().copyWith(latitude: 34.7, longitude: 135.5);
    expect(updated.latitude, 34.7);
    expect(updated.longitude, 135.5);
  });

  test('Rejects setting only one coordinate', () {
    expect(() => sample().copyWith(latitude: 34.7), throwsArgumentError);
  });

  test('Rejects simultaneously clearing and setting coordinates', () {
    expect(
      () => sample().copyWith(
        clearCoordinates: true,
        latitude: 34.7,
        longitude: 135.5,
      ),
      throwsArgumentError,
    );
  });

  test('Identity survives a complete edit', () {
    final updated = sample().copyWith(
      name: 'Kodokan Institute',
      city: 'Tokyo',
      durationMinutes: 180,
      googlePlaceId: 'replacement',
      latitude: 35.6,
      longitude: 139.6,
    );
    updated.validate();
    expect(updated.id, 'kodokan');
    expect(updated.tripId, 'japan');
    expect(updated.createdAt, created);
    expect(updated.createdByUid, 'owner');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';

void main() {
  final created = DateTime.utc(2026, 10, 26);

  BucketListItem makeItem({
    String name = 'Kodokan',
    int? durationMinutes = 120,
    List<String> links = const [],
    double? latitude,
    double? longitude,
  }) {
    return BucketListItem(
      id: 'place-1',
      tripId: 'trip-1',
      name: name,
      city: 'Tokyo',
      country: 'Japan',
      type: BucketItemType.attraction,
      createdByUid: 'traveller-1',
      createdAt: created,
      updatedAt: created,
      durationMinutes: durationMinutes,
      usefulLinks: links,
      latitude: latitude,
      longitude: longitude,
    );
  }

  test('Valid attraction can be created', () {
    final item = makeItem();
    expect(() => item.validate(), returnsNormally);
    expect(item.durationMinutes, 120);
    expect(item.tripId, 'trip-1');
  });

  test('Duration can be unspecified', () {
    final item = makeItem(durationMinutes: null);
    expect(() => item.validate(), returnsNormally);
    expect(item.hasDuration, isFalse);
  });

  test('Empty attraction name is rejected', () {
    expect(() => makeItem(name: ' ').validate(), throwsArgumentError);
  });

  test('Non-positive duration is rejected', () {
    expect(() => makeItem(durationMinutes: 0).validate(), throwsArgumentError);
  });

  test('HTTP and HTTPS links are accepted', () {
    final item = makeItem(
      links: ['https://example.com/place', 'http://example.org'],
    );
    expect(() => item.validate(), returnsNormally);
  });

  test('Invalid links are rejected', () {
    final item = makeItem(links: ['javascript:alert(1)']);
    expect(() => item.validate(), throwsArgumentError);
  });

  test('Coordinates must be supplied together', () {
    final item = makeItem(latitude: 35.7);
    expect(() => item.validate(), throwsArgumentError);
  });

  test('Valid coordinates are accepted', () {
    final item = makeItem(latitude: 35.7, longitude: 139.7);
    expect(() => item.validate(), returnsNormally);
    expect(item.hasCoordinates, isTrue);
  });

  test('Copy preserves the immutable item identity', () {
    final original = makeItem();
    final changed = original.copyWith(
      name: 'Kodokan Judo Institute',
      notes: 'Visit with the group',
    );
    expect(changed.id, original.id);
    expect(changed.tripId, original.tripId);
    expect(changed.createdByUid, original.createdByUid);
    expect(changed.name, 'Kodokan Judo Institute');
  });
}

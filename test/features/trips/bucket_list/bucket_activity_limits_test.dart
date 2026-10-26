import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item_codec.dart';

void main() {
  final created = DateTime.utc(2026, 10, 26, 18);

  BucketListItem item({
    String name = 'Kodokan',
    String city = 'Tokyo',
    String country = 'Japan',
    int? durationMinutes = 120,
    String notes = '',
    List<String> usefulLinks = const [],
  }) {
    return BucketListItem(
      id: 'kodokan',
      tripId: 'japan',
      name: name,
      city: city,
      country: country,
      type: BucketItemType.attraction,
      createdByUid: 'owner',
      createdAt: created,
      updatedAt: created,
      durationMinutes: durationMinutes,
      notes: notes,
      usefulLinks: usefulLinks,
    );
  }

  test('Valid activity passes all limits', () {
    item().validate();
  });

  test('Name accepts exactly 200 characters', () {
    item(name: 'A' * 200).validate();
  });

  test('Name rejects 201 characters', () {
    expect(() => item(name: 'A' * 201).validate(), throwsArgumentError);
  });

  test('City accepts exactly 150 characters', () {
    item(city: 'T' * 150).validate();
  });

  test('City rejects 151 characters', () {
    expect(() => item(city: 'T' * 151).validate(), throwsArgumentError);
  });

  test('Country rejects 151 characters', () {
    expect(() => item(country: 'J' * 151).validate(), throwsArgumentError);
  });

  test('Duration accepts 10080 minutes', () {
    item(durationMinutes: 10080).validate();
  });

  test('Duration rejects 10081 minutes', () {
    expect(() => item(durationMinutes: 10081).validate(), throwsArgumentError);
  });

  test('Duration rejects zero', () {
    expect(() => item(durationMinutes: 0).validate(), throwsArgumentError);
  });

  test('Notes accept exactly 10000 characters', () {
    item(notes: 'N' * 10000).validate();
  });

  test('Notes reject 10001 characters', () {
    expect(() => item(notes: 'N' * 10001).validate(), throwsArgumentError);
  });

  test('Twenty valid links are accepted', () {
    item(
      usefulLinks: List.generate(20, (index) => 'https://example.com/$index'),
    ).validate();
  });

  test('Twenty-one links are rejected', () {
    expect(
      () => item(
        usefulLinks: List.generate(21, (index) => 'https://example.com/$index'),
      ).validate(),
      throwsArgumentError,
    );
  });

  test('Link of exactly 2048 characters is accepted', () {
    final url = Uri.https(
      'example.com',
      '/${'a' * (2048 - 'https://example.com/'.length)}',
    ).toString();

    item(usefulLinks: [url]).validate();
  });

  test('Link longer than 2048 characters is rejected', () {
    final url = Uri.https(
      'example.com',
      '/${'a' * (2049 - 'https://example.com/'.length)}',
    ).toString();

    expect(() => item(usefulLinks: [url]).validate(), throwsArgumentError);
  });

  test('Codec serializes dates as UTC strings', () {
    final data = BucketListItemCodec.toMap(item());

    expect(data['createdAt'], isA<String>());
    expect(data['updatedAt'], isA<String>());
    expect((data['createdAt'] as String).endsWith('Z'), isTrue);
  });

  test('Codec rejects an over-limit name', () {
    expect(
      () => BucketListItemCodec.toMap(item(name: 'A' * 201)),
      throwsArgumentError,
    );
  });

  test('Optional duration remains nullable', () {
    final data = BucketListItemCodec.toMap(item(durationMinutes: null));

    expect(data['durationMinutes'], isNull);
  });
}

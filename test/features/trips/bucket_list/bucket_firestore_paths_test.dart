import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_firestore_paths.dart';

void main() {
  test('Activity path is scoped to its trip', () {
    expect(
      BucketFirestorePaths.activity('trip-a', 'kodokan'),
      'trips/trip-a/bucketList/kodokan',
    );
  });

  test('Votes are stored under their activity', () {
    expect(
      BucketFirestorePaths.votes('trip-a', 'kodokan'),
      'trips/trip-a/bucketList/kodokan/votes',
    );
  });

  test('Each vote document is keyed by user UID', () {
    expect(
      BucketFirestorePaths.vote('trip-a', 'kodokan', 'user-a'),
      'trips/trip-a/bucketList/kodokan/votes/user-a',
    );
  });

  test('Other trips have independent activity paths', () {
    expect(
      BucketFirestorePaths.activity('trip-a', 'kodokan'),
      isNot(BucketFirestorePaths.activity('trip-b', 'kodokan')),
    );
  });

  test('Empty IDs are rejected', () {
    expect(() => BucketFirestorePaths.activities(''), throwsArgumentError);
  });

  test('IDs cannot inject extra path segments', () {
    expect(
      () => BucketFirestorePaths.vote('trip', 'place', '../other'),
      throwsArgumentError,
    );
  });
}

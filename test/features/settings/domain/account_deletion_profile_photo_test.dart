// Test automatici di account_deletion_profile_photo (settings/domain).
// Casi, ad esempio: "own profile photo is deleted", "path of another user is ignored".

import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/settings/domain/account_deletion_profile_photo.dart';

String? pathFor(String uid, Object? photoPath) =>
    AccountDeletionProfilePhoto.pathToDelete(
      uid: uid,
      profileData: {'photoPath': photoPath},
    );

void main() {
  test('own profile photo is deleted', () {
    expect(
      pathFor('anna', 'users/anna/profile/profile_1.jpg'),
      'users/anna/profile/profile_1.jpg',
    );
  });

  test('surrounding spaces are ignored', () {
    expect(
      pathFor('anna', '  users/anna/profile/profile_1.jpg '),
      'users/anna/profile/profile_1.jpg',
    );
  });

  test('missing, empty or non-text photoPath means nothing to delete', () {
    expect(
      AccountDeletionProfilePhoto.pathToDelete(uid: 'anna', profileData: null),
      isNull,
    );
    expect(
      AccountDeletionProfilePhoto.pathToDelete(uid: 'anna', profileData: {}),
      isNull,
    );
    expect(pathFor('anna', ''), isNull);
    expect(pathFor('anna', 42), isNull);
  });

  test('path of another user is ignored', () {
    expect(pathFor('anna', 'users/bruno/profile/profile_1.jpg'), isNull);
  });

  test('paths outside the profile folder are ignored', () {
    expect(pathFor('anna', 'users/anna/trips/t1/cover/cover_1.jpg'), isNull);
    expect(pathFor('anna', 'users/anna/profile/'), isNull);
    expect(pathFor('anna', 'users/anna/profile/a/b.jpg'), isNull);
    expect(pathFor('anna', 'users/anna/profile'), isNull);
  });

  test('an invalid uid never produces a path', () {
    expect(pathFor('', 'users//profile/p.jpg'), isNull);
    expect(pathFor('an/na', 'users/an/na/profile/p.jpg'), isNull);
  });
}

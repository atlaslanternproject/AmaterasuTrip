import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/domain/access/trip_access.dart';

void main() {
  test('OWNER can delete a trip', () {
    expect(
      TripAccessPolicy.can(
        role: TripRole.owner,
        permission: TripPermission.deleteTrip,
      ),
      isTrue,
    );
  });

  test('TRAVELER cannot delete a trip', () {
    expect(
      TripAccessPolicy.can(
        role: TripRole.traveler,
        permission: TripPermission.deleteTrip,
      ),
      isFalse,
    );
  });

  test('all other TRAVELER permissions remain unchanged', () {
    for (final permission in TripPermission.values) {
      if (permission == TripPermission.deleteTrip) {
        continue;
      }

      expect(
        TripAccessPolicy.can(role: TripRole.traveler, permission: permission),
        isTrue,
        reason: 'Unexpected restriction: $permission',
      );
    }
  });
}

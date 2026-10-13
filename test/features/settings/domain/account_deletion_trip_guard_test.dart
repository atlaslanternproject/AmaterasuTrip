import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/settings/domain/account_deletion_trip_guard.dart';

void main() {
  test('account without trips can continue', () {
    expect(
      () => AccountDeletionTripGuard.requireNoTripReferences(
        ownsTrip: false,
        participatesInTrip: false,
      ),
      returnsNormally,
    );
  });

  test('participant with a trip is blocked', () {
    expect(
      () => AccountDeletionTripGuard.requireNoTripReferences(
        ownsTrip: false,
        participatesInTrip: true,
      ),
      throwsStateError,
    );
  });

  test('trip owner is blocked', () {
    expect(
      () => AccountDeletionTripGuard.requireNoTripReferences(
        ownsTrip: true,
        participatesInTrip: false,
      ),
      throwsStateError,
    );
  });

  test('owner and participant is blocked', () {
    expect(
      () => AccountDeletionTripGuard.requireNoTripReferences(
        ownsTrip: true,
        participatesInTrip: true,
      ),
      throwsStateError,
    );
  });
}

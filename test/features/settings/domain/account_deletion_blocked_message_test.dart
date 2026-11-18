// Test automatici del blocco della cancellazione account con viaggi attivi.
// Casi, ad esempio: "blocked deletion has its own error type", "blocked message in Italian and English".

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/settings/domain/account_deletion_trip_guard.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

void main() {
  test('blocked deletion has its own error type, still a StateError', () {
    Object? thrown;
    try {
      AccountDeletionTripGuard.requireNoTripReferences(
        ownsTrip: true,
        participatesInTrip: false,
      );
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<AccountDeletionBlockedByTripsError>());
    expect(thrown, isA<StateError>());
  });

  test('blocked message in Italian and English', () {
    expect(
      lookupAppLocalizations(const Locale('it')).accountDeleteBlockedByTrips,
      "Prima di eliminare l'account esci dai viaggi o eliminali.",
    );
    expect(
      lookupAppLocalizations(const Locale('en')).accountDeleteBlockedByTrips,
      'Before deleting your account, leave your trips or delete them.',
    );
  });

  test('the generic error stays different from the blocked message', () {
    final it = lookupAppLocalizations(const Locale('it'));
    expect(it.accountDeleteError, isNot(it.accountDeleteBlockedByTrips));
  });
}

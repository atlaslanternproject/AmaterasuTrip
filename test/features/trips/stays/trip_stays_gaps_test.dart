// Test automatici dell'avviso "notti senza alloggio" (solo informativo):
// calcolo delle notti scoperte nell'intervallo del viaggio e avviso nella pagina.
// Casi, ad esempio: "cancelled stays do not cover nights", "banner lists the periods".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_trip_stays.dart';

DateTime d(int day) => DateTime(2027, 4, day);

Future<void> open(WidgetTester tester, DateTime start, DateTime end) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      // Nights 12, 13, 14 and 20, 21.
      stays: [testStay('s1'), testStay('s2', day: 20, nights: 2)],
      repository: FakeTripStaysRepository(),
      tripInfo: (currency: 'EUR', start: start, end: end),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nights from the first day to the day before the end', () {
    final stays = [testStay('s1')]; // 12 -> 15
    expect(TripStaysGaps.uncoveredNights(stays, d(12), d(15)), isEmpty);
    expect(TripStaysGaps.uncoveredNights(stays, d(10), d(17)), [
      d(10),
      d(11),
      d(15),
      d(16),
    ]);
    expect(TripStaysGaps.uncoveredNights(stays, d(12), d(12)), isEmpty);
  });

  test('cancelled stays do not cover nights; odd dates are skipped', () {
    final cancelled = [testStay('s1', status: TripStayStatus.cancelled)];
    expect(TripStaysGaps.uncoveredNights(cancelled, d(12), d(14)), [
      d(12),
      d(13),
    ]);
    expect(
      TripStaysGaps.uncoveredNights(const [], DateTime(1970), d(1)),
      isEmpty,
    );
    expect(TripStaysGaps.uncoveredNights(const [], d(14), d(12)), isEmpty);
  });

  test('consecutive nights become one period', () {
    expect(TripStaysGaps.ranges([d(10), d(11), d(15), d(17), d(18)]), [
      (d(10), d(11)),
      (d(15), d(15)),
      (d(17), d(18)),
    ]);
  });

  testWidgets('banner lists the uncovered periods', (tester) async {
    await open(tester, d(11), d(23));
    expect(find.byKey(const Key('stays-gaps')), findsOneWidget);
    expect(
      find.text(
        '7 notti del viaggio senza alloggio: 11 apr, 15 apr – 19 apr, 22 apr.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no banner when every night has a stay', (tester) async {
    await open(tester, d(12), d(15));
    expect(find.byKey(const Key('stays-gaps')), findsNothing);
  });
}

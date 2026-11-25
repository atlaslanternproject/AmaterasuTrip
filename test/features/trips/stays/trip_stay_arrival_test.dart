// Test automatici delle aggiunte facoltative v2 degli alloggi: accesso
// (codice porta, Wi-Fi), arrivo tardivo con la reception e tassa di
// soggiorno (salvate insieme in "extras"), righe della card ed editor.
// Casi, ad esempio: "city tax total from nights and guests", "editor saves arrival and tax".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_codec.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_extras.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

TripStay ryokan({TripStayExtras extras = const TripStayExtras()}) => TripStay(
  id: 's1',
  tripId: 't1',
  name: 'Ryokan',
  checkInDate: DateTime(2027, 4, 12),
  checkOutDate: DateTime(2027, 4, 15),
  createdByUid: 'anna',
  guestUids: const ['anna', 'bruno'],
  extras: extras,
);

Future<void> open(
  WidgetTester tester,
  FakeTripStaysRepository repo, {
  List<TripStay> stays = const [],
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: stays,
      repository: repo,
      tripInfo: (
        currency: 'JPY',
        start: DateTime(2027, 4, 10),
        end: DateTime(2027, 4, 20),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  test('extras are saved together, checked and give the tax total', () {
    const extras = TripStayExtras(
      doorCode: '1234',
      wifiName: 'Guest',
      lateArrivalTime: '23:30',
      taxMinorUnits: 200,
      taxCurrency: 'JPY',
    );
    final map = TripStayCodec.toMap(ryokan(extras: extras));
    expect(map['extras'], {
      'doorCode': '1234',
      'wifiName': 'Guest',
      'lateArrivalTime': '23:30',
      'taxMinorUnits': 200,
      'taxCurrency': 'JPY',
    });
    expect(TripStayCodec.toMap(ryokan()).containsKey('extras'), isFalse);
    expect(extras.taxTotal(3, 2), 1200);
    expect(
      TripStayValidator.problems(
        ryokan(extras: const TripStayExtras(taxPersons: 60)),
      ),
      contains(TripStayProblem.extrasInvalid),
    );
  });

  testWidgets('card shows arrival, access and the city tax total', (
    tester,
  ) async {
    await open(
      tester,
      FakeTripStaysRepository(),
      stays: [
        ryokan(
          extras: const TripStayExtras(
            doorCode: '1234#',
            wifiName: 'Guest',
            wifiPassword: 'sakura',
            lateArrivalTime: '23:30',
            receptionContact: 'Kenji',
            taxMinorUnits: 200,
            taxCurrency: 'JPY',
          ),
        ),
      ],
    );
    expect(find.text('Arrivo alle 23:30 · Reception: Kenji'), findsOneWidget);
    expect(find.text('Codice porta: 1234#'), findsOneWidget);
    expect(find.text('Wi-Fi: Guest · sakura'), findsOneWidget);
    expect(find.textContaining('× 3 notti × 2 persone)'), findsOneWidget);
  });

  testWidgets('editor saves arrival, access and tax', (tester) async {
    final repo = FakeTripStaysRepository();
    await open(tester, repo);
    await tapKey(tester, 'stays-add');
    await tester.enterText(find.byKey(const Key('stay-name')), 'Ryokan');
    await tester.enterText(find.byKey(const Key('stay-door-code')), '4321');
    await tester.enterText(find.byKey(const Key('stay-wifi-name')), 'Casa');
    await tester.enterText(find.byKey(const Key('stay-reception')), 'Yuki');
    await tester.enterText(find.byKey(const Key('stay-tax-cost')), '300');
    await tester.enterText(find.byKey(const Key('stay-tax-persons')), '3');
    await tapKey(tester, 'stay-save');
    final saved = repo.created.single.extras;
    expect(saved.doorCode, '4321');
    expect(saved.wifiName, 'Casa');
    expect(saved.receptionContact, 'Yuki');
    expect((saved.taxMinorUnits, saved.taxCurrency), (300, 'JPY'));
    expect(saved.taxPersons, 3);
  });
}

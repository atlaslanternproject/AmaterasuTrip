// Test automatici dei contatti degli alloggi: cache dei dati Google,
// telefono e sito compilati dalla ricerca, pop-up "Contatta".
// Casi, ad esempio: "Google fills phone and website only when empty", "Contatta is hidden without contacts".

import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info_cached.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support/fake_trip_stays.dart';
import 'support/fake_places.dart';

Future<void> tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Google data is asked once per place, retried after an error', () async {
    var calls = 0;
    var fail = true;
    final info = CachedAmaterasuPlaceInfo(
      loadContacts: (id, lang) async {
        calls++;
        if (fail) throw StateError('offline');
        return const AmaterasuPlaceContacts(phone: '+81 75 1');
      },
      loadPhotos: (id, lang) async {
        calls++;
        return const [AmaterasuPlacePhoto(url: 'https://p/1')];
      },
    );
    await expectLater(
      info.contacts('p1', languageCode: 'it'),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    fail = false;
    expect((await info.contacts('p1', languageCode: 'it'))?.phone, '+81 75 1');
    await info.contacts('p1', languageCode: 'it');
    await info.photos('p1', languageCode: 'it');
    await info.photos('p1', languageCode: 'it');
    expect(calls, 3);
  });

  testWidgets('Google fills phone and website only when empty', (tester) async {
    await tall(tester);
    final repo = FakeTripStaysRepository();
    final info = FakePlaceInfo(
      contactsResult: const AmaterasuPlaceContacts(
        phone: '+81 75-344-8888',
        website: 'https://granvia.jp',
      ),
    );
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: const [],
        repository: repo,
        placeInfo: info,
        extra: [amaterasuPlaceSearchProvider.overrideWithValue(FakePlaces())],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stays-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stay-property-url')),
      'https://mio.example',
    );
    await tester.enterText(find.byKey(const Key('stay-search')), 'granvia');
    await tester.tap(find.byKey(const Key('stay-search-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    expect(info.contactCalls, ['ChIJ-kyoto']);

    await tester.enterText(find.byKey(const Key('stay-email')), 'non valida');
    await tester.pumpAndSettle();
    expect(
      find.text('Scrivi un\'email valida, ad esempio nome@esempio.it.'),
      findsWidgets,
    );
    await tester.enterText(find.byKey(const Key('stay-email')), 'a@granvia.jp');
    await tester.ensureVisible(find.byKey(const Key('stay-save')));
    await tester.tap(find.byKey(const Key('stay-save')));
    await tester.pumpAndSettle();
    final stay = repo.created.single;
    expect(stay.phone, '+81 75-344-8888');
    expect(stay.propertyUrl, 'https://mio.example');
    expect(stay.email, 'a@granvia.jp');
  });

  testWidgets('changing Google place updates its phone and website, '
      'never what the user typed', (tester) async {
    await tall(tester);
    final repo = FakeTripStaysRepository();
    final info = FakePlaceInfo(
      contactsResult: const AmaterasuPlaceContacts(
        phone: '+81 1111',
        website: 'https://primo.jp',
      ),
    );
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: const [],
        repository: repo,
        placeInfo: info,
        extra: [amaterasuPlaceSearchProvider.overrideWithValue(FakePlaces())],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stays-add')));
    await tester.pumpAndSettle();
    Future<void> choosePlace() async {
      await tester.enterText(find.byKey(const Key('stay-search')), 'granvia');
      await tester.tap(find.byKey(const Key('stay-search-go')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hotel Granvia'));
      await tester.pumpAndSettle();
    }

    await choosePlace();
    await tester.enterText(
      find.byKey(const Key('stay-property-url')),
      'https://scritto-a-mano.it',
    );
    info.contactsResult = const AmaterasuPlaceContacts(
      phone: '+81 2222',
      website: 'https://secondo.jp',
    );
    await choosePlace();
    await tester.ensureVisible(find.byKey(const Key('stay-save')));
    await tester.tap(find.byKey(const Key('stay-save')));
    await tester.pumpAndSettle();
    final stay = repo.created.single;
    expect(stay.phone, '+81 2222');
    expect(stay.propertyUrl, 'https://scritto-a-mano.it');
    expect(stay.email, isNull);
  });

  testWidgets('a place with contacts shows Contatta in every view', (
    tester,
  ) async {
    await tall(tester);
    final saved = testStay(
      's1',
      placeId: 'ChIJ-kyoto',
      phone: '+81 75-344-8888',
      propertyUrl: 'https://granvia.jp',
    );
    for (final view in ['cards', 'list', 'details']) {
      SharedPreferences.setMockInitialValues({
        'amaterasu.stays.v1.anna.t1.view': view,
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        staysTestApp(
          const TripHotelsPage(tripId: 't1'),
          stays: [saved],
          repository: FakeTripStaysRepository(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Contatta').evaluate().length +
            find.byKey(const Key('stay-contact')).evaluate().length,
        greaterThan(0),
        reason: view,
      );
    }
  });

  testWidgets('Contatta is hidden without contacts', (tester) async {
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')],
        repository: FakeTripStaysRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-contact')), findsNothing);
  });

  testWidgets('Contatta: call, write, open and copy', (tester) async {
    await tall(tester);
    final launch = FakeLaunch();
    await tester.pumpWidget(
      staysTestApp(
        TripHotelsPage(tripId: 't1', launch: launch.call),
        stays: [
          testStay(
            's1',
            phone: '+81 (75) 344',
            email: 'a@hotel.jp',
            propertyUrl: 'https://hotel.jp',
          ),
        ],
        repository: FakeTripStaysRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stay-contact')));
    await tester.pumpAndSettle();
    expect(find.text('Contatta Hotel Kyoto'), findsOneWidget);

    for (final id in ['phone', 'email', 'site']) {
      await tester.tap(find.byKey(Key('stay-contact-$id-action')));
      await tester.pumpAndSettle();
    }
    expect(launch.calls.map((c) => c.$1.toString()), [
      'tel:+8175344',
      'mailto:a@hotel.jp',
      'https://hotel.jp',
    ]);
    expect(launch.calls.last.$2, LaunchMode.externalApplication);

    await tester.tap(find.byKey(const Key('stay-contact-email-copy')));
    await tester.pumpAndSettle();
    expect(find.text('Copiato negli appunti.'), findsOneWidget);
  });
}

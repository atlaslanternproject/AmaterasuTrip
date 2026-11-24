// Test automatici del carosello foto degli alloggi.
// Casi, ad esempio: "without a Google place there is a placeholder and no request", "only cards near the screen ask for photos".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

const _photos = [
  AmaterasuPlacePhoto(
    url: 'https://p/1',
    authors: [AmaterasuPhotoAuthor(name: 'Aiko')],
  ),
  AmaterasuPlacePhoto(
    url: 'https://p/2',
    authors: [AmaterasuPhotoAuthor(name: 'Ben')],
  ),
  AmaterasuPlacePhoto(url: 'https://p/3'),
];

class _ThrowingInfo extends FakePlaceInfo {
  @override
  Future<List<AmaterasuPlacePhoto>> photos(
    String placeId, {
    required String languageCode,
  }) async => throw StateError('quota');
}

void main() {
  testWidgets('without a Google place there is a placeholder and no request', (
    tester,
  ) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')],
        repository: FakeTripStaysRepository(),
        placeInfo: info,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-placeholder')), findsOneWidget);
    expect(info.photoCalls, isEmpty);
  });

  testWidgets('first photo in the card; viewer with arrows and authors', (
    tester,
  ) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(),
        placeInfo: info,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photos')), findsOneWidget);
    // In the card: first photo, count and Google mark, no author names.
    expect(find.text('Aiko'), findsNothing);
    expect(find.byKey(const Key('stay-photo-count')), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.byKey(const Key('stay-photo-next')), findsNothing);

    await tester.tap(find.byKey(const Key('stay-photos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-viewer')), findsOneWidget);
    expect(find.text('Aiko'), findsOneWidget);
    expect(find.byKey(const Key('stay-photo-prev')), findsNothing);

    await tester.tap(find.byKey(const Key('stay-photo-next')));
    await tester.pumpAndSettle();
    expect(find.text('Ben'), findsOneWidget);
    expect(find.byKey(const Key('stay-photo-prev')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stay-photo-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-next')), findsNothing);
    await tester.tap(find.byKey(const Key('stay-photo-close')));
    await tester.pumpAndSettle();

    // Rebuilding the page does not ask Google again.
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(),
        placeInfo: info,
      ),
    );
    await tester.pumpAndSettle();
    expect(info.photoCalls, ['ChIJ1']);
  });

  testWidgets('a failed request shows the placeholder', (tester) async {
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(),
        placeInfo: _ThrowingInfo(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-placeholder')), findsOneWidget);
  });

  for (final (width, height) in [(1000.0, 220.0), (360.0, 160.0)]) {
    testWidgets('photo on top, $height high at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        staysTestApp(
          const TripHotelsPage(tripId: 't1'),
          stays: [testStay('s1')],
          repository: FakeTripStaysRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final photo = find.byKey(const Key('stay-photo-placeholder'));
      expect(tester.getSize(photo).height, height);
      expect(
        tester.getTopLeft(photo).dy,
        lessThan(tester.getTopLeft(find.text('Hotel Kyoto')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('only cards near the screen ask for photos', (tester) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(
      staysTestApp(
        const TripHotelsPage(tripId: 't1'),
        stays: [
          for (var i = 0; i < 12; i++)
            testStay(
              's$i',
              name: 'Hotel $i',
              day: 1 + i,
              nights: 1,
              placeId: 'p$i',
            ),
        ],
        repository: FakeTripStaysRepository(),
        placeInfo: info,
      ),
    );
    await tester.pumpAndSettle();
    expect(info.photoCalls.length, lessThan(6));
    expect(info.photoCalls.first, 'p0');
  });
}

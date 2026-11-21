// Test automatici del carosello foto degli alloggi.
// Casi, ad esempio: "without a Google place there is a placeholder and no request", "only cards near the screen ask for photos".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

const _photos = [
  TripStayPlacePhoto(url: 'https://p/1',
      authors: [TripStayPhotoAuthor(name: 'Aiko')]),
  TripStayPlacePhoto(url: 'https://p/2',
      authors: [TripStayPhotoAuthor(name: 'Ben')]),
  TripStayPlacePhoto(url: 'https://p/3'),
];

class _ThrowingInfo extends FakePlaceInfo {
  @override
  Future<List<TripStayPlacePhoto>> photos(String placeId,
      {required String languageCode}) async => throw StateError('quota');
}

void main() {
  testWidgets('without a Google place there is a placeholder and no request',
      (tester) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1')], repository: FakeTripStaysRepository(),
        placeInfo: info));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-placeholder')), findsOneWidget);
    expect(info.photoCalls, isEmpty);
  });

  testWidgets('photos: one request, arrows, dots and authors', (tester) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(), placeInfo: info));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photos')), findsOneWidget);
    expect(find.text('Aiko'), findsOneWidget);
    expect(find.byKey(const Key('stay-photo-prev')), findsNothing);

    await tester.tap(find.byKey(const Key('stay-photo-next')));
    await tester.pumpAndSettle();
    expect(find.text('Ben'), findsOneWidget);
    expect(find.byKey(const Key('stay-photo-prev')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stay-photo-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-next')), findsNothing);

    // Rebuilding the page does not ask Google again.
    await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(), placeInfo: info));
    await tester.pumpAndSettle();
    expect(info.photoCalls, ['ChIJ1']);
  });

  testWidgets('a failed request shows the placeholder', (tester) async {
    await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
        stays: [testStay('s1', placeId: 'ChIJ1')],
        repository: FakeTripStaysRepository(), placeInfo: _ThrowingInfo()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-photo-placeholder')), findsOneWidget);
  });

  testWidgets('only cards near the screen ask for photos', (tester) async {
    final info = FakePlaceInfo(photosResult: _photos);
    await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
        stays: [
          for (var i = 0; i < 12; i++)
            testStay('s$i', name: 'Hotel $i', day: 1 + i, nights: 1,
                placeId: 'p$i'),
        ],
        repository: FakeTripStaysRepository(), placeInfo: info));
    await tester.pumpAndSettle();
    expect(info.photoCalls.length, lessThan(6));
    expect(info.photoCalls.first, 'p0');
  });
}

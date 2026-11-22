// Test automatici del modulo Luogo condiviso (lib/core/places) con le
// impostazioni predefinite che useranno le nuove sezioni.
// Casi, ad esempio: "search picks a place with default keys", "contact dialog with default keys".

import 'package:amaterasutrip/core/places/amaterasu_contact_validator.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_contact_dialog.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_place_photo_carousel.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_place_search_field.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/trips/stays/support/fake_places.dart';
import '../../features/trips/stays/support/fake_trip_stays.dart' show FakePlaceInfo;

Widget app(Widget child) => ProviderScope(
  overrides: [amaterasuPlaceInfoProvider.overrideWithValue(FakePlaceInfo())],
  child: MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  test('phone and email checks', () {
    expect(AmaterasuContactValidator.isPhone('+39 06 1234'), isTrue);
    expect(AmaterasuContactValidator.isPhone('abc'), isFalse);
    expect(AmaterasuContactValidator.isEmail('a@b.it'), isTrue);
    expect(AmaterasuContactValidator.isEmail('a@b'), isFalse);
    expect(amaterasuHasContacts(), isFalse);
    expect(amaterasuHasContacts(email: 'a@b.it'), isTrue);
  });

  testWidgets('search picks a place with default keys', (tester) async {
    TripDestination? picked;
    await tester.pumpWidget(app(AmaterasuPlaceSearchField(
      places: FakePlaces(),
      onPicked: (place) async => picked = place,
    )));
    await tester.enterText(find.byKey(const Key('place-search')), 'granvia');
    await tester.tap(find.byKey(const Key('place-search-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    expect(picked?.placeId, 'ChIJ-kyoto');
    expect(find.text('Hotel Granvia'), findsNothing);
  });

  testWidgets('contact dialog with default keys', (tester) async {
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () => showAmaterasuContactDialog(context,
            title: 'Contatta Trattoria', phone: '+39 06 1'),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('place-contact-dialog')), findsOneWidget);
    expect(find.byKey(const Key('place-contact-phone-action')), findsOneWidget);
    expect(find.byKey(const Key('place-contact-email-action')), findsNothing);
  });

  testWidgets('photo placeholder with the chosen icon', (tester) async {
    await tester.pumpWidget(app(const AmaterasuPlacePhotoCarousel(
      placeId: null,
      height: 120,
      placeholderIcon: Icons.restaurant,
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('place-photo-placeholder')), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(const AmaterasuPlacePhoto(url: 'https://x').authors, isEmpty);
  });
}

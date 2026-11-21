// Test automatici dei link condivisi (core/links).
// Casi, ad esempio: "valid links follow the Bucket List rules", "failed opening offers Copia link".

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

class _Launch {
  _Launch({this.result = true, this.throws = false});
  final bool result;
  final bool throws;
  final calls = <(Uri, LaunchMode, String?)>[];

  Future<bool> call(Uri uri, {LaunchMode mode = LaunchMode.platformDefault,
      String? webOnlyWindowName}) async {
    calls.add((uri, mode, webOnlyWindowName));
    if (throws) throw PlatformException(code: 'x');
    return result;
  }
}

Widget app(Widget child, {String locale = 'it'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('valid links follow the Bucket List rules', () {
    expect(AmaterasuWebLink.parse(' https://booking.com/x ').toString(),
        'https://booking.com/x');
    expect(AmaterasuWebLink.isValid('http://hotel.example.jp'), isTrue);
    for (final bad in ['', '   ', 'ftp://a.com', 'booking.com', 'https://',
      'https://a.com/a b', 'https://a.com/${'x' * 2048}', null]) {
      expect(AmaterasuWebLink.isValid(bad), isFalse, reason: '$bad');
    }
  });

  test('chip label is the site name or the fallback', () {
    expect(AmaterasuWebLink.label('https://www.airbnb.it/rooms/1', 'Apri'),
        'www.airbnb.it');
    expect(AmaterasuWebLink.label('not a link', 'Apri'), 'Apri');
  });

  test('Google Maps address is the same as in the Bucket List', () {
    expect(
      AmaterasuWebLink.googleMaps(name: 'Hotel Kyoto', placeId: 'ChIJ1'),
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': 'Hotel Kyoto',
        'query_place_id': 'ChIJ1',
      }),
    );
    expect(
      AmaterasuWebLink.googleMaps(name: 'X', latitude: 35.0, longitude: 135.5)
          .toString(),
      'https://www.google.com/maps/search/?api=1&query=35.0%2C135.5',
    );
    expect(AmaterasuWebLink.googleMaps(name: 'X'), isNull);
  });

  test('texts are exactly those of the Bucket List, in both languages', () {
    final it = lookupAppLocalizations(const Locale('it'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(it.commonLinkInvalid, 'Il link non è valido.');
    expect(en.commonLinkInvalid, 'The link is invalid.');
    expect(it.commonLinkOpenFailed,
        'Impossibile aprire il link. Puoi copiarlo e aprirlo nel browser.');
    expect(en.commonLinkOpenFailed,
        'Could not open the link. You can copy it and open it in your browser.');
    expect(it.commonLinkCopy, 'Copia link');
    expect(en.commonLinkCopy, 'Copy link');
    expect(it.commonLinkOpen, 'Apri link');
    expect(en.commonLinkOpen, 'Open link');
    expect(it.commonMapsOpenFailed, 'Impossibile aprire Google Maps.');
    expect(en.commonMapsOpenFailed, 'Could not open Google Maps.');
  });

  testWidgets('chip looks like the Bucket List one and opens a new tab',
      (tester) async {
    final launch = _Launch();
    await tester.pumpWidget(app(AmaterasuLinkChip(
      link: 'https://www.booking.com/h/1', launch: launch.call)));
    expect(find.text('www.booking.com'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.open_in_new));
    expect(icon.size, 15);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(launch.calls.single.$1.toString(), 'https://www.booking.com/h/1');
    expect(launch.calls.single.$2, LaunchMode.externalApplication);
    expect(launch.calls.single.$3, '_blank');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('invalid link: message, nothing opened', (tester) async {
    final launch = _Launch();
    await tester.pumpWidget(app(AmaterasuLinkChip(
      link: 'booking.com', label: 'Prenotazione', launch: launch.call)));
    await tester.tap(find.text('Prenotazione'));
    await tester.pumpAndSettle();
    expect(launch.calls, isEmpty);
    expect(find.text('Il link non è valido.'), findsOneWidget);
  });

  for (final throws in [false, true]) {
    testWidgets('failed opening offers Copia link (throws: $throws)',
        (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
      final launch = _Launch(result: false, throws: throws);
      await tester.pumpWidget(app(AmaterasuLinkChip(
        link: ' https://hotel.example.jp/stay ', launch: launch.call)));
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(find.text(
        'Impossibile aprire il link. Puoi copiarlo e aprirlo nel browser.'),
        findsOneWidget);
      await tester.tap(find.text('Copia link'));
      await tester.pumpAndSettle();
      expect(copied, ['https://hotel.example.jp/stay']);
    });
  }

  testWidgets('Google Maps: platform default, error message if it fails',
      (tester) async {
    final launch = _Launch(result: false);
    final uri = AmaterasuWebLink.googleMaps(name: 'Hotel', placeId: 'p1')!;
    await tester.pumpWidget(app(Builder(builder: (context) => TextButton(
      onPressed: () => AmaterasuLinkOpener.openMaps(context, uri,
        failedMessage: AppLocalizations.of(context)!.commonMapsOpenFailed,
        launch: launch.call),
      child: const Text('map'),
    )), locale: 'en'));
    await tester.tap(find.text('map'));
    await tester.pumpAndSettle();
    expect(launch.calls.single.$1, uri);
    expect(launch.calls.single.$2, LaunchMode.platformDefault);
    expect(find.text('Could not open Google Maps.'), findsOneWidget);
  });
}

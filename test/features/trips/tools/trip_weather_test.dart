// Test automatici del Meteo (nuova tappa 1b): regole fisse (cielo, cosa
// mettere, aria e pollini), link a 3B Meteo, lettura dei dati e pagina con
// dati finti: giorni del viaggio, scelta del giorno, errori e "Riprova",
// nessun errore di spazio al 130 % su telefono. Nessuna chiamata di rete.

import 'package:amaterasutrip/features/trips/tools/weather/trip_weather_data.dart';
import 'package:amaterasutrip/features/trips/tools/weather/trip_weather_labels.dart';
import 'package:amaterasutrip/features/trips/tools/weather/trip_weather_page.dart';
import 'package:amaterasutrip/features/trips/tools/weather/trip_weather_provider.dart';
import 'package:amaterasutrip/features/trips/tools/weather/trip_weather_rules.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

Map<Object?, Object?> day(
  String date, {
  double max = 14,
  int code = 61,
  double rain = 80,
  double precip = 5.5,
}) => {
  'date': date,
  'code': code,
  'max': max,
  'min': 7,
  'rain': rain,
  'precip': precip,
  'sunrise': '${date}T07:12',
  'sunset': '${date}T16:44',
  'uv': 1,
  'wind': 22,
};

final Map<Object?, Object?> fakeWeather = {
  'place': {'name': 'Roma', 'countryCode': 'IT'},
  'tripStart': '2026-11-26',
  'tripEnd': '2026-11-28',
  'forecast': {
    'fetchedAt': DateTime(2026, 11, 25, 9, 5).millisecondsSinceEpoch,
    'days': [
      day('2026-11-25', max: 30, code: 0, rain: 0, precip: 0),
      day('2026-11-26'),
    ],
    'hours': [
      {'time': '2026-11-25T10:00', 'temp': 25, 'rain': 0, 'code': 0},
      {'time': '2026-11-26T10:00', 'temp': 11, 'rain': 90, 'code': 61},
    ],
  },
  'air': {
    'days': [
      {
        'date': '2026-11-26',
        'aqi': 45,
        'pollen': {'birch': 60, 'grass': 0},
      },
    ],
  },
  'climate': {
    'years': [2025, 2024, 2023],
    'max': 15.2,
    'min': 6.8,
    'precip': 2.4,
    'rainyDays': 30,
  },
  'stale': false,
};

var calls = 0;

Future<void> open(
  WidgetTester tester, {
  double width = 1000,
  TripWeatherLoader? loader,
}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  calls = 0;
  await tester.pumpWidget(
    sectionsTestApp(
      const TripWeatherPage(tripId: 't1'),
      overrides: [
        tripWeatherLoaderProvider.overrideWithValue(
          loader ??
              (id) async {
                calls++;
                return fakeWeather;
              },
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('sky groups and fixed clothing rules', () {
    expect(tripWeatherSkyOf(0), TripWeatherSky.clear);
    expect(tripWeatherSkyOf(63), TripWeatherSky.rain);
    expect(tripWeatherSkyOf(81), TripWeatherSky.rain);
    expect(tripWeatherSkyOf(75), TripWeatherSky.snow);
    expect(tripWeatherSkyOf(96), TripWeatherSky.storm);
    expect(tripWeatherWearOf(max: 31, min: 22, uv: 9), [
      TripWeatherWear.light,
      TripWeatherWear.sunHat,
    ]);
    expect(tripWeatherWearOf(max: 24, min: 12, uv: 7), [
      TripWeatherWear.tshirt,
      TripWeatherWear.lightLayer,
      TripWeatherWear.sunscreen,
    ]);
    expect(tripWeatherWearOf(max: 9, min: 3, rain: 70, wind: 45), [
      TripWeatherWear.warmCoat,
      TripWeatherWear.umbrella,
      TripWeatherWear.windproof,
    ]);
    expect(tripWeatherWearOf(max: 1, min: -4, code: 73), [
      TripWeatherWear.heavyCoat,
      TripWeatherWear.hatGloves,
      TripWeatherWear.boots,
    ]);
    expect(tripWeatherWearOf(max: null), isEmpty);
  });

  test('air and pollen levels', () {
    expect(tripWeatherAirLevel(15), TripWeatherLevel.good);
    expect(tripWeatherAirLevel(55), TripWeatherLevel.moderate);
    expect(tripWeatherAirLevel(120), TripWeatherLevel.veryPoor);
    expect(tripWeatherPollenLevel(5), TripWeatherLevel.good);
    expect(tripWeatherPollenLevel(60), TripWeatherLevel.poor);
  });

  test('3B Meteo link: Italian city page, home page abroad', () {
    expect(
      tripWeather3bLink('Roma', 'IT'),
      'https://www.3bmeteo.com/meteo/roma',
    );
    expect(
      tripWeather3bLink('Reggio Emilia', 'it'),
      'https://www.3bmeteo.com/meteo/reggio+emilia',
    );
    expect(
      tripWeather3bLink('Forlì', 'IT'),
      'https://www.3bmeteo.com/meteo/forli',
    );
    expect(
      tripWeather3bLink(null, 'IT'),
      'https://www.3bmeteo.com/meteo/italia',
    );
    expect(tripWeather3bLink('Parigi', 'FR'), 'https://www.3bmeteo.com/');
  });

  test('data: trip days, hours and air of a day, empty answer', () {
    final w = TripWeather.fromMap(fakeWeather);
    expect(w.days.length, 2);
    expect(w.inTrip('2026-11-25'), isFalse);
    expect(w.inTrip('2026-11-26'), isTrue);
    expect(w.hoursOf('2026-11-26').single.temp, 11);
    expect(w.airOf('2026-11-26')!.pollen, {'birch': 60.0, 'grass': 0.0});
    expect(w.climate!.years, [2025, 2024, 2023]);
    final empty = TripWeather.fromMap(const {});
    expect(empty.days, isEmpty);
    expect(empty.climate, isNull);
    expect(empty.stale, isFalse);
  });

  testWidgets('page: first trip day chosen, another day on tap', (
    tester,
  ) async {
    await open(tester);
    expect(calls, 1);
    expect(find.byKey(const Key('weather-trip-2026-11-26')), findsOneWidget);
    expect(find.byKey(const Key('weather-trip-2026-11-25')), findsNothing);
    // The first trip day is selected: its clothing, air and pollen.
    expect(find.byKey(const Key('weather-wear-umbrella')), findsOneWidget);
    expect(find.textContaining('Qualità dell\'aria: moderata'), findsNothing);
    await tester.tap(find.text('Aria e pollini'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Qualità dell\'aria: discreta'), findsNothing);
    expect(find.textContaining('moderata (indice europeo 45)'), findsOneWidget);
    expect(find.text('Betulla: alto'), findsOneWidget);
    expect(find.textContaining('Graminacee'), findsNothing);
    expect(find.textContaining('massime 15°'), findsOneWidget);
    expect(find.textContaining('Open-Meteo.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weather-day-2026-11-25')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weather-wear-light')), findsOneWidget);
    expect(find.byKey(const Key('weather-wear-umbrella')), findsNothing);
    expect(find.textContaining('nessun dato'), findsOneWidget);
    expect(find.text('Apri su 3B Meteo'), findsOneWidget);
  });

  testWidgets('trip beyond the forecast: explained', (tester) async {
    await open(
      tester,
      loader: (id) async => {
        ...fakeWeather,
        'tripStart': '2027-08-01',
        'tripEnd': '2027-08-10',
      },
    );
    expect(find.textContaining('oltre i 16 giorni'), findsOneWidget);
  });

  testWidgets('errors: retry after unavailable, no destination', (
    tester,
  ) async {
    var fail = true;
    await open(
      tester,
      loader: (id) async {
        if (fail) {
          throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
        }
        return fakeWeather;
      },
    );
    expect(find.textContaining('Meteo non disponibile'), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const Key('weather-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weather-page')), findsOneWidget);

    await open(
      tester,
      loader: (id) async => throw FirebaseFunctionsException(
        message: 'no-destination',
        code: 'failed-precondition',
      ),
    );
    expect(find.textContaining('non ha una destinazione'), findsOneWidget);
    expect(find.byKey(const Key('weather-retry')), findsNothing);
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, width: 390);
    expect(tester.takeException(), isNull);
  });
}

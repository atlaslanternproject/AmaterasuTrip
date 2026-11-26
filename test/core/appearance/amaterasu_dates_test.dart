// Test automatici del formato di data e ora (Extra E4): "come la lingua"
// resta il formato di prima, gg/mm/aaaa e aaaa-mm-gg, ore a 12 ore con
// AM/PM; una card di prenotazione segue la scelta di Aspetto.
// Casi, ad esempio: "day formats", "a booking card follows the choice".

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/trips/sections/support/fake_section_store.dart';
import 'amaterasu_appearance_test.dart' show FakeAppearanceStore;

class FixedAppearance extends AmaterasuAppearanceController {
  FixedAppearance(this.value);

  final AmaterasuAppearance value;

  @override
  AmaterasuAppearance build() => value;
}

Future<String> render(
  WidgetTester tester,
  AmaterasuAppearance a,
  String Function(BuildContext) text,
) async {
  late String out;
  await tester.pumpWidget(
    ProviderScope(
      // A new container for every check.
      key: UniqueKey(),
      overrides: [
        amaterasuAppearanceProvider.overrideWith(() => FixedAppearance(a)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            out = text(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return out;
}

void main() {
  final day = DateTime(2027, 4, 9);

  testWidgets('every format, the long one in Italian and English', (
    tester,
  ) async {
    final d = DateTime(2027, 8, 30);
    final out = <String, String>{};
    for (final locale in const [Locale('it'), Locale('en')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('it'), Locale('en')],
          home: Builder(
            builder: (context) {
              for (final f in AmaterasuAppearance.dateFormats) {
                out['${locale.languageCode}-$f'] = AmaterasuDates.withFormat(
                  context,
                  f,
                  d,
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(out['it-dmy'], '30/08/2027');
    expect(out['it-mdy'], '08/30/2027');
    expect(out['it-ymd'], '2027-08-30');
    expect(out['it-ymdSlash'], '2027/08/30');
    expect(out['it-long'], '30 agosto 2027');
    expect(out['en-long'], 'August 30, 2027');
  });

  testWidgets('day formats and 12-hour time', (tester) async {
    const ymd = AmaterasuAppearance(dateFormat: 'ymd');
    const dmy = AmaterasuAppearance(dateFormat: 'dmy', timeFormat: '12');
    expect(
      await render(tester, ymd, (c) => AmaterasuDates.day(c, day)),
      '2027-04-09',
    );
    expect(
      await render(tester, dmy, (c) => AmaterasuDates.day(c, day)),
      '09/04/2027',
    );
    expect(
      await render(tester, dmy, (c) => AmaterasuDates.time(c, '14:05')),
      '2:05 PM',
    );
    expect(
      await render(tester, dmy, (c) => AmaterasuDates.time(c, '00:30')),
      '12:30 AM',
    );
    expect(
      await render(
        tester,
        const AmaterasuAppearance(),
        (c) => AmaterasuDates.time(c, '14:05'),
      ),
      '14:05',
    );
    // "Like the language": exactly the Material format used before.
    expect(
      await render(
        tester,
        const AmaterasuAppearance(),
        (c) =>
            AmaterasuDates.day(c, day) ==
                MaterialLocalizations.of(c).formatMediumDate(day)
            ? 'same'
            : 'different',
      ),
      'same',
    );
  });

  testWidgets('a booking card follows the choice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bigWindow(tester);
    await tester.pumpWidget(
      sectionsTestApp(
        TripBookingsPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [
          amaterasuAppearanceStoreProvider.overrideWithValue(
            FakeAppearanceStore(
              const AmaterasuAppearance(dateFormat: 'ymd', timeFormat: '12'),
            ),
          ),
          tripReservationsStoreProvider.overrideWithValue(
            FakeSectionStore<TripReservation>(
              items: [
                TripReservation(
                  id: 'r',
                  tripId: 't1',
                  createdByUid: 'anna',
                  name: 'Museo',
                  category: TripReservationCategory.entry,
                  date: day,
                  time: '14:05',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2027-04-09 · 2:05 PM'), findsWidgets);
  });
}

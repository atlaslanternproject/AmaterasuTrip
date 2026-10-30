import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:amaterasutrip/features/trips/presentation/utils/trip_date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
    await initializeDateFormatting('en');
  });
  group('Trip date formatter', () {
    test('Italian date always includes its year', () {
      final date = DateTime(2027, 4, 12);
      final text = formatTripDateWithYear(date, const Locale('it'));

      expect(text, contains('2027'));
      expect(text, contains('12'));
    });

    test('English date always includes its year', () {
      final date = DateTime(2027, 4, 12);
      final text = formatTripDateWithYear(date, const Locale('en'));

      expect(text, contains('2027'));
      expect(text, contains('12'));
    });

    test('Different years remain distinguishable', () {
      final first = formatTripDateWithYear(
        DateTime(2027, 12, 30),
        const Locale('it'),
      );
      final second = formatTripDateWithYear(
        DateTime(2028, 1, 3),
        const Locale('it'),
      );

      expect(first, contains('2027'));
      expect(second, contains('2028'));
      expect(first, isNot(second));
    });

    test('Formatting does not change the input date', () {
      final date = DateTime(2027, 4, 12);

      formatTripDateWithYear(date, const Locale('en'));

      expect(date.year, 2027);
      expect(date.month, 4);
      expect(date.day, 12);
    });

    test('Italian and English dates are localized', () {
      final date = DateTime(2027, 4, 12);

      final italian = formatTripDateWithYear(date, const Locale('it'));
      final english = formatTripDateWithYear(date, const Locale('en'));

      expect(italian, contains('2027'));
      expect(english, contains('2027'));
      expect(italian, isNot(english));
    });
  });
}

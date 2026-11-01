import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';

abstract final class BudgetCurrency {
  static List<String> get supported => CurrencyMinorUnits.supportedCodes;

  static String normalize(String raw) {
    final text = raw.trim().toUpperCase();

    if (text == 'JPT' ||
        text.startsWith('JPT -') ||
        text.startsWith('JPT ·') ||
        text.contains('YEN GIAPPONESE') ||
        text.contains('JAPANESE YEN')) {
      return 'JPY';
    }

    final first = text.split(RegExp(r'[\s·\-]+')).first;
    if (supported.contains(first)) return first;

    throw FormatException('Valuta non supportata: $raw');
  }

  static int decimals(String currency) =>
      CurrencyMinorUnits.decimals(normalize(currency));
}

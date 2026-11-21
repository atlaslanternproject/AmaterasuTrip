// Lettura e controllo degli importi scritti dall'utente,
// nel numero di decimali giusto per la valuta.

import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';

abstract final class BudgetMoneyInput {
  /// Amount as plain text for an input field, the opposite of [parse]
  /// (e.g. 5000 EUR -> "50.00", 1200 JPY -> "1200").
  static String plainText(int minor, String currency) {
    final decimals = CurrencyMinorUnits.decimals(currency);
    if (decimals == 0) return '$minor';
    final factor = CurrencyMinorUnits.factor(currency);
    final fraction = (minor % factor).toString().padLeft(decimals, '0');
    return '${minor ~/ factor}.$fraction';
  }

  static int parse(String input, String currency, {bool allowZero = false}) {
    final decimals = CurrencyMinorUnits.decimals(currency);
    final normalized = input.trim().replaceAll(',', '.');

    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(normalized)) {
      throw const FormatException('Importo non valido.');
    }

    final parts = normalized.split('.');
    if (parts.length > 1 && parts[1].length > decimals) {
      throw FormatException(
        'Questa valuta accetta al massimo $decimals decimali.',
      );
    }

    final whole = int.parse(parts[0]);
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts[1].padRight(decimals, '0'));

    final total = whole * CurrencyMinorUnits.factor(currency) + fraction;

    if (total < 0 || (!allowZero && total == 0) || total > 9007199254740991) {
      throw const FormatException('Importo fuori intervallo.');
    }
    return total;
  }
}

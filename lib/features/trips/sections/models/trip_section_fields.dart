// Aiuti comuni per leggere, scrivere e controllare i campi delle sezioni,
// con gli stessi limiti di firestore.rules (testi, link, membri, spesa
// collegata e costo previsto).

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';

abstract final class TripSectionFields {
  static const nameMax = 200;
  static const placeMax = 300;
  static const codeMax = 100;
  static const shortMax = 120;
  static const notesMax = 10000;
  static const uidsMax = 50;

  /// Highest expected cost in minor units (same limit as firestore.rules).
  static const costMax = 1000000000000;
  static final _expenseId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Trimmed text, or null when empty.
  static String? clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? readText(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static double? readNumber(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is num ? value.toDouble() : null;
  }

  static List<String> readUids(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is List ? value.whereType<String>().toList() : const [];
  }

  static bool longer(String? value, int max) => (value?.length ?? 0) > max;

  static bool badLink(String? value) =>
      value != null && !AmaterasuWebLink.isValid(value);

  static bool badExpenseId(String? value) =>
      value != null && !_expenseId.hasMatch(value);

  /// Expected cost: both empty, or an amount above zero in a known currency.
  static bool badCost(int? minorUnits, String? currency) =>
      minorUnits != null &&
      (minorUnits <= 0 ||
          minorUnits > costMax ||
          !CurrencyMinorUnits.supportedCodes.contains(currency));

  /// Saved cost fields (none when there is no amount).
  static Map<String, dynamic> costMap(int? minorUnits, String? currency) =>
      minorUnits == null || currency == null
      ? const {}
      : {
          'estimatedCostMinorUnits': minorUnits,
          'estimatedCostCurrency': currency,
        };

  /// Cost read from a document, or (null, null) when incomplete.
  static (int?, String?) readCost(Map<String, dynamic> data) {
    final minor = data['estimatedCostMinorUnits'];
    final currency = readText(data, 'estimatedCostCurrency');
    return minor is int && currency != null ? (minor, currency) : (null, null);
  }
}

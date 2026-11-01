import '../../models/currency_exchange_rate.dart';

/// Serializes exact rational rates using decimal strings.
///
/// BigInt values are never converted to double.
abstract final class BudgetExchangeRateCodec {
  static Map<String, dynamic> encode(CurrencyExchangeRate rate) => {
    'sourceCurrency': rate.sourceCurrency,
    'targetCurrency': rate.targetCurrency,
    'numerator': rate.numerator.toString(),
    'denominator': rate.denominator.toString(),
    'observedAt': rate.observedAt.toUtc().toIso8601String(),
    'isManual': rate.isManual,
  };

  static CurrencyExchangeRate decode(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid exchange rate.');
    }

    final data = Map<String, dynamic>.from(raw);

    final source = data['sourceCurrency'];
    final target = data['targetCurrency'];
    final numerator = data['numerator'];
    final denominator = data['denominator'];
    final observedAt = data['observedAt'];
    final isManual = data['isManual'];

    if (source is! String ||
        target is! String ||
        numerator is! String ||
        denominator is! String ||
        observedAt is! String ||
        isManual is! bool) {
      throw const FormatException('Invalid exchange rate fields.');
    }

    final n = BigInt.tryParse(numerator);
    final d = BigInt.tryParse(denominator);
    final date = DateTime.tryParse(observedAt);

    if (n == null || d == null || date == null) {
      throw const FormatException('Invalid exchange rate values.');
    }

    return CurrencyExchangeRate(
      sourceCurrency: source,
      targetCurrency: target,
      numerator: n,
      denominator: d,
      observedAt: date,
      isManual: isManual,
    );
  }
}

/// Number of decimal places supported for accounting amounts.
///
/// Unknown currencies are rejected rather than silently assuming
/// that they have two fractional digits.
abstract final class CurrencyMinorUnits {
  static const Map<String, int> _digits = {
    'EUR': 2,
    'USD': 2,
    'GBP': 2,
    'CHF': 2,
    'CAD': 2,
    'AUD': 2,
    'NZD': 2,
    'SGD': 2,
    'HKD': 2,
    'CNY': 2,
    'TWD': 2,
    'KRW': 0,
    'JPY': 0,
    'VND': 0,
    'CLP': 0,
    'ISK': 0,
    'HUF': 2,
    'PLN': 2,
    'CZK': 2,
    'DKK': 2,
    'NOK': 2,
    'SEK': 2,
    'RON': 2,
    'TRY': 2,
    'THB': 2,
    'MYR': 2,
    'IDR': 2,
    'INR': 2,
    'PHP': 2,
    'BRL': 2,
    'MXN': 2,
    'ZAR': 2,
    'AED': 2,
    'SAR': 2,
    'ILS': 2,
    'EGP': 2,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
    'TND': 3,
  };

  static List<String> get supportedCodes =>
      _digits.keys.toList(growable: false);

  static int decimals(String code) {
    final result = _digits[code];
    if (result == null) {
      throw ArgumentError.value(code, 'currency', 'Unsupported currency');
    }
    return result;
  }

  static int factor(String code) {
    var result = 1;
    for (var i = 0; i < decimals(code); i++) {
      result *= 10;
    }
    return result;
  }
}

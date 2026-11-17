import 'dart:convert';

import 'package:http/http.dart' as http;

import '../calculations/currency_minor_units.dart';

/// An observed provider rate (one target major unit per base major unit).
class BudgetFxQuote {
  const BudgetFxQuote({
    required this.base,
    required this.quote,
    required this.rate,
    required this.observedDate,
    required this.requestedDate,
    required this.source,
    this.manual = false,
  });

  final String base;
  final String quote;
  final double rate;
  final DateTime observedDate;
  final DateTime? requestedDate;
  final String source;
  final bool manual;

  String get observedIso => BudgetFxService.isoDate(observedDate);

  static BudgetFxQuote? fromLocked(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(raw);
    final value = data['rate'];
    final rate = value is num ? value.toDouble() : double.nan;
    final date = DateTime.tryParse(data['date']?.toString() ?? '');
    final base = data['base']?.toString() ?? '';
    final quote = data['quote']?.toString() ?? '';
    if (date == null ||
        !rate.isFinite ||
        rate <= 0 ||
        !BudgetFxService.validCurrency(base) ||
        !BudgetFxService.validCurrency(quote)) {
      return null;
    }
    return BudgetFxQuote(
      base: base,
      quote: quote,
      rate: rate,
      observedDate: date,
      requestedDate: DateTime.tryParse(data['requestedDate']?.toString() ?? ''),
      source: data['source']?.toString() ?? 'unknown',
      manual: data['manual'] == true,
    );
  }
}

/// Public daily FX observations; no hard-coded or fabricated rates.
/// These are presentation-only; never change original settlement amounts.
class BudgetFxService {
  BudgetFxService({Future<String> Function(Uri)? load})
    : _load = load ?? _loadNetwork;

  final Future<String> Function(Uri) _load;
  final Map<String, ({DateTime at, Future<BudgetFxQuote> value})> _cache = {};

  static bool validCurrency(String code) =>
      RegExp(r'^[A-Z]{3}$').hasMatch(code) &&
      CurrencyMinorUnits.supportedCodes.contains(code);

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<String> _loadNetwork(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Exchange rate provider unavailable.');
    }
    return response.body;
  }

  Future<BudgetFxQuote> latest(String base, String quote) =>
      _request(base, quote, null);

  Future<BudgetFxQuote> historical(String base, String quote, DateTime date) =>
      _request(base, quote, DateTime(date.year, date.month, date.day));

  Future<BudgetFxQuote> _request(String base, String quote, DateTime? date) {
    if (!validCurrency(base) || !validCurrency(quote) || base == quote) {
      return Future.error(ArgumentError('Invalid FX pair.'));
    }
    if (date != null && isoDate(date).compareTo(isoDate(DateTime.now())) > 0) {
      return Future.error(ArgumentError('FX date is in the future.'));
    }
    final dateKey = date == null ? 'latest' : isoDate(date);
    final key = '$base/$quote/$dateKey';
    final current = _cache[key];
    if (current != null &&
        (date != null ||
            DateTime.now().difference(current.at) <
                const Duration(minutes: 30))) {
      return current.value;
    }
    late final Future<BudgetFxQuote> requested;
    requested = _fetch(base, quote, date).catchError((
      Object error,
      StackTrace stack,
    ) {
      if (identical(_cache[key]?.value, requested)) {
        _cache.remove(key);
      }
      Error.throwWithStackTrace(error, stack);
    });
    _cache[key] = (at: DateTime.now(), value: requested);
    return requested;
  }

  Future<BudgetFxQuote> _fetch(
    String base,
    String quote,
    DateTime? requestedDate,
  ) async {
    // Frankfurter v2 uses ?date=YYYY-MM-DD; not a path segment.
    final uri = Uri.https(
      'api.frankfurter.dev',
      '/v2/rate/$base/$quote',
      requestedDate == null ? null : {'date': isoDate(requestedDate)},
    );
    final decoded = jsonDecode(await _load(uri));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid FX response.');
    }
    final raw = decoded['rate'];
    final rate = raw is num ? raw.toDouble() : double.nan;
    final observed = DateTime.tryParse(decoded['date']?.toString() ?? '');
    if (decoded['base']?.toString().toUpperCase() != base ||
        decoded['quote']?.toString().toUpperCase() != quote ||
        observed == null ||
        !rate.isFinite ||
        rate <= 0 ||
        isoDate(observed).compareTo(isoDate(DateTime.now())) > 0 ||
        (requestedDate != null &&
            isoDate(observed).compareTo(isoDate(requestedDate)) > 0)) {
      throw const FormatException('Unusable provider FX rate.');
    }
    return BudgetFxQuote(
      base: base,
      quote: quote,
      rate: rate,
      observedDate: observed,
      requestedDate: requestedDate,
      source: 'Frankfurter',
    );
  }

  static int? convertMinor(
    int minorUnits,
    String from,
    String to,
    BudgetFxQuote? fx,
  ) {
    if (from == to) {
      return minorUnits;
    }
    if (fx == null ||
        fx.base != from ||
        fx.quote != to ||
        !fx.rate.isFinite ||
        fx.rate <= 0) {
      return null;
    }
    final amount =
        minorUnits /
        CurrencyMinorUnits.factor(from) *
        fx.rate *
        CurrencyMinorUnits.factor(to);
    if (!amount.isFinite || amount.abs() > 9007199254740991) {
      return null;
    }
    return amount.round();
  }
}

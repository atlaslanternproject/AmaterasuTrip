// Calcoli di "Converti" (nuova tappa 1): temperatura, distanze, pesi,
// taglie delle scarpe (tabella indicativa EU/UK/US) e mancia divisa tra
// persone. Le valute usano i tassi del budget (budgetDisplayQuote), non
// questo file. Nessuna API.

abstract final class TripConvertMath {
  static double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;
  static double kmToMiles(double km) => km / 1.609344;
  static double milesToKm(double mi) => mi * 1.609344;
  static double kgToPounds(double kg) => kg / 0.45359237;
  static double poundsToKg(double lb) => lb * 0.45359237;

  /// Shoe sizes, indicative (they change between brands): EU, UK, US men,
  /// US women.
  static const shoes = [
    (eu: 36, uk: 3.5, usMen: 4.5, usWomen: 5.5),
    (eu: 37, uk: 4, usMen: 5, usWomen: 6.5),
    (eu: 38, uk: 5, usMen: 6, usWomen: 7.5),
    (eu: 39, uk: 6, usMen: 7, usWomen: 8.5),
    (eu: 40, uk: 6.5, usMen: 7.5, usWomen: 9),
    (eu: 41, uk: 7.5, usMen: 8.5, usWomen: 10),
    (eu: 42, uk: 8, usMen: 9, usWomen: 10.5),
    (eu: 43, uk: 9, usMen: 10, usWomen: 11.5),
    (eu: 44, uk: 9.5, usMen: 10.5, usWomen: 12),
    (eu: 45, uk: 10.5, usMen: 11.5, usWomen: 13),
    (eu: 46, uk: 11, usMen: 12, usWomen: 13.5),
  ];

  /// Tip on [amount] at [percent], total and share for each of [people].
  static ({double tip, double total, double each}) tip(
    double amount,
    int percent,
    int people,
  ) {
    final tip = amount * percent / 100;
    final total = amount + tip;
    return (tip: tip, total: total, each: people > 0 ? total / people : total);
  }

  /// "12,5" or "12.5" -> 12.5; null when it is not a number.
  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// Up to two decimals, without useless zeros ("12.5", "3").
  static String show(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

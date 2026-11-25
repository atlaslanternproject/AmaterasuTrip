// Aggiunte facoltative di un alloggio (v2), salvate insieme nel campo
// "extras": note di accesso (codice della porta, Wi-Fi, istruzioni),
// arrivo tardivo (orario e contatto della reception) e tassa di soggiorno
// a persona per notte con il numero di persone.

import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';
import 'trip_stay_dates.dart';

class TripStayExtras {
  const TripStayExtras({
    this.doorCode,
    this.wifiName,
    this.wifiPassword,
    this.accessNotes,
    this.lateArrivalTime,
    this.receptionContact,
    this.taxMinorUnits,
    this.taxCurrency,
    this.taxPersons,
  });

  static const shortMax = 100;
  static const notesMax = 1000;
  static const contactMax = 200;
  static const taxMax = 100000000;
  static const personsMax = 50;

  final String? doorCode;
  final String? wifiName;
  final String? wifiPassword;
  final String? accessNotes;
  final String? lateArrivalTime;
  final String? receptionContact;

  /// City tax per person per night, in minor units of [taxCurrency].
  final int? taxMinorUnits;
  final String? taxCurrency;

  /// People who pay the tax (when empty: the guests of the stay).
  final int? taxPersons;

  bool get hasAccess =>
      doorCode != null ||
      wifiName != null ||
      wifiPassword != null ||
      accessNotes != null;

  /// Total tax for [nights] and [persons] people; null without a tax.
  int? taxTotal(int nights, int persons) {
    final tax = taxMinorUnits;
    if (tax == null || nights <= 0 || persons <= 0) return null;
    return tax * nights * persons;
  }

  Map<String, dynamic> toMap() {
    String? text(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    final tax = taxCurrency == null ? null : taxMinorUnits;
    return {
      'doorCode': ?text(doorCode),
      'wifiName': ?text(wifiName),
      'wifiPassword': ?text(wifiPassword),
      'accessNotes': ?text(accessNotes),
      'lateArrivalTime': ?text(lateArrivalTime),
      'receptionContact': ?text(receptionContact),
      if (tax != null) ...{'taxMinorUnits': tax, 'taxCurrency': taxCurrency},
      'taxPersons': ?taxPersons,
    };
  }

  static TripStayExtras fromMap(Object? raw) {
    if (raw is! Map) return const TripStayExtras();
    String? text(String key) {
      final value = raw[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    int? number(String key) => raw[key] is int ? raw[key] as int : null;
    final tax = number('taxMinorUnits');
    final currency = text('taxCurrency');
    return TripStayExtras(
      doorCode: text('doorCode'),
      wifiName: text('wifiName'),
      wifiPassword: text('wifiPassword'),
      accessNotes: text('accessNotes'),
      lateArrivalTime: text('lateArrivalTime'),
      receptionContact: text('receptionContact'),
      taxMinorUnits: currency == null ? null : tax,
      taxCurrency: tax == null ? null : currency,
      taxPersons: number('taxPersons'),
    );
  }

  /// True when something breaks the limits of firestore.rules.
  bool get invalid {
    bool long(String? v, int max) => v != null && v.trim().length > max;
    final tax = taxMinorUnits;
    final persons = taxPersons;
    final time = lateArrivalTime;
    return long(doorCode, shortMax) ||
        long(wifiName, shortMax) ||
        long(wifiPassword, shortMax) ||
        long(accessNotes, notesMax) ||
        long(receptionContact, contactMax) ||
        (time != null && !TripStayDates.isValidTime(time)) ||
        (tax != null &&
            (tax <= 0 ||
                tax > taxMax ||
                !CurrencyMinorUnits.supportedCodes.contains(taxCurrency))) ||
        (persons != null && (persons < 1 || persons > personsMax));
  }
}

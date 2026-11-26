// Dati di "Info paese" (nuova tappa 1c) letti dal file
// assets/country_info/country_info.json, rigenerato da
// tool/build_country_info.mjs con i dati aperti di Wikidata (CC0 1.0).
// Una voce senza dati nel file non si mostra. Nessuna chiamata di rete.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';

List<String> _strings(Object? v) =>
    v is List ? v.whereType<String>().toList() : const [];

class TripCountryInfo {
  const TripCountryInfo({
    required this.code,
    this.iso3,
    this.wikidata,
    this.nameIt,
    this.nameEn,
    this.callingCode = const [],
    this.emergency = const [],
    this.emergencyUses = const {},
    this.plugs = const [],
    this.voltage = const [],
    this.driving,
    this.timeZones = const [],
  });

  factory TripCountryInfo.fromMap(String code, Map<String, dynamic> m) {
    final name = m['name'] is Map ? m['name'] as Map : const {};
    return TripCountryInfo(
      code: code,
      iso3: m['iso3'] as String?,
      wikidata: m['wikidata'] as String?,
      nameIt: name['it'] as String?,
      nameEn: name['en'] as String?,
      callingCode: _strings(m['callingCode']),
      emergency: _strings(m['emergency']),
      emergencyUses: {
        if (m['emergencyUses'] case final Map uses)
          for (final e in uses.entries)
            if (e.key is String) e.key as String: _strings(e.value),
      },
      plugs: _strings(m['plugs']),
      voltage: _strings(m['voltage']),
      driving: m['driving'] as String?,
      timeZones: _strings(m['timeZones']),
    );
  }

  /// ISO 3166-1 alpha-2 ("IT") and alpha-3 ("ITA").
  final String code;
  final String? iso3, wikidata, nameIt, nameEn;
  final List<String> callingCode, emergency, plugs, voltage, timeZones;

  /// What each emergency number is for (Wikidata "has use"): police,
  /// fire, ambulance, general, coastGuard, deaf. Missing when unknown.
  final Map<String, List<String>> emergencyUses;

  /// "left" or "right".
  final String? driving;

  String name(String lang) =>
      (lang == 'it' ? nameIt ?? nameEn : nameEn ?? nameIt) ?? code;
}

class TripCountryInfoBook {
  const TripCountryInfoBook({
    required this.source,
    required this.licence,
    required this.generated,
    required this.countries,
  });

  factory TripCountryInfoBook.fromJson(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final source = json['source'] as Map<String, dynamic>? ?? const {};
    final countries = json['countries'] as Map<String, dynamic>? ?? const {};
    return TripCountryInfoBook(
      source: source['name'] as String? ?? '-',
      licence: source['licence'] as String? ?? '-',
      generated: DateTime.tryParse('${json['generated']}'),
      countries: {
        for (final e in countries.entries)
          if (e.value is Map<String, dynamic>)
            e.key: TripCountryInfo.fromMap(
              e.key,
              e.value as Map<String, dynamic>,
            ),
      },
    );
  }

  final String source, licence;
  final DateTime? generated;
  final Map<String, TripCountryInfo> countries;
}

const tripCountryInfoAsset = 'assets/country_info/country_info.json';

/// The file, read once per session.
final tripCountryInfoBookProvider = FutureProvider<TripCountryInfoBook>(
  (ref) async => TripCountryInfoBook.fromJson(
    await rootBundle.loadString(tripCountryInfoAsset),
  ),
);

/// Country of the trip destination ("IT"), when the trip has one.
final tripCountryCodeProvider = Provider.autoDispose.family<String?, String>(
  (ref, tripId) => ref
      .watch(tripProvider(tripId))
      .asData
      ?.value
      ?.destinationData
      ?.countryCode
      ?.toUpperCase(),
);

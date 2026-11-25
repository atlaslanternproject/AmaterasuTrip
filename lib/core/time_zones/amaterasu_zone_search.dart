// Ricerca del fuso orario per città (Extra C): "venezia" -> Venezia,
// Veneto, Italia, Europe/Rome. Usa il geocoding gratuito di Open-Meteo
// (senza chiave, vedi docs/audit/API-ESTERNE.md), solo quando si preme
// "Cerca", con le risposte in memoria per la sessione.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A city with its IANA time zone.
class AmaterasuZoneCity {
  const AmaterasuZoneCity({
    required this.name,
    required this.zone,
    this.region,
    this.country,
  });

  final String name;
  final String zone;
  final String? region;
  final String? country;

  /// "Veneto, Italia" under the city name.
  String get place => [?region, ?country].join(', ');
}

abstract interface class AmaterasuZoneSearch {
  Future<List<AmaterasuZoneCity>> search(String query, String languageCode);
}

class OpenMeteoZoneSearch implements AmaterasuZoneSearch {
  OpenMeteoZoneSearch({Future<String> Function(Uri)? load})
    : _load = load ?? _network;

  final Future<String> Function(Uri) _load;
  final _cache = <String, Future<List<AmaterasuZoneCity>>>{};

  static Future<String> _network(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const FormatException('Geocoding unavailable.');
    }
    return response.body;
  }

  static List<AmaterasuZoneCity> parse(String body) {
    final data = jsonDecode(body);
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    return [
      for (final r in results)
        if (r is Map && text(r['name']) != null && text(r['timezone']) != null)
          AmaterasuZoneCity(
            name: r['name'] as String,
            zone: r['timezone'] as String,
            region: text(r['admin1']),
            country: text(r['country']),
          ),
    ];
  }

  @override
  Future<List<AmaterasuZoneCity>> search(String query, String languageCode) {
    final q = query.trim();
    if (q.length < 2) return Future.value(const []);
    final key = '${q.toLowerCase()}|$languageCode';
    final cached = _cache[key];
    if (cached != null) return cached;
    final future = _load(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '8',
        'language': languageCode,
        'format': 'json',
      }),
    ).then(parse);
    _cache[key] = future;
    future.catchError((Object _) {
      _cache.remove(key);
      return const <AmaterasuZoneCity>[];
    });
    return future;
  }
}

final amaterasuZoneSearchProvider = Provider<AmaterasuZoneSearch>(
  (ref) => OpenMeteoZoneSearch(),
);

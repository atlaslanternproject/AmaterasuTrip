// Novità dell'app per versione, lette dall'unico file del repository
// assets/changelog/changelog.json (it/en, la più recente in alto). Serve
// al pannello "Cosa c'è di nuovo" e all'elenco delle versioni.

import 'dart:convert';

import 'package:flutter/services.dart';

class AmaterasuVersionNews {
  const AmaterasuVersionNews({
    required this.version,
    required this.date,
    required this.news,
  });

  final String version;
  final DateTime? date;

  /// Language code ('it', 'en') -> lines for the users.
  final Map<String, List<String>> news;

  /// Lines in [languageCode], in English when missing.
  List<String> linesFor(String languageCode) =>
      news[languageCode] ?? news['en'] ?? const [];
}

abstract final class AmaterasuChangelog {
  static const asset = 'assets/changelog/changelog.json';

  /// Parses the file; versions in the file order (newest first).
  static List<AmaterasuVersionNews> parse(String source) {
    final data = jsonDecode(source);
    final list = data is Map ? data['versions'] : null;
    if (list is! List) return const [];
    return [
      for (final raw in list)
        if (raw is Map && raw['version'] is String)
          AmaterasuVersionNews(
            version: raw['version'] as String,
            date: DateTime.tryParse('${raw['date']}'),
            news: {
              for (final lang in const ['it', 'en'])
                if (raw[lang] is List)
                  lang: [
                    for (final line in raw[lang] as List)
                      if (line is String) line,
                  ],
            },
          ),
    ];
  }

  static Future<List<AmaterasuVersionNews>> load([AssetBundle? bundle]) async =>
      parse(await (bundle ?? rootBundle).loadString(asset, cache: false));
}

// "Link utili" delle sezioni: elenco di indirizzi web salvato nel campo
// usefulLinks (come nella bucket list), al massimo 10, controllati con
// AmaterasuWebLink e da sectionLinks in firestore.rules.

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';

abstract final class TripSectionLinks {
  static const key = 'usefulLinks';
  static const max = 10;

  /// Saved value, or an empty map when there are no links.
  static Map<String, dynamic> toMap(List<String> links) {
    final clean = [
      for (final link in links)
        if (link.trim().isNotEmpty) link.trim(),
    ];
    return clean.isEmpty ? const {} : {key: clean};
  }

  static List<String> read(Map<String, dynamic> data) => [
    if (data[key] is List)
      for (final link in data[key] as List)
        if (link is String && link.trim().isNotEmpty) link,
  ];

  static bool invalid(List<String> links) =>
      links.length > max || !links.every(AmaterasuWebLink.isValid);
}

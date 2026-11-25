// Testo in cui cerca "Cerca" (nuova tappa 2): solo i campi scritti
// dall'utente (nomi, testi, note, indirizzi, città, codici di
// prenotazione, voci delle checklist), mai codice porta, Wi-Fi, telefono,
// email, link o identificativi. Confronto senza maiuscole né accenti.

/// Saved fields that hold text written by the user.
const tripSearchKeys = {
  'name',
  'title',
  'text',
  'body',
  'notes',
  'address',
  'area',
  'city',
  'country',
  'arrivalCity',
  'departureCity',
  'zoneCity',
  'carrier',
  'number',
  'bookingCode',
  'confirmationCode',
  'ticketCode',
  'holder',
  'seat',
  'seats',
  'where',
  'forText',
  'cuisine',
  'cancellationPolicy',
  'directions',
  'accessNotes',
  'allergenNotes',
  'triedNote',
  'moment',
  'bookedViaOther',
  'linkName',
  'items',
  'checklist',
  'extras',
};

/// Containers: their inner maps (also keyed by ID, like checklist items)
/// are read with the same key list.
const _containers = {'items', 'checklist', 'extras'};

/// Texts of [data] under [tripSearchKeys], in order, without links.
List<String> tripSearchTexts(Map<String, dynamic> data) {
  final out = <String>[];
  void walk(Object? value, {required bool text, bool inside = false}) {
    if (value is String) {
      final line = value.trim();
      if (text && line.isNotEmpty && !line.startsWith('http')) out.add(line);
    } else if (value is List) {
      for (final v in value) {
        walk(v, text: text && !inside, inside: inside);
      }
    } else if (value is Map) {
      for (final e in value.entries) {
        final allowed = tripSearchKeys.contains(e.key);
        // Inside a container, maps keyed by ID are entered too.
        if (allowed || (inside && e.value is Map)) {
          walk(e.value, text: allowed, inside: inside);
        }
      }
    }
  }

  for (final e in data.entries) {
    if (_containers.contains(e.key)) {
      walk(e.value, text: false, inside: true);
    } else if (tripSearchKeys.contains(e.key) && e.value is String) {
      walk(e.value, text: true);
    }
  }
  return out;
}

const _plain = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ß': 'ss',
};

/// Lower case without accents: "Città" and "citta" are the same.
String tripSearchFold(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final c = String.fromCharCode(rune);
    buffer.write(_plain[c] ?? c);
  }
  return buffer.toString();
}

/// Whether every word of [query] is in [texts]; null when it is not,
/// otherwise the first text containing the first word (the snippet).
String? tripSearchMatch(List<String> texts, String query) {
  final words = tripSearchFold(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return null;
  final folded = texts.map(tripSearchFold).toList();
  final all = folded.join('\n');
  if (!words.every(all.contains)) return null;
  for (var i = 0; i < texts.length; i++) {
    if (folded[i].contains(words.first)) return tripSearchSnippet(texts[i]);
  }
  return tripSearchSnippet(texts.first);
}

/// One line of at most 120 characters.
String tripSearchSnippet(String text) {
  final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return line.length <= 120 ? line : '${line.substring(0, 117)}...';
}

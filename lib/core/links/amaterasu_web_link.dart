// Validazione dei link web dell'app, con le stesse regole della bucket list
// e di firestore.rules: http o https, dominio non vuoto, al massimo 2048
// caratteri, spazi iniziali e finali ignorati.

abstract final class AmaterasuWebLink {
  /// Longest accepted link, as in firestore.rules (validBucketLink).
  static const maxLength = 2048;

  /// The link as an address to open, or null when it is not valid.
  static Uri? parse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text.length > maxLength || text.contains(' ')) {
      return null;
    }
    final uri = Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  static bool isValid(String? raw) => parse(raw) != null;

  /// Text shown on a link chip: the site name (host), or [fallback].
  static String label(String raw, String fallback) =>
      Uri.tryParse(raw.trim())?.host.isNotEmpty == true
      ? Uri.parse(raw.trim()).host
      : fallback;

  /// Google Maps address of a place: by Google place id when known,
  /// otherwise by coordinates. Null when neither is available.
  static Uri? googleMaps({
    required String name,
    String? placeId,
    double? latitude,
    double? longitude,
  }) {
    final id = placeId?.trim() ?? '';
    if (id.isNotEmpty) {
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': name,
        'query_place_id': id,
      });
    }
    if (latitude != null && longitude != null) {
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$latitude,$longitude',
      });
    }
    return null;
  }
}

// Lettura di un link di Google Maps incollato: nome del luogo (dal tratto
// /place/Nome/) e coordinate (@lat,lng o ?q=lat,lng) quando ci sono. Serve
// solo a precompilare: il link resta salvato com'è.

class TripMapsLink {
  const TripMapsLink({this.name, this.latitude, this.longitude});

  final String? name;
  final double? latitude;
  final double? longitude;

  static final _at = RegExp(r'@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)');
  static final _query = RegExp(r'^(-?\d{1,2}\.\d+),\s*(-?\d{1,3}\.\d+)$');

  /// True for google.com/maps, maps.google.*, maps.app.goo.gl and goo.gl/maps.
  static bool isMapsLink(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return (host.contains('google.') && uri.path.startsWith('/maps')) ||
        host.startsWith('maps.google.') ||
        host == 'maps.app.goo.gl' ||
        (host == 'goo.gl' && uri.path.startsWith('/maps'));
  }

  static TripMapsLink parse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return const TripMapsLink();
    String? name;
    final segments = uri.pathSegments;
    final placeIndex = segments.indexOf('place');
    if (placeIndex >= 0 && placeIndex + 1 < segments.length) {
      name = segments[placeIndex + 1].replaceAll('+', ' ').trim();
    }
    double? lat;
    double? lng;
    final at = _at.firstMatch(uri.path);
    final query = _query.firstMatch(uri.queryParameters['q'] ?? '');
    final match = at ?? query;
    if (match != null) {
      lat = double.tryParse(match.group(1)!);
      lng = double.tryParse(match.group(2)!);
      if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
        lat = lng = null;
      }
    }
    return TripMapsLink(
      name: name == null || name.isEmpty ? null : name,
      latitude: lat,
      longitude: lng,
    );
  }
}

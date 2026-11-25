// Ora e scarto da UTC di un fuso orario IANA (es. Europe/Rome) in una
// data: nel browser con Intl (dati sempre aggiornati, ora legale
// compresa); fuori dal browser (test) solo per i fusi fissi Etc/GMT±N e
// Etc/UTC. Restituisce null quando non può calcolarlo.

import 'amaterasu_zone_clock_stub.dart'
    if (dart.library.js_interop) 'amaterasu_zone_clock_web.dart'
    as platform;

abstract final class AmaterasuZoneClock {
  static final _etc = RegExp(r'^Etc/GMT([+-])(\d{1,2})$');

  /// "+02:00" for [zone] on [day] (at noon UTC), or null.
  static String? offsetOn(String zone, DateTime day) =>
      platform.zoneOffset(zone, day) ?? fixedOffset(zone);

  /// "14:32" now in [zone], or null.
  static String? localTimeNow(String zone, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final fromPlatform = platform.zoneTime(zone, at);
    if (fromPlatform != null) return fromPlatform;
    final offset = fixedOffset(zone);
    if (offset == null) return null;
    final sign = offset.startsWith('-') ? -1 : 1;
    final minutes =
        sign *
        (int.parse(offset.substring(1, 3)) * 60 +
            int.parse(offset.substring(4)));
    final local = at.toUtc().add(Duration(minutes: minutes));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  /// Offset of the fixed zones (no daylight saving), or null.
  static String? fixedOffset(String zone) {
    if (zone == 'Etc/UTC' || zone == 'UTC') return '+00:00';
    final m = _etc.firstMatch(zone);
    if (m == null) return null;
    // Etc/GMT names have the opposite sign: Etc/GMT-1 is UTC+1.
    final sign = m.group(1) == '-' ? '+' : '-';
    return '$sign${m.group(2)!.padLeft(2, '0')}:00';
  }
}

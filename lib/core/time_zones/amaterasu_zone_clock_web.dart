// Nel browser: scarto da UTC e ora attuale di un fuso IANA con le funzioni
// di web/amaterasu_time_zone.js (Intl.DateTimeFormat). Un fuso sconosciuto
// dà null, senza errori.

import 'dart:js_interop';

@JS('amaterasuZoneOffset')
external JSString? _offset(JSString zone, JSString isoDay);

@JS('amaterasuZoneTime')
external JSString? _time(JSString zone, JSNumber epochMs);

String? zoneOffset(String zone, DateTime day) {
  try {
    final iso =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return _offset(zone.toJS, iso.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

String? zoneTime(String zone, DateTime at) {
  try {
    return _time(zone.toJS, at.millisecondsSinceEpoch.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

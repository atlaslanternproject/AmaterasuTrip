// Scrittura di un calendario .ics (RFC 5545) per "Esporta" (tappa 3a):
// eventi con ora UTC, ora locale "fluttuante" o giornata intera; testi
// protetti (\ ; , a capo), righe oltre 75 byte spezzate, fine riga CRLF.
// Solo calcoli: nessun file, nessuna rete.

import 'dart:convert';

/// When an event starts or ends.
class TripIcsTime {
  const TripIcsTime.utc(this.value) : kind = TripIcsTimeKind.utc;
  const TripIcsTime.local(this.value) : kind = TripIcsTimeKind.local;
  const TripIcsTime.day(this.value) : kind = TripIcsTimeKind.day;

  /// UTC instant, wall-clock time of the place, or calendar day.
  final DateTime value;
  final TripIcsTimeKind kind;

  TripIcsTime plus(Duration d) => switch (kind) {
    TripIcsTimeKind.utc => TripIcsTime.utc(value.add(d)),
    TripIcsTimeKind.local => TripIcsTime.local(value.add(d)),
    TripIcsTimeKind.day => TripIcsTime.day(value.add(d)),
  };
}

enum TripIcsTimeKind { utc, local, day }

class TripIcsEvent {
  const TripIcsEvent({
    required this.uid,
    required this.summary,
    required this.start,
    required this.end,
    this.location,
    this.description,
  });

  final String uid, summary;
  final TripIcsTime start, end;
  final String? location, description;
}

abstract final class TripIcsWriter {
  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';

  static String _clock(DateTime d) =>
      '${_date(d)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

  /// "DTSTART:20270410T130000Z", "DTSTART:20270410T150000" or
  /// "DTSTART;VALUE=DATE:20270410".
  static String time(String name, TripIcsTime t) => switch (t.kind) {
    TripIcsTimeKind.utc => '$name:${_clock(t.value.toUtc())}Z',
    TripIcsTimeKind.local => '$name:${_clock(t.value)}',
    TripIcsTimeKind.day => '$name;VALUE=DATE:${_date(t.value)}',
  };

  /// Text value with \ ; , and new lines protected.
  static String escape(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(RegExp(r'\r\n|\r|\n'), r'\n');

  /// Splits a line longer than 75 bytes (UTF-8) without cutting a letter.
  static String fold(String line) {
    final out = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (bytes + size > 75) {
        out.write('\r\n ');
        bytes = 1;
      }
      out.write(char);
      bytes += size;
    }
    return out.toString();
  }

  static String write({
    required String name,
    required List<TripIcsEvent> events,
    required DateTime now,
  }) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Amaterasu Trip//Calendario//IT',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:${escape(name)}',
      for (final e in events) ...[
        'BEGIN:VEVENT',
        'UID:${e.uid}',
        time('DTSTAMP', TripIcsTime.utc(now)),
        time('DTSTART', e.start),
        time('DTEND', e.end),
        'SUMMARY:${escape(e.summary)}',
        if (e.location != null && e.location!.trim().isNotEmpty)
          'LOCATION:${escape(e.location!.trim())}',
        if (e.description != null && e.description!.trim().isNotEmpty)
          'DESCRIPTION:${escape(e.description!.trim())}',
        'END:VEVENT',
      ],
      'END:VCALENDAR',
    ];
    return '${lines.map(fold).join('\r\n')}\r\n';
  }
}

// Strumenti delle checklist senza interfaccia: nuovo identificativo di voce,
// copia della lista con le spunte azzerate, testo da stampare (HTML) e CSV
// per Excel.

import 'dart:math';

import 'trip_checklist.dart';

abstract final class TripChecklistTools {
  static final _random = Random();

  /// Short id that fits the rules (letters and digits).
  static String newId() =>
      'e${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1296).toRadixString(36)}';

  /// Copy for "Duplicate list": same entries, nothing checked.
  static TripChecklist duplicate(
    TripChecklist list, {
    required String authorUid,
    required String title,
  }) => TripChecklist(
    tripId: list.tripId,
    createdByUid: authorUid,
    title: title,
    isPrivate: list.isPrivate,
    template: list.template,
    categories: list.categories,
    entries: {
      for (final e in list.entries.values) e.id: e.copyWith(done: false),
    },
  );

  static String _esc(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Printable page: one table per category with boxes to tick on paper.
  static String html(TripChecklist list, String? Function(String?) nameOf) {
    final body = StringBuffer();
    for (final category in list.shownCategories) {
      body.write('<h2>${_esc(category)}</h2><ul>');
      for (final e in list.entriesOf(category)) {
        final who = nameOf(e.assigneeUid);
        body.write(
          '<li>${e.done ? '☑' : '☐'} ${_esc(e.text)}'
          '${e.quantity == null ? '' : ' × ${e.quantity}'}'
          '${who == null ? '' : ' (${_esc(who)})'}</li>',
        );
      }
      body.write('</ul>');
    }
    return '<!doctype html><html><head><meta charset="utf-8"><title>'
        '${_esc(list.title)}</title><style>body{font-family:sans-serif;'
        'margin:16px}h1{font-size:18px}h2{font-size:14px;margin:14px 0 4px}'
        'ul{list-style:none;padding:0}li{padding:2px 0;font-size:13px}'
        '</style></head><body><h1>${_esc(list.title)}</h1>$body</body></html>';
  }

  /// CSV for Excel: category; entry; quantity; person; done.
  static String csv(
    TripChecklist list,
    String? Function(String?) nameOf,
    List<String> header,
    String yes,
    String no,
  ) {
    String cell(String v) => '"${v.replaceAll('"', '""')}"';
    final lines = [header.map(cell).join(';')];
    for (final category in list.shownCategories) {
      for (final e in list.entriesOf(category)) {
        lines.add(
          [
            category,
            e.text,
            e.quantity?.toString() ?? '',
            nameOf(e.assigneeUid) ?? '',
            e.done ? yes : no,
          ].map(cell).join(';'),
        );
      }
    }
    return '﻿${lines.join('\r\n')}';
  }
}

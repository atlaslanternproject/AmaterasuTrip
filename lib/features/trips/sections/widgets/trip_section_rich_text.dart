// Formattazione di base dei testi delle sezioni (note): una riga che
// inizia con "# " è un titolo in grassetto, "- " o "* " diventa un punto
// elenco "•", e il testo tra ** e ** è in grassetto. Nient'altro.

import 'package:flutter/widgets.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

final _bold = RegExp(r'\*\*(.+?)\*\*');

TextSpan tripSectionRichText(String text, TextStyle base) {
  final strong = base.copyWith(fontWeight: FontWeight.w700);
  final spans = <InlineSpan>[];
  for (final (index, raw) in text.split('\n').indexed) {
    if (index > 0) spans.add(const TextSpan(text: '\n'));
    if (raw.startsWith('# ')) {
      spans.add(
        TextSpan(
          text: raw.substring(2),
          style: strong.copyWith(color: AmaterasuColors.textCream),
        ),
      );
      continue;
    }
    final line = raw.startsWith('- ') || raw.startsWith('* ')
        ? '• ${raw.substring(2)}'
        : raw;
    var start = 0;
    for (final match in _bold.allMatches(line)) {
      if (match.start > start) {
        spans.add(TextSpan(text: line.substring(start, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: strong));
      start = match.end;
    }
    if (start < line.length) spans.add(TextSpan(text: line.substring(start)));
  }
  return TextSpan(style: base, children: spans);
}

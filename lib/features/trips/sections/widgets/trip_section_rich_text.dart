// Formattazione di base dei testi delle sezioni (note): una riga che
// inizia con "# " è un titolo in grassetto, "- " o "* " diventa un punto
// elenco "•", il testo tra ** e ** è in grassetto e gli indirizzi web
// (http/https) diventano link da toccare se si passa [onLink].

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

final _bold = RegExp(r'\*\*(.+?)\*\*');
final _url = RegExp(r'https?://[^\s]+');

TextSpan tripSectionRichText(
  String text,
  TextStyle base, {
  void Function(String url)? onLink,
}) {
  final strong = base.copyWith(fontWeight: FontWeight.w700);
  final spans = <InlineSpan>[];

  // Plain text with its web addresses as tappable links.
  void plain(String part, [TextStyle? style]) {
    var start = 0;
    final open = onLink;
    if (open != null) {
      for (final match in _url.allMatches(part)) {
        // A final dot or comma belongs to the sentence, not to the link.
        var url = match.group(0)!;
        while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
          url = url.substring(0, url.length - 1);
        }
        if (!AmaterasuWebLink.isValid(url)) continue;
        if (match.start > start) {
          spans.add(
            TextSpan(text: part.substring(start, match.start), style: style),
          );
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              key: Key('rich-link-$url'),
              onTap: () => open(url),
              child: Text(
                url,
                style: (style ?? base).copyWith(
                  color: AmaterasuColors.accentGold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
        start = match.start + url.length;
      }
    }
    if (start < part.length) {
      spans.add(TextSpan(text: part.substring(start), style: style));
    }
  }

  for (final (index, raw) in text.split('\n').indexed) {
    if (index > 0) spans.add(const TextSpan(text: '\n'));
    if (raw.startsWith('# ')) {
      plain(
        raw.substring(2),
        strong.copyWith(color: AmaterasuColors.textCream),
      );
      continue;
    }
    final line = raw.startsWith('- ') || raw.startsWith('* ')
        ? '• ${raw.substring(2)}'
        : raw;
    var start = 0;
    for (final match in _bold.allMatches(line)) {
      if (match.start > start) plain(line.substring(start, match.start));
      plain(match.group(1)!, strong);
      start = match.end;
    }
    if (start < line.length) plain(line.substring(start));
  }
  return TextSpan(style: base, children: spans);
}
